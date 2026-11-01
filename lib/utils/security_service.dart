import 'dart:io';
import 'package:flutter/services.dart';

class SecurityService {
  static const MethodChannel _channel =
      MethodChannel('com.example.inspection/security');

  /// Disables screenshot / screen capture at the OS level (e.g. during video recording)
  /// to prevent SurfaceFlinger / camera buffer queue deadlocks and screen freezes.
  static Future<void> disableScreenshot() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enableSecure');
      }
    } catch (_) {}
  }

  /// Re-enables screenshot / screen capture when video recording stops.
  static Future<void> enableScreenshot() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disableSecure');
      }
    } catch (_) {}
  }
}
