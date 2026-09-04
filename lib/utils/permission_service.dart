import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._internal();
  static final PermissionService instance = PermissionService._internal();

  bool _isRequestingPermission = false;

  bool get isRequesting => _isRequestingPermission;

  Future<PermissionStatus> checkStatus(Permission permission) async {
    return await permission.status;
  }

  /// Request Camera Permission
  Future<bool> requestCameraPermission(BuildContext context) async {
    return await _handlePermissionRequest(
      context: context,
      permission: Permission.camera,
      featureName: 'Camera',
      rationale: 'Camera permission is required to capture inspection images.',
    );
  }

  /// Request Microphone Permission
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    return await _handlePermissionRequest(
      context: context,
      permission: Permission.microphone,
      featureName: 'Microphone',
      rationale: 'Microphone permission is required to record inspection audio and voice notes.',
    );
  }

  /// Request Both Camera + Microphone for Video
  Future<bool> requestVideoPermissions(BuildContext context) async {
    final cameraGranted = await requestCameraPermission(context);
    if (!cameraGranted) return false;

    final micGranted = await requestMicrophonePermission(context);
    if (!micGranted) return false;

    return true;
  }

  /// Request Photos / Storage / Media Permission based on Android Version
  Future<bool> requestMediaStoragePermission(
    BuildContext context, {
    bool isVideo = false,
  }) async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;

      bool granted = await _handlePermissionRequest(
        context: context,
        permission: isVideo ? Permission.videos : Permission.photos,
        featureName: 'Media Storage',
        rationale: 'Media permission is required to select inspection images and videos.',
      );

      if (granted) return true;

      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      return await _handlePermissionRequest(
        context: context,
        permission: Permission.storage,
        featureName: 'Storage',
        rationale: 'Storage permission is required to select inspection images and videos.',
      );
    } else {
      return await _handlePermissionRequest(
        context: context,
        permission: Permission.photos,
        featureName: 'Photos',
        rationale: 'Photo library permission is required to select inspection images.',
      );
    }
  }

  /// Internal permission request handler with duplicate guard and permanently denied dialog
  Future<bool> _handlePermissionRequest({
    required BuildContext context,
    required Permission permission,
    required String featureName,
    required String rationale,
  }) async {
    if (_isRequestingPermission) {
      return false;
    }

    // 1. Check current permission status
    PermissionStatus status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showPermanentlyDeniedDialog(context, featureName, rationale);
      }
      return false;
    }

    // 2. Request permission (queries live system status on iOS & Android)
    _isRequestingPermission = true;
    try {
      status = await permission.request();
    } catch (e) {
      debugPrint("Error requesting $featureName permission: $e");
    } finally {
      _isRequestingPermission = false;
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    // 3. Show dialog if permission is permanently denied after request attempt
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await showPermanentlyDeniedDialog(context, featureName, rationale);
      }
      return false;
    }

    return false;
  }

  /// User-friendly Dialog for Permanently Denied Permissions
  Future<void> showPermanentlyDeniedDialog(
    BuildContext context,
    String featureName,
    String rationale,
  ) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "$featureName Permission Required",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            "$rationale Please enable it in Application Settings to proceed.",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              child: const Text(
                "Open Settings",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
