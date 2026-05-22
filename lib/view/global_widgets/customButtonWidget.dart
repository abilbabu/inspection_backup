import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/color_constants.dart';

class CustomButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double borderRadius;
  final double padding;
  final Color textColor;
  final double textSize;
  final bool isDisabled;
  final bool showLoader;

  const CustomButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.borderRadius = 12,
    this.padding = 10,
    this.textColor = Colors.white,
    required this.textSize,
    this.isDisabled = false,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isDisabled || showLoader;

    return InkWell(
      onTap: disabled ? null : onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 15,
                spreadRadius: 1,
                offset: Offset(5, 5),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: padding),
          child: Center(
            child: showLoader
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: textColor, size: textSize + 2),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: textSize,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class CustomButtonTwo extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double borderRadius;
  final double padding;
  final Gradient? textGradient;
  final Gradient? borderGradient;
  final double textSize;
  final bool isDisabled;
  final bool showLoader;

  const CustomButtonTwo({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.borderRadius = 12,
    this.padding = 10,
    this.textGradient,
    this.borderGradient,
    this.textSize = 14,
    this.isDisabled = false,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isDisabled || showLoader;

    final Gradient borderGradient =
        textGradient ??
        const LinearGradient(colors: [Color(0xFF0066A6), Color(0xFF00BFA6)]);

    return InkWell(
      onTap: disabled ? null : onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: borderGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 15,
                spreadRadius: 1,
                offset: Offset(5, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: Container(
            decoration: BoxDecoration(
              color: ColorConstants.whiteColor,
              borderRadius: BorderRadius.circular(borderRadius - 1.5),
            ),
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: padding),
            child: Center(
              child: showLoader
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _GradientContent(
                      text: text,
                      icon: icon,
                      gradient: borderGradient,
                      textSize: textSize,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientContent extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Gradient gradient;
  final double textSize;

  const _GradientContent({
    required this.text,
    required this.gradient,
    required this.textSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      blendMode: BlendMode.srcIn,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: textSize + 2, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: textSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
