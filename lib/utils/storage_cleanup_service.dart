import 'dart:developer';
import 'dart:io';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class StorageCleanupService {
  StorageCleanupService._();
  static final StorageCleanupService instance = StorageCleanupService._();

  /// Safe deletion of a list of file paths.
  /// Safeguard: NEVER deletes a file if it is currently referenced in the offline upload queue.
  Future<void> cleanupFilesSafely(List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    try {
      final queue = await LocalUploadStorageService.getQueue();
      final Set<String> queuedPaths = {};
      for (final task in queue) {
        if (task.status != 'completed') {
          for (final item in task.mediaItems) {
            if (item.filePath.isNotEmpty) {
              queuedPaths.add(p.normalize(item.filePath));
            }
          }
        }
      }

      for (final filePath in filePaths) {
        if (filePath.isEmpty) continue;
        final normalized = p.normalize(filePath);
        if (queuedPaths.contains(normalized)) {
          log("🛡️ [StorageCleanupService] Protected queued file, skipping: $filePath");
          continue;
        }

        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            log("🗑️ [StorageCleanupService] Safely deleted: $filePath");
          }
        } catch (e) {
          log("⚠️ [StorageCleanupService] Could not delete $filePath: $e");
        }
      }
    } catch (e) {
      log("⚠️ [StorageCleanupService] Error in cleanupFilesSafely: $e");
    }
  }

  /// Purges native VideoCompress cache files
  Future<void> cleanupVideoCompressCache() async {
    try {
      await VideoCompress.deleteAllCache();
      log("🧹 [StorageCleanupService] Cleared VideoCompress cache");
    } catch (e) {
      log("⚠️ [StorageCleanupService] Error clearing VideoCompress cache: $e");
    }
  }

  /// Clean up abandoned temporary files in getTemporaryDirectory() older than [maxAge].
  /// Never deletes files that are queued for upload or currently active drafts.
  Future<void> cleanupOrphanedTempFiles({Duration maxAge = const Duration(hours: 12)}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) return;

      final queue = await LocalUploadStorageService.getQueue();
      final Set<String> protectedPaths = {};
      for (final task in queue) {
        for (final item in task.mediaItems) {
          if (item.filePath.isNotEmpty) {
            protectedPaths.add(p.normalize(item.filePath));
          }
        }
      }

      final now = DateTime.now();
      int deletedCount = 0;
      int deletedBytes = 0;

      await for (final entity in tempDir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final normalized = p.normalize(entity.path);
          if (protectedPaths.contains(normalized)) continue;

          final fileName = p.basename(entity.path);
          // Target temporary processing files
          final isTargetPattern = fileName.startsWith('compressed_') ||
              fileName.startsWith('edited_') ||
              fileName.startsWith('rotated_') ||
              fileName.startsWith('temp_car_diagram_') ||
              fileName.startsWith('car_diagram_') ||
              fileName.endsWith('.jpg') ||
              fileName.endsWith('.png') ||
              fileName.endsWith('.mp4');

          if (!isTargetPattern) continue;

          try {
            final stat = await entity.stat();
            if (now.difference(stat.modified) > maxAge) {
              final int size = stat.size.toInt();
              await entity.delete();
              deletedCount++;
              deletedBytes += size;
            }
          } catch (_) {}
        }
      }

      if (deletedCount > 0) {
        log("🧹 [StorageCleanupService] Cleaned up $deletedCount orphaned temp files (${deletedBytes ~/ (1024 * 1024)} MB)");
      }
    } catch (e) {
      log("⚠️ [StorageCleanupService] Error cleaning orphaned temp files: $e");
    }
  }

  /// Run safe cleanup at app startup or background sync completion
  Future<void> runRoutineCleanup() async {
    try {
      await cleanupVideoCompressCache();
      await cleanupOrphanedTempFiles();
    } catch (e) {
      log("⚠️ [StorageCleanupService] Error running routine cleanup: $e");
    }
  }
}
