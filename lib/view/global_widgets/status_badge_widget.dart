import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String statusText;
  final Color statusColor;
  final bool showDot;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const StatusBadgeWidget({
    super.key,
    required this.statusText,
    required this.statusColor,
    this.showDot = true,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            statusText,
            style: ApptextstyleConstants.thinText(
              fontSize: fontSize,
              color: statusColor,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
