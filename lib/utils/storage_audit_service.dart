import 'dart:developer';
import 'dart:io';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageSnapshot {
  final int temporaryDirBytes;
  final int mediaCacheBytes;
  final int offlineMediaBytes;
  final int otherDocumentsBytes;
  final int pendingUploadBytes;
  final int totalManagedBytes;
  final DateTime timestamp;

  const StorageSnapshot({
    required this.temporaryDirBytes,
    required this.mediaCacheBytes,
    required this.offlineMediaBytes,
    required this.otherDocumentsBytes,
    required this.pendingUploadBytes,
    required this.totalManagedBytes,
    required this.timestamp,
  });

  static String formatBytes(int bytes) {
    if (bytes <= 0) return "0.0 MB";
    final mb = bytes / (1024 * 1024);
    if (mb < 1.0) {
      final kb = bytes / 1024;
      return "${kb.toStringAsFixed(1)} KB";
    }
    return "${mb.toStringAsFixed(2)} MB";
  }

  @override
  String toString() {
    return '''
================= STORAGE SNAPSHOT [${timestamp.toIso8601String()}] =================
• Temp Cache Directory : ${formatBytes(temporaryDirBytes)}
• Remote Media Cache   : ${formatBytes(mediaCacheBytes)}
• Offline Media Dir    : ${formatBytes(offlineMediaBytes)}
• Other App Documents  : ${formatBytes(otherDocumentsBytes)}
• Pending Upload Queue : ${formatBytes(pendingUploadBytes)}
----------------------------------------------------------------------------------
• Total Managed Bytes  : ${formatBytes(totalManagedBytes)}
==================================================================================''';
  }
}

class StorageAuditService {
  StorageAuditService._();
  static final StorageAuditService instance = StorageAuditService._();

  /// Recursively calculate the size in bytes of a given directory or file
  Future<int> _calculateEntitySize(FileSystemEntity entity) async {
    try {
      if (entity is File) {
        return await entity.length();
      } else if (entity is Directory) {
        int total = 0;
        await for (final child in entity.list(recursive: true, followLinks: false)) {
          if (child is File) {
            try {
              total += await child.length();
            } catch (_) {}
          }
        }
        return total;
      }
    } catch (_) {}
    return 0;
  }

  /// Gather a detailed storage snapshot of the app's current storage footprint
  Future<StorageSnapshot> getSnapshot() async {
    int tempBytes = 0;
    int mediaCacheBytes = 0;
    int offlineMediaBytes = 0;
    int otherDocsBytes = 0;
    int pendingBytes = 0;

    try {
      // 1. Temporary Directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        tempBytes = await _calculateEntitySize(tempDir);
      }
    } catch (e) {
      log("⚠️ [StorageAuditService] Error calculating temp size: $e");
    }

    try {
      // 2. Application Documents Directory
      final docDir = await getApplicationDocumentsDirectory();
      if (await docDir.exists()) {
        final offlineDir = Directory(p.join(docDir.path, 'offline_media'));
        if (await offlineDir.exists()) {
          offlineMediaBytes = await _calculateEntitySize(offlineDir);
        }

        // Check if media_cache exists in documents (legacy path)
        final docMediaCacheDir = Directory(p.join(docDir.path, 'media_cache'));
        if (await docMediaCacheDir.exists()) {
          mediaCacheBytes += await _calculateEntitySize(docMediaCacheDir);
        }

        // Also check if media_cache exists in temp directory
        try {
          final tempDir = await getTemporaryDirectory();
          final tempMediaCacheDir = Directory(p.join(tempDir.path, 'media_cache'));
          if (await tempMediaCacheDir.exists()) {
            mediaCacheBytes += await _calculateEntitySize(tempMediaCacheDir);
          }
        } catch (_) {}

        // Calculate other documents files
        await for (final entity in docDir.list(followLinks: false)) {
          final name = p.basename(entity.path);
          if (name != 'offline_media' && name != 'media_cache') {
            otherDocsBytes += await _calculateEntitySize(entity);
          }
        }
      }
    } catch (e) {
      log("⚠️ [StorageAuditService] Error calculating doc size: $e");
    }

    try {
      // 3. Pending Upload Queue size
      final queue = await LocalUploadStorageService.getQueue();
      final pendingTasks = queue.where((t) => t.status != 'completed').toList();
      for (final task in pendingTasks) {
        for (final item in task.mediaItems) {
          if (item.filePath.isNotEmpty) {
            final f = File(item.filePath);
            if (await f.exists()) {
              pendingBytes += await f.length();
            }
          }
        }
      }
    } catch (e) {
      log("⚠️ [StorageAuditService] Error calculating pending queue size: $e");
    }

    final total = tempBytes + offlineMediaBytes + otherDocsBytes;

    return StorageSnapshot(
      temporaryDirBytes: tempBytes,
      mediaCacheBytes: mediaCacheBytes,
      offlineMediaBytes: offlineMediaBytes,
      otherDocumentsBytes: otherDocsBytes,
      pendingUploadBytes: pendingBytes,
      totalManagedBytes: total,
      timestamp: DateTime.now(),
    );
  }

  /// Print a formatted diagnostic report to log console
  Future<StorageSnapshot> logSnapshot(String contextTag) async {
    final snapshot = await getSnapshot();
    log("📊 [StorageAudit][$contextTag]\n$snapshot");
    return snapshot;
  }
}
