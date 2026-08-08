import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class MediaCompressionHelper {
  /// Compress an image file to reduce upload size while preserving resolution.
  /// Falls back to original file if compression fails or is unsupported.
  static Future<File> compressImageFile(File originalFile) async {
    try {
      if (!await originalFile.exists()) return originalFile;

      final tempDir = await getTemporaryDirectory();
      final String targetPath = p.join(
        tempDir.path,
        "compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(originalFile.path)}",
      );

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        final origSize = await originalFile.length();
        final compSize = await compressedFile.length();
        return compressedFile;
      }
    } catch (e) {
      print("e: $e");
    }
    return originalFile;
  }

  /// Compress a video file using VideoCompress.
  /// Falls back to original file if compression fails or takes too long.
  static Future<File> compressVideoFile(File originalFile) async {
    try {
      if (!await originalFile.exists()) return originalFile;

      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        originalFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (mediaInfo != null && mediaInfo.file != null) {
        final compressedFile = mediaInfo.file!;
        final origSize = await originalFile.length();
        final compSize = await compressedFile.length();
        return compressedFile;
      }
    } catch (e) {
      print("⚠️ e: $e");
    }
    return originalFile;
  }
}
