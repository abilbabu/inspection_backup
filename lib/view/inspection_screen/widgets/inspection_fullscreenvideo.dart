import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionFullScreenVideo_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/fullScreenVideos.dart';
import 'package:inspection/view/inspection_screen/widgets/video_recapture_warning_dialog.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class InspectionFullScreenVideo extends StatefulWidget {
  final String videoUrl;
  final String label;
  final bool isReadOnly;

  const InspectionFullScreenVideo({
    super.key,
    required this.videoUrl,
    required this.label,
    this.isReadOnly = false,
  });

  @override
  State<InspectionFullScreenVideo> createState() =>
      _InspectionFullScreenVideoState();
}

class _InspectionFullScreenVideoState extends State<InspectionFullScreenVideo> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isHandlingRecapture = false;

  bool get _effectiveReadOnly =>
      widget.isReadOnly ||
      widget.videoUrl.startsWith('http://') ||
      widget.videoUrl.startsWith('https://');

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _initialized = true);
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRecapture(
    BuildContext context,
    InspectionFullscreenVideoController controller,
  ) async {
    if (_isHandlingRecapture) return;
    _isHandlingRecapture = true;
    try {
      if (controller.isUploading) {
        final result = await VideoRecaptureWarningDialog.show(
          context,
          title: "Operation in Progress",
          bannerText: "Video is currently being processed",
          content:
              "A video capture or processing operation is already in progress. Please wait for it to finish, close this message, or delete the current video before attempting another capture.",
          onDelete: () async {
            try {
              final file = File(widget.videoUrl);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (_) {}
          },
        );
        if (result == VideoRecaptureDialogResult.delete && context.mounted) {
          Navigator.pop(context, "recapture");
        }
        return;
      }

      debugPrint("Recapture triggered in fullscreen video");
      Navigator.pop(context, "recapture");
    } finally {
      _isHandlingRecapture = false;
    }
  }

  void _togglePlayPause() {
    if (!_initialized) return;
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  Duration get _position =>
      _initialized ? _controller.value.position : Duration.zero;

  Duration get _duration =>
      _initialized ? _controller.value.duration : Duration.zero;

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Basic Inspection",
        onBackPress: () => context.pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Consumer<InspectionFullscreenVideoController>(
          builder: (context, controller, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                /// LABEL
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                /// VIDEO AREA
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyan, width: 2.5),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_initialized) {
                          _togglePlayPause();
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_initialized)
                            Center(
                              child: AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: VideoPlayer(_controller),
                              ),
                            )
                          else
                            const Center(child: CircularProgressIndicator()),

                          if (_initialized && _controller.value.isBuffering)
                            const Center(child: CircularProgressIndicator()),

                          /// PLAY BUTTON
                          if (_initialized && !_controller.value.isPlaying)
                            InkWell(
                              onTap: _togglePlayPause,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: ColorConstants.buttonGradient,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          /// TIME + DURATION LINE
                          if (_initialized)
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 40,
                              child: Row(
                                children: [
                                  /// CURRENT TIME
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  /// SLIDER
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                      ),
                                      child: Slider(
                                        min: 0,
                                        max: _duration.inMilliseconds
                                            .toDouble(),
                                        value: _position.inMilliseconds
                                            .clamp(0, _duration.inMilliseconds)
                                            .toDouble(),
                                        onChanged: (value) {
                                          _controller.seekTo(
                                            Duration(
                                              milliseconds: value.toInt(),
                                            ),
                                          );
                                        },
                                        activeColor: ColorConstants.syanColor,
                                        inactiveColor: Colors.white.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  /// TOTAL TIME
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (!_effectiveReadOnly)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _handleRecapture(context, controller),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/svg/repeat.svg',
                                    width: 12,
                                    height: 12,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          Positioned(
                            top: 6,
                            right: 6,
                            child: IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenVideos(
                                      controller: _controller,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (!_effectiveReadOnly) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleRecapture(context, controller),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/svg/repeat.svg',
                              width: 12,
                              height: 12,
                              colorFilter: const ColorFilter.mode(
                                Colors.red,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Click here or the icon to capture again*",
                              style: ApptextstyleConstants.lightText(
                                fontSize: 13,
                                color: ColorConstants.errorcolor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonWidget(
                    text: _effectiveReadOnly ? "CLOSE" : "DONE",
                    textSize: 16,
                    icon: _effectiveReadOnly ? Icons.close : Icons.check,
                    isDisabled: !_effectiveReadOnly && controller.isUploading,
                    showLoader: !_effectiveReadOnly && controller.isUploading,
                    onPressed: () async {
                      if (_effectiveReadOnly) {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.pop();
                        }
                        return;
                      }
                      final file = await controller.saveVideo(widget.videoUrl);

                      if (!context.mounted || file == null) return;
                      Navigator.pop(context, file);
                    },
                  ),
                ),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}
