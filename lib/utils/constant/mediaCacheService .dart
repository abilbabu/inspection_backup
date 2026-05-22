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

  String _hash(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }

  Future<Directory> _cacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(base.path, "media_cache"));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

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
        // log("♻️ CACHE HIT → ${file.path}");
        return file;
      }
      onDownloadStart?.call();

      /// ⬇️ DOWNLOAD ONCE
      // log("⬇️ DOWNLOADING → $url");
      final res = await _dio.download(url, file.path);
      if (res.statusCode == 200) return file;
    } catch (e) {
      log("❌ Cache error: $e");
    }
    return null;
  }
}
