import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';

enum ToastType { success, error, warning, info }

/// Premium floating glassmorphism SnackBar / Toast banner for app warnings, errors, and success feedback.
class CustomToast {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();

    Color bgColor;
    Color borderColor;
    Color iconBgColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case ToastType.error:
        bgColor = const Color(0xFF1E1014);
        borderColor = const Color(0xFFFF4D4D).withOpacity(0.5);
        iconBgColor = const Color(0xFFFF4D4D).withOpacity(0.18);
        iconColor = const Color(0xFFFF5252);
        iconData = Icons.error_outline_rounded;
        break;
      case ToastType.warning:
        bgColor = const Color(0xFF241C0E);
        borderColor = const Color(0xFFFFB74D).withOpacity(0.5);
        iconBgColor = const Color(0xFFFFB74D).withOpacity(0.18);
        iconColor = const Color(0xFFFFB74D);
        iconData = Icons.warning_amber_rounded;
        break;
      case ToastType.success:
        bgColor = const Color(0xFF0D2316);
        borderColor = const Color(0xFF00E676).withOpacity(0.5);
        iconBgColor = const Color(0xFF00E676).withOpacity(0.18);
        iconColor = const Color(0xFF00E676);
        iconData = Icons.check_circle_outline_rounded;
        break;
      case ToastType.info:
        bgColor = const Color(0xFF101C28);
        borderColor = const Color(0xFF40C4FF).withOpacity(0.5);
        iconBgColor = const Color(0xFF40C4FF).withOpacity(0.18);
        iconColor = const Color(0xFF40C4FF);
        iconData = Icons.info_outline_rounded;
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        title,
                        style: ApptextstyleConstants.mediumText(
                          color: Colors.white,
                          fontSize: 13,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    message,
                    style: ApptextstyleConstants.thinText(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    scaffold.showSnackBar(snackBar);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.error);
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.warning);
  }

  static void showSuccess(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.success);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.info);
  }
}
