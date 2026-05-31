import 'dart:io';
import 'package:flutter/material.dart';

class InspectionFullscreenVideoController extends ChangeNotifier {
  bool isUploading = false;
  bool isSuccess = false;

  Future<File?> saveVideo(String videoPath) async {
    if (isUploading) return null;
    isUploading = true;
    notifyListeners();
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        debugPrint("Video file not found");
        return null;
      }
      await Future.delayed(const Duration(seconds: 2));
      isSuccess = true;
      return file;
    } catch (e) {
      debugPrint("Video save error: $e");
      return null;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}
