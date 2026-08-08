import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:inspection/model/upload_queue_model.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:inspection/utils/network_sync_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MediaUploadSyncService {
  static bool _isProcessing = false;
  static bool get isProcessing => _isProcessing;

  /// Process all pending tasks in the local queue sequentially
  static Future<void> processQueue() async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;
    try {
      final List<UploadQueueModel> pending =
          await LocalUploadStorageService.getPendingTasks();

      if (pending.isEmpty) {
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken') ?? '';

      final Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            if (userToken.isNotEmpty) "Authorization": "Bearer $userToken",
            "Accept": "application/json",
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      for (var task in pending) {
        final success = await _uploadSingleTask(dio, task);
        if (!success) {
        }
      }
    } catch (e) {
    } finally {
      _isProcessing = false;
    }
  }

  /// Upload a single queued task using Dio with extended timeouts
  static Future<bool> _uploadSingleTask(Dio dio, UploadQueueModel task) async {
    // Verify that at least one file exists on disk
    bool hasValidFile = false;
    for (var item in task.mediaItems) {
      if (File(item.filePath).existsSync()) {
        hasValidFile = true;
        break;
      }
    }

    if (!hasValidFile && task.mediaItems.isNotEmpty) {
      await LocalUploadStorageService.removeTask(task.id);
      return false;
    }

    await LocalUploadStorageService.updateTaskStatus(task.id, 'uploading');

    // Apply exponential backoff delay if retrying a previously failed task
    if (task.retryCount > 0) {
      final backoffSeconds = (1 << task.retryCount).clamp(1, 30);
      await Future.delayed(Duration(seconds: backoffSeconds));
    }

    try {
      FormData formData = FormData();

      final isSingleSave = task.endpointUrl.contains("saveSingleTask");
      final isVehicleEssential = task.endpointUrl.contains("saveVehicleEssentialDetails");

      if (isSingleSave) {
        // Build FormData for vehicleinspection/saveSingleTask
        if (task.fields.containsKey("data")) {
          formData.files.add(MapEntry(
            "data",
            MultipartFile.fromString(
              task.fields["data"]!,
              contentType: http_parser.MediaType("application", "json"),
            ),
          ));
        }

        for (int i = 0; i < task.mediaItems.length; i++) {
          final item = task.mediaItems[i];
          final file = File(item.filePath);
          if (!file.existsSync()) continue;

          if (item.type == "0") {
            final multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "inspection_image_${item.imgIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg",
              contentType: http_parser.MediaType("image", "jpeg"),
            );
            formData.files.add(MapEntry("viimagefiles", multipartFile));
          } else if (item.type == "2") {
            final ext = item.filePath.split('.').last.toLowerCase();
            final subType = (ext == 'm4a' || ext == 'aac' || ext == 'wav' || ext == 'mp3') ? ext : 'mpeg';
            final multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "inspection_audio_${DateTime.now().millisecondsSinceEpoch}.$subType",
              contentType: http_parser.MediaType("audio", subType),
            );
            formData.files.add(MapEntry("viaudiofile", multipartFile));
          } else if (item.type == "1") {
            final multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "inspection_video_${DateTime.now().millisecondsSinceEpoch}.mp4",
              contentType: http_parser.MediaType("video", "mp4"),
            );
            formData.files.add(MapEntry("vivideofile", multipartFile));
          }
        }
      } else if (isVehicleEssential) {
        // Build FormData for vehicleinspection/saveVehicleEssentialDetails
        if (task.fields.containsKey("payload")) {
          formData.files.add(MapEntry(
            "payload",
            MultipartFile.fromString(
              task.fields["payload"]!,
              contentType: http_parser.MediaType("application", "json"),
            ),
          ));
        }

        for (var item in task.mediaItems) {
          final file = File(item.filePath);
          if (!file.existsSync()) continue;

          if (item.type == "0") {
            final multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "essential_image_${DateTime.now().millisecondsSinceEpoch}.jpg",
              contentType: http_parser.MediaType("image", "jpeg"),
            );
            formData.files.add(MapEntry("essentinalImage", multipartFile));
          }
        }
      } else {
        // Default / Basic Inspection upload handling
        task.fields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value));
        });

        for (int i = 0; i < task.mediaItems.length; i++) {
          final item = task.mediaItems[i];
          final file = File(item.filePath);
          if (!file.existsSync()) continue;

          MultipartFile multipartFile;
          if (item.is360) {
            multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "inspection_360_video_${DateTime.now().millisecondsSinceEpoch}.mp4",
              contentType: http_parser.MediaType("video", "mp4"),
            );
          } else if (item.type == "0") {
            multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "inspection_image_${item.imgIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg",
              contentType: http_parser.MediaType("image", "jpeg"),
            );
          } else if (item.type == "2") {
            final ext = item.filePath.split('.').last.toLowerCase();
            final subType = (ext == 'm4a' || ext == 'aac' || ext == 'wav' || ext == 'mp3') ? ext : 'mpeg';
            multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "inspection_audio_${DateTime.now().millisecondsSinceEpoch}.$subType",
              contentType: http_parser.MediaType("audio", subType),
            );
          } else {
            multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: "inspection_video_${DateTime.now().millisecondsSinceEpoch}.mp4",
              contentType: http_parser.MediaType("video", "mp4"),
            );
          }

          formData.files.add(MapEntry("mediaFiles[$i].file", multipartFile));
          formData.fields.add(MapEntry("mediaFiles[$i].type", item.type));
        }
      }

      final response = await dio.post(
        task.endpointUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = ((sent / total) * 100).toStringAsFixed(0);
          }
        },
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        if (resData is Map) {
          final bodyStatusCode = resData['statusCode'];
          final bodyStatus = resData['status'];
          if (bodyStatusCode == 400 || bodyStatusCode == "400" || bodyStatus == "FAILED") {
            await LocalUploadStorageService.updateTaskStatus(
              task.id,
              'failed',
              retryCount: task.retryCount + 1,
            );
            return false;
          }
        }

        await LocalUploadStorageService.cleanupTaskMediaFiles(task);
        await LocalUploadStorageService.removeTask(task.id);
        await NetworkSyncManager().refreshPendingCount();
        return true;
      } else {
        await LocalUploadStorageService.updateTaskStatus(
          task.id,
          'failed',
          retryCount: task.retryCount + 1,
        );
        return false;
      }
    } on DioException catch (e) {
      await LocalUploadStorageService.updateTaskStatus(
        task.id,
        'failed',
        retryCount: task.retryCount + 1,
      );
      return false;
    } catch (e) {
      await LocalUploadStorageService.updateTaskStatus(
        task.id,
        'failed',
        retryCount: task.retryCount + 1,
      );
      return false;
    }
  }
}
