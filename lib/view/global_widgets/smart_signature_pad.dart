import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:signature/signature.dart';

/// A smart signature pad that prevents accidental markings when the user scrolls the page.
/// 
/// In Scroll Mode (default):
/// - Touch & drag events pass directly through to the parent scroll view.
/// - Accidental scroll strokes are never drawn on the signature canvas.
/// - Tapping anywhere on the pad activates Signing Mode.
/// 
/// In Signing Mode:
/// - The canvas captures touch events for natural signing.
/// - A prominent [Done] button allows the user to immediately lock the signature.
/// - Automatically auto-locks after 1.8 seconds of inactivity once a signature is drawn.
/// - Intelligently detects upward scroll-flick attempts, undoes the accidental vertical stroke,
///   and locks the pad so subsequent swipes scroll the page.
class SmartSignaturePad extends StatefulWidget {
  final SignatureController controller;
  final double height;
  final String label;
  final VoidCallback? onCleared;

  const SmartSignaturePad({
    super.key,
    required this.controller,
    required this.height,
    this.label = "Signature",
    this.onCleared,
  });

  @override
  State<SmartSignaturePad> createState() => _SmartSignaturePadState();
}

class _SmartSignaturePadState extends State<SmartSignaturePad> {
  bool _isSigningActive = false;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _setupControllerCallbacks();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _setupControllerCallbacks() {
    widget.controller.onDrawStart = () {
      _inactivityTimer?.cancel();
    };

    widget.controller.onDrawEnd = () {
      _inactivityTimer?.cancel();
      _checkScrollSwipeAttempt();

      // Auto-lock signature after 1.8 seconds of no touches once drawn
      _inactivityTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _isSigningActive && widget.controller.isNotEmpty) {
          setState(() {
            _isSigningActive = false;
          });
        }
      });
    };
  }

  /// Detects if an upward drag was actually a scroll attempt rather than a signature stroke.
  /// If the user flicked upwards exiting the top edge, undo the line and lock for scrolling.
  void _checkScrollSwipeAttempt() {
    if (widget.controller.isEmpty) return;
    try {
      final strokes = widget.controller.pointsToStrokes(3);
      if (strokes.isEmpty) return;
      final lastStroke = strokes.last;
      if (lastStroke.length >= 2) {
        final start = lastStroke.first.offset;
        final end = lastStroke.last.offset;
        final dy = end.dy - start.dy;
        final dx = end.dx - start.dx;

        // Upward swipe check: moved upwards by > 45px, ended near the top 30px, and mostly vertical
        if (dy < -45 && end.dy <= 30 && dy.abs() > 2.5 * dx.abs()) {
          widget.controller.undo();
          if (mounted) {
            setState(() {
              _isSigningActive = false;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSignature = widget.controller.isNotEmpty;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Base signature container with state-aware border styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: ColorConstants.dashboardboxShadow,
              border: Border.all(
                color: _isSigningActive
                    ? const Color(0xFF00BFA6)
                    : (hasSignature
                        ? ColorConstants.syanColor
                        : ColorConstants.syanColor.withOpacity(0.6)),
                width: _isSigningActive ? 2.0 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_isSigningActive) {
                    setState(() {
                      _isSigningActive = true;
                    });
                  }
                },
                child: IgnorePointer(
                  ignoring: !_isSigningActive,
                  child: Signature(
                    controller: widget.controller,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Friendly placeholder when empty and not actively signing
          if (!_isSigningActive && !hasSignature)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Icon(
                          Icons.draw_outlined,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap here to sign",
                        style: ApptextstyleConstants.mediumText(
                          color: const Color(0xFF0066A6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Drag anywhere to scroll",
                        style: ApptextstyleConstants.lightText(
                          color: ColorConstants.toastgrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top-right mode indicator / Done button
          Positioned(
            top: 10,
            right: 10,
            child: _isSigningActive
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSigningActive = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Done",
                            style: ApptextstyleConstants.mediumText(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : (hasSignature
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF81C784),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 12,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Locked • Scroll safe",
                              style: ApptextstyleConstants.lightText(
                                color: const Color(0xFF2E7D32),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),
          ),

          // Bottom-right controls (Edit & Clear)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isSigningActive && hasSignature)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isSigningActive = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ColorConstants.syanColor.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit,
                              size: 13,
                              color: Color(0xFF0066A6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Edit",
                              style: ApptextstyleConstants.lightText(
                                color: const Color(0xFF0066A6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (hasSignature || _isSigningActive)
                  IconButton(
                    onPressed: () {
                      widget.controller.clear();
                      widget.onCleared?.call();
                      setState(() {
                        _isSigningActive = true;
                      });
                    },
                    tooltip: "Clear signature",
                    icon: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedEraser,
                        size: 26,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

