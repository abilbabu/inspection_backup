import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionFullScreenVideo_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/fullScreenVideos.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class InspectionFullScreenVideo extends StatefulWidget {
  final String videoUrl;
  final String label;

  const InspectionFullScreenVideo({
    super.key,
    required this.videoUrl,
    required this.label,
  });

  @override
  State<InspectionFullScreenVideo> createState() =>
      _InspectionFullScreenVideoState();
}

class _InspectionFullScreenVideoState extends State<InspectionFullScreenVideo> {
  late VideoPlayerController _controller;
  bool _initialized = false;

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
                            FutureBuilder<Size>(
                              future: _getVideoSize(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final size = snapshot.data!;
                                final isLandscape = size.width > size.height;

                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.cyan,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: Transform.rotate(
                                        angle: isLandscape ? 1.5708 : 0,
                                        child: SizedBox(
                                          width: size.width,
                                          height: size.height,
                                          child: VideoPlayer(_controller),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          else
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

                          Positioned(
                            bottom: 10,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context, "recapture"),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  'assets/svg/repeat.svg',
                                  width: 18,
                                  height: 18,
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

                const SizedBox(height: 20),

                /// CLOSE BUTTON
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/svg/repeat.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Colors.red,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(width: 2),
                    Text(
                      "Click the icon to capture again*",
                      style: ApptextstyleConstants.lightText(
                        fontSize: 12,
                        color: ColorConstants.errorcolor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CustomButtonWidget(
                    text: "DONE",
                    textSize: 16,
                    icon: Icons.check,
                    isDisabled: controller.isUploading,
                    showLoader: controller.isUploading,
                    onPressed: () async {
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

  Future<Size> _getVideoSize() async {
    final value = _controller.value;

    if (!value.isInitialized) {
      return const Size(1, 1);
    }

    return Size(value.size.width, value.size.height);
  }
}
