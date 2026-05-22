// this page use for video play to report screen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspection/utils/constant/color_constants.dart'
    show ColorConstants;
import 'package:video_player/video_player.dart';

class FullScreenVideos extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideos({super.key, required this.controller});

  @override
  State<FullScreenVideos> createState() => _FullScreenVideosState();
}

class _FullScreenVideosState extends State<FullScreenVideos> {
  bool isLandscape = true;

  @override
  void initState() {
    super.initState();
    _setLandscape();
    widget.controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    isLandscape = true;
  }

  void _setPortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    isLandscape = false;
  }

  void _toggleRotation() {
    isLandscape ? _setPortrait() : _setLandscape();
    setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            Center(
              child: IconButton(
                iconSize: 70,
                color: Colors.white,
                icon: Icon(
                  widget.controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                onPressed: () {
                  widget.controller.value.isPlaying
                      ? widget.controller.pause()
                      : widget.controller.play();
                },
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: ColorConstants.syanColor,
                      inactiveTrackColor: ColorConstants.lightGreyColor
                          .withOpacity(0.4),
                      thumbColor: ColorConstants.syanColor,
                      overlayColor: ColorConstants.syanColor.withOpacity(0.2),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      min: 0,
                      max: duration.inSeconds.toDouble(),
                      value: position.inSeconds
                          .clamp(0, duration.inSeconds)
                          .toDouble(),
                      onChanged: (value) {
                        widget.controller.seekTo(
                          Duration(seconds: value.toInt()),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_time(position), _time(duration)],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.screen_rotation,
                          color: Colors.white,
                        ),
                        onPressed: _toggleRotation,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _time(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return Text(
      "${two(d.inMinutes)}:${two(d.inSeconds % 60)}",
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }
}
