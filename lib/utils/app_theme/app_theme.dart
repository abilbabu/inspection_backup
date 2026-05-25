import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:inspection/utils/constant/color_constants.dart';

class AppTheme extends StatelessWidget {
  final Widget child;

  const AppTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient
        Container(
          height: 375,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0066A6),
                Color(0xFF00BFA6),
              ],
              stops: [0.2, 8.0],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 300),
              child: ClipPath(
                clipper: WaveClipperTwo(reverse: true),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorConstants.syanColor.withOpacity(0.3),
                        const Color(0xFFB0CDD2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Main Content
        child,
      ],
    );
  }
}