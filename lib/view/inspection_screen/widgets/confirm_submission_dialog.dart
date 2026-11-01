import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/color_constants.dart';

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
      builder: (context) => const ConfirmSubmissionDialog(
        title: "Exit Basic Inspection?",
        content:
            "Are you sure you want to return to the dashboard? Your progress up to the last saved step and any captured media will be safely preserved.",
        confirmText: "Exit to Home",
        cancelText: "Stay & Resume",
        bannerText: "Progress & captured media will be preserved.",
        icon: Icons.logout_rounded,
        iconBgColor: Color(0xFFFEF3C7),
        iconBorderColor: Color(0xFFFDE68A),
        iconColor: Color(0xFFD97706),
        bannerBgColor: Color(0xFFFFFBEB),
        bannerBorderColor: Color(0xFFFDE68A),
        bannerIcon: Icons.shield_outlined,
        bannerIconColor: Color(0xFFD97706),
        bannerTextColor: Color(0xFFB45309),
        confirmIcon: Icons.exit_to_app_rounded,
      ),
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
      child: Padding(
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
    );
  }
}
