import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:inspection/utils/network_sync_manager.dart';

class ConfirmSubmissionDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final String bannerText;
  final IconData icon;
  final Color iconBgColor;
  final Color iconBorderColor;
  final Color iconColor;
  final Color bannerBgColor;
  final Color bannerBorderColor;
  final IconData bannerIcon;
  final Color bannerIconColor;
  final Color bannerTextColor;
  final IconData confirmIcon;
  final Gradient confirmGradient;

  const ConfirmSubmissionDialog({
    super.key,
    this.title = "Confirm Submission",
    this.content =
        "The inspection report is about to be submitted as the final version. Please review all inspection details, captured images/videos, audio recordings, conditions, notes, and comments carefully.",
    this.confirmText = "Confirm & Submit",
    this.cancelText = "Cancel & Review",
    this.bannerText = "Submitting locks the inspection data as final.",
    this.icon = Icons.assignment_turned_in_rounded,
    this.iconBgColor = const Color(0xFFE0F2FE),
    this.iconBorderColor = const Color(0xFFBAE6FD),
    this.iconColor = ColorConstants.lightblueColor,
    this.bannerBgColor = const Color(0xFFF0F9FF),
    this.bannerBorderColor = const Color(0xFFBAE6FD),
    this.bannerIcon = Icons.info_outline_rounded,
    this.bannerIconColor = const Color(0xFF0284C7),
    this.bannerTextColor = const Color(0xFF0369A1),
    this.confirmIcon = Icons.check_circle_rounded,
    this.confirmGradient = ColorConstants.buttonGradient,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConfirmSubmissionDialog(),
    );
  }

  static Future<bool?> showExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NetworkAwareExitDialog(),
    );
  }

  static Future<bool?> showDiscard(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConfirmSubmissionDialog(
        title: "Discard Changes?",
        content:
            "Unsaved changes on this step will be cleared. Are you sure you want to go back?",
        confirmText: "Discard",
        cancelText: "Keep Editing",
        bannerText: "Unsaved changes will be cleared.",
        icon: Icons.delete_outline_rounded,
        iconBgColor: Color(0xFFFEE2E2),
        iconBorderColor: Color(0xFFFCA5A5),
        iconColor: Color(0xFFDC2626),
        bannerBgColor: Color(0xFFFEF2F2),
        bannerBorderColor: Color(0xFFFCA5A5),
        bannerIcon: Icons.warning_amber_rounded,
        bannerIconColor: Color(0xFFDC2626),
        bannerTextColor: Color(0xFF991B1B),
        confirmIcon: Icons.delete_forever_rounded,
        confirmGradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Top Badge Icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
                border: Border.all(color: iconBorderColor, width: 2),
              ),
              child: Icon(
                icon,
                size: 36,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle Warning Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bannerBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bannerBorderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    bannerIcon,
                    size: 20,
                    color: bannerIconColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: bannerTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Content Body Text
            Text(
              content,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: confirmGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              confirmIcon,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}

enum NetworkQuality { checking, online, slow, offline }

class NetworkAwareExitDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;

  const NetworkAwareExitDialog({
    super.key,
    this.title = "Exit Basic Inspection?",
    this.content =
        "Are you sure you want to return to the dashboard? Your progress up to the last saved step and any captured media will be safely preserved.",
    this.confirmText = "Exit to Home",
    this.cancelText = "Stay & Resume",
  });

  @override
  State<NetworkAwareExitDialog> createState() => _NetworkAwareExitDialogState();
}

class _NetworkAwareExitDialogState extends State<NetworkAwareExitDialog> {
  NetworkQuality _quality = NetworkQuality.checking;
  bool _isChecking = true;
  int _pendingCount = 0;
  bool _hasEverReconnected = false;

  @override
  void initState() {
    super.initState();
    _checkNetworkQuality();
  }

  Future<void> _checkNetworkQuality() async {
    if (!mounted) return;
    setState(() {
      _isChecking = true;
    });

    try {
      int pending = 0;
      try {
        final tasks = await LocalUploadStorageService.getPendingTasks();
        pending = tasks.length;
      } catch (_) {}

      // 1. Hardware connection check
      final connectivity = await Connectivity().checkConnectivity();
      final isDisconnected =
          connectivity.every((c) => c == ConnectivityResult.none);

      if (isDisconnected) {
        if (mounted) {
          setState(() {
            _quality = NetworkQuality.offline;
            _pendingCount = pending;
            _isChecking = false;
          });
        }
        return;
      }

      // 2. Cross-platform Latency & Socket Probe (Android, iOS, Tablets, Cellular, Wi-Fi)
      bool lookupSucceeded = false;
      int latencyMs = 0;
      final stopwatch = Stopwatch()..start();
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        stopwatch.stop();
        latencyMs = stopwatch.elapsedMilliseconds;
        lookupSucceeded = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        // Fallback probe for iOS / cellular / restricted networks
        try {
          stopwatch.reset();
          stopwatch.start();
          final fallbackResult = await InternetAddress.lookup('cloudflare.com')
              .timeout(const Duration(seconds: 2));
          stopwatch.stop();
          latencyMs = stopwatch.elapsedMilliseconds;
          lookupSucceeded =
              fallbackResult.isNotEmpty && fallbackResult[0].rawAddress.isNotEmpty;
        } catch (_) {
          lookupSucceeded = false;
        }
      }

      if (!lookupSucceeded) {
        if (mounted) {
          setState(() {
            _quality = NetworkQuality.offline;
            _pendingCount = pending;
            _isChecking = false;
          });
        }
        return;
      }

      final isSlow = latencyMs > 1500;
      if (mounted) {
        final wasOffline =
            _quality == NetworkQuality.offline || _quality == NetworkQuality.slow;
        setState(() {
          _quality = isSlow ? NetworkQuality.slow : NetworkQuality.online;
          _pendingCount = pending;
          _isChecking = false;
          if (wasOffline && !isSlow) {
            _hasEverReconnected = true;
          }
        });
        if (!isSlow && pending > 0) {
          NetworkSyncManager().syncIfConnected();
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _quality = NetworkQuality.slow;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quality = NetworkQuality.offline;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quality == NetworkQuality.online) {
      return _buildOnlineDialog();
    }
    return _buildWarningOrCheckingDialog();
  }

  Widget _buildOnlineDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasEverReconnected
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
                border: Border.all(
                  color: _hasEverReconnected
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFDE68A),
                  width: 2,
                ),
              ),
              child: Icon(
                _hasEverReconnected ? Icons.wifi_rounded : Icons.logout_rounded,
                size: 36,
                color: _hasEverReconnected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _hasEverReconnected ? "Connection Restored" : widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _hasEverReconnected
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasEverReconnected
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasEverReconnected
                        ? Icons.check_circle_outline_rounded
                        : Icons.shield_outlined,
                    size: 20,
                    color: _hasEverReconnected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _hasEverReconnected
                          ? "Internet is connected. Syncing local media."
                          : "Progress & captured media will be preserved.",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _hasEverReconnected
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        widget.cancelText,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ColorConstants.buttonGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.lightblueColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.exit_to_app_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                widget.confirmText,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildWarningOrCheckingDialog() {
    final bool isOffline = _quality == NetworkQuality.offline;
    final bool isChecking = _isChecking || _quality == NetworkQuality.checking;

    final Color badgeBg = isOffline
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    final Color badgeBorder = isOffline
        ? const Color(0xFFFCA5A5)
        : const Color(0xFFFDE68A);
    final Color badgeColor = isOffline
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);

    final String title = isChecking
        ? "Checking Connection..."
        : (isOffline ? "No Internet Connection" : "Slow Internet Found");

    final String bannerText;
    if (isChecking) {
      bannerText = "Verifying internet connection & sync status...";
    } else if (isOffline) {
      bannerText = _pendingCount > 0
          ? "Offline Mode: $_pendingCount media item(s) pending sync."
          : "Device is offline. Connect to sync with server.";
    } else {
      bannerText = _pendingCount > 0
          ? "Slow Internet: $_pendingCount item(s) waiting to sync."
          : "Weak or unstable internet connection detected.";
    }

    final String contentText;
    if (isChecking) {
      contentText =
          "Please wait a moment while we check your network connection...";
    } else if (isOffline) {
      contentText =
          "Your internet connection is currently turned off or disconnected. Please reconnect or check your Wi-Fi / mobile data.\n\nYour inspection progress is safely stored on this device.";
    } else {
      contentText =
          "A slow or high-latency internet connection was detected. Syncing media and inspection data to the server may take extra time or fail.\n\nPlease check your network or reconnect to a stronger connection.";
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeBg,
                border: Border.all(color: badgeBorder, width: 2),
              ),
              child: isChecking
                  ? const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFD97706),
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      isOffline
                          ? Icons.wifi_off_rounded
                          : Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                      size: 36,
                      color: badgeColor,
                    ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOffline
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOffline
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOffline ? Icons.wifi_off_rounded : Icons.speed_rounded,
                    size: 20,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isOffline
                            ? const Color(0xFF991B1B)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              contentText,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Top Buttons: Stay & Resume  |  Check / Reconnect
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        "Stay & Resume",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ColorConstants.buttonGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.lightblueColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isChecking ? null : _checkNetworkQuality,
                        child: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "Check Connection",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Secondary option: Exit to Home Anyway
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton.icon(
                icon: const Icon(
                  Icons.exit_to_app_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                label: const Text(
                  "Exit to Home Anyway (Save Offline)",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
