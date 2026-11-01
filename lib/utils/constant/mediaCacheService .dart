import 'dart:convert' show utf8;
import 'dart:developer';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum CachedMediaType { image, video, audio }

class MediaCacheService {
  MediaCacheService._();
  static final MediaCacheService instance = MediaCacheService._();

  final Dio _dio = Dio();

  /// Maximum cache size allowed for remote media (150 MB)
  static const int maxCacheSizeBytes = 150 * 1024 * 1024;
  /// Target size to trim down to when cache limit is exceeded (100 MB)
  static const int targetTrimSizeBytes = 100 * 1024 * 1024;

  bool _hasMigratedLegacyDocsCache = false;

  String _hash(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  /// Get the managed cache directory in the OS temporary/cache directory
  Future<Directory> _cacheDir() async {
    // One-time migration: delete old legacy cache from Documents to immediately free space
    if (!_hasMigratedLegacyDocsCache) {
      _hasMigratedLegacyDocsCache = true;
      _cleanupLegacyDocsCache();
    }

    final base = await getTemporaryDirectory();
    final dir = Directory(path.join(base.path, "media_cache"));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Clean legacy media_cache folder from getApplicationDocumentsDirectory()
  Future<void> _cleanupLegacyDocsCache() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final legacyDir = Directory(path.join(docDir.path, "media_cache"));
      if (await legacyDir.exists()) {
        log("🧹 [MediaCacheService] Pruning legacy documents media_cache directory...");
        await legacyDir.delete(recursive: true);
      }
    } catch (e) {
      log("⚠️ [MediaCacheService] Legacy cache cleanup error: $e");
    }
  }

  /// Retrieve cached file if available, or download with LRU cache management
  Future<File?> getCachedFile(
    String url,
    CachedMediaType type, {
    VoidCallback? onDownloadStart,
  }) async {
    try {
      final dir = await _cacheDir();
      final ext = switch (type) {
        CachedMediaType.image => ".jpg",
        CachedMediaType.video => ".mp4",
        CachedMediaType.audio => ".aac",
      };

      final file = File(path.join(dir.path, "${_hash(url)}$ext"));

      /// ✅ CACHE HIT
      if (await file.exists()) {
        try {
          // Touch last modified time to maintain LRU accuracy
          await file.setLastModified(DateTime.now());
        } catch (_) {}
        return file;
      }

      onDownloadStart?.call();

      /// ⬇️ DOWNLOAD ONCE
      final res = await _dio.download(url, file.path);
      if (res.statusCode == 200) {
        // Enforce cache size policy asynchronously after download
        _enforceCacheSizeLimit();
        return file;
      }
    } catch (e) {
      log("❌ Cache error: $e");
    }
    return null;
  }

  /// Evict oldest files according to LRU policy when directory size exceeds limit
  Future<void> _enforceCacheSizeLimit() async {
    try {
      final dir = await _cacheDir();
      final List<FileSystemEntity> entities = await dir.list().toList();

      List<File> files = [];
      int currentTotalBytes = 0;

      for (var entity in entities) {
        if (entity is File) {
          try {
            files.add(entity);
            currentTotalBytes += await entity.length();
          } catch (_) {}
        }
      }

      if (currentTotalBytes <= maxCacheSizeBytes) {
        return; // Cache is within healthy bounds
      }

      log("⚠️ [MediaCacheService] Cache reached ${currentTotalBytes ~/ (1024 * 1024)} MB. Evicting oldest entries to $targetTrimSizeBytes bytes...");

      // Sort files by modified date ascending (oldest first)
      files.sort((a, b) {
        final aTime = a.lastModifiedSync();
        final bTime = b.lastModifiedSync();
        return aTime.compareTo(bTime);
      });

      for (var f in files) {
        if (currentTotalBytes <= targetTrimSizeBytes) break;
        try {
          final size = await f.length();
          await f.delete();
          currentTotalBytes -= size;
        } catch (_) {}
      }
    } catch (e) {
      log("⚠️ [MediaCacheService] Error enforcing cache size: $e");
    }
  }

  /// Safely clear media cache for a specific URL
  Future<void> clearCacheForUrl(String url, CachedMediaType type) async {
    try {
      final dir = await _cacheDir();
      final ext = switch (type) {
        CachedMediaType.image => ".jpg",
        CachedMediaType.video => ".mp4",
        CachedMediaType.audio => ".aac",
      };
      final file = File(path.join(dir.path, "${_hash(url)}$ext"));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      log("❌ Clear cache error: $e");
    }
  }

  /// Explicitly clear all media cache entries (disposable remote cache only)
  Future<void> clearAllCache() async {
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
      await _cleanupLegacyDocsCache();
    } catch (e) {
      log("❌ Clear all media cache error: $e");
    }
  }
}
