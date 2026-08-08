import 'dart:convert';
import 'dart:io';
import 'package:inspection/model/upload_queue_model.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUploadStorageService {
  static const String _queueKey = 'offline_media_upload_queue';

  /// Safely copy a media file (image, video, audio) from temporary cache into persistent offline storage
  static Future<String> copyToPersistentStorage(String sourcePath) async {
    if (sourcePath.isEmpty) return sourcePath;
    final file = File(sourcePath);
    if (!await file.exists()) return sourcePath;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory(path.join(docDir.path, 'offline_media'));
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourcePath)}";
      final persistentFile = await file.copy(path.join(offlineDir.path, fileName));
      return persistentFile.path;
    } catch (e) {
      print("⚠️ ee: $e");
      return sourcePath;
    }
  }

  /// Safely delete a single file from disk
  static Future<void> cleanupFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("⚠️ [LocalUploadStorageService] Could not delete local file $filePath: $e");
    }
  }

  /// Add new task to local queue
  static Future<void> addToQueue(UploadQueueModel task) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UploadQueueModel> tasks = await getQueue();
    // Replace if task with same ID exists, else add
    tasks.removeWhere((t) => t.id == task.id);
    tasks.add(task);
    await _saveQueue(prefs, tasks);
  }

  /// Retrieve all tasks from local queue
  static Future<List<UploadQueueModel>> getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawJson = prefs.getString(_queueKey);
      if (rawJson == null || rawJson.isEmpty) return [];

      final List<dynamic> list = jsonDecode(rawJson);
      return list
          .map((item) => UploadQueueModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("⚠️ [LocalUploadStorageService] Error loading queue: $e");
      return [];
    }
  }

  /// Reset any task stuck in 'uploading' status (e.g. from an app crash) back to 'pending'
  static Future<void> resetOrphanedUploadingTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<UploadQueueModel> tasks = await getQueue();
    bool updated = false;

    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].status == 'uploading') {
        tasks[i] = tasks[i].copyWith(status: 'pending');
        updated = true;
      }
    }

    if (updated) {
      await _saveQueue(prefs, tasks);
    }
  }

  /// Get pending or failed tasks ready for upload retry (capped at 5 retries)
  static Future<List<UploadQueueModel>> getPendingTasks() async {
    final queue = await getQueue();
    return queue
        .where((t) =>
            t.status == 'pending' ||
            (t.status == 'failed' && t.retryCount < 5))
        .toList();
  }

  /// Update task status and retry count
  static Future<void> updateTaskStatus(
    String taskId,
    String status, {
    int? retryCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UploadQueueModel> tasks = await getQueue();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(
        status: status,
        retryCount: retryCount ?? tasks[index].retryCount,
      );
      await _saveQueue(prefs, tasks);
    }
  }

  /// Remove task from local queue after successful upload
  static Future<void> removeTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UploadQueueModel> tasks = await getQueue();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveQueue(prefs, tasks);
  }

  /// Remove tasks matching jobId and imageId after successful upload
  static Future<void> removeTaskByImageId(int jobId, String imageId) async {
    if (imageId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final List<UploadQueueModel> tasks = await getQueue();
    final toRemove = tasks.where((t) =>
      t.jobId == jobId &&
      (t.fields["inspectionImageId"] == imageId || t.fields["inspection_image_id"] == imageId)
    ).toList();

    for (var task in toRemove) {
      await cleanupTaskMediaFiles(task);
    }
    tasks.removeWhere((t) => toRemove.contains(t));
    await _saveQueue(prefs, tasks);
  }

  /// Save media and payload into local offline queue when internet is not available
  static Future<UploadQueueModel> enqueueOfflineTask({
    required int jobId,
    required String endpointUrl,
    required List<MediaItemQueue> mediaItems,
    required Map<String, String> fields,
  }) async {
    List<MediaItemQueue> persistentItems = [];
    for (var item in mediaItems) {
      final persistentPath = await copyToPersistentStorage(item.filePath);
      persistentItems.add(MediaItemQueue(
        filePath: persistentPath,
        type: item.type,
        is360: item.is360,
        imgIndex: item.imgIndex,
      ));
    }

    final task = UploadQueueModel(
      id: "queue_${jobId}_${DateTime.now().millisecondsSinceEpoch}",
      jobId: jobId,
      endpointUrl: endpointUrl,
      mediaItems: persistentItems,
      fields: fields,
      status: 'pending',
      retryCount: 0,
      createdAt: DateTime.now().toIso8601String(),
    );

    await addToQueue(task);
    return task;
  }

  /// Save skipped item ID locally for offline persistence
  static Future<void> saveSkippedImageId(int jobId, int imageId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'skipped_image_ids_$jobId';
    List<String> list = prefs.getStringList(key) ?? [];
    if (!list.contains(imageId.toString())) {
      list.add(imageId.toString());
      await prefs.setStringList(key, list);
    }
  }

  /// Get all skipped item IDs for a job
  static Future<List<int>> getSkippedImageIds(int jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'skipped_image_ids_$jobId';
      List<String> list = prefs.getStringList(key) ?? [];
      return list.map((s) => int.tryParse(s) ?? 0).where((id) => id != 0).toList();
    } catch (_) {
      return [];
    }
  }

  /// Safely delete local compressed media files from disk after success
  static Future<void> cleanupTaskMediaFiles(UploadQueueModel task) async {
    for (var item in task.mediaItems) {
      if (item.filePath.isNotEmpty) {
        try {
          final file = File(item.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
        }
      }
    }
  }

  /// Clear all cached skipped image IDs and offline queue tasks for a specific job
  static Future<void> clearJobCache(int jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Remove skipped image IDs
      await prefs.remove('skipped_image_ids_$jobId');
      
      // 2. Remove any queue tasks for this job and clean up files
      final List<UploadQueueModel> tasks = await getQueue();
      final tasksToRemove = tasks.where((t) => t.jobId == jobId).toList();
      for (var task in tasksToRemove) {
        await cleanupTaskMediaFiles(task);
      }
      tasks.removeWhere((t) => t.jobId == jobId);
      await _saveQueue(prefs, tasks);
      
    } catch (e) {
    }
  }

  /// Clear all offline local storage queues, skipped IDs, and cached media files across all jobs
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasks = await getQueue();
      for (var task in tasks) {
        await cleanupTaskMediaFiles(task);
      }
      await prefs.remove(_queueKey);

      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('skipped_image_ids_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
    }
  }

  static Future<void> _saveQueue(
    SharedPreferences prefs,
    List<UploadQueueModel> tasks,
  ) async {
    final String encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_queueKey, encoded);
  }
}
