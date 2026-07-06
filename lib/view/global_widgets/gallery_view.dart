import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/basicInspectionReport_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/fullScreenVideos.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:video_player/video_player.dart';

class GalleryView extends StatefulWidget {
  final int jobId;
  final String type;
  const GalleryView({super.key, required this.jobId, required this.type});

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BasicInspectionReportController>().getBasicInspection(
        widget.jobId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        context.pop();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.type == 'external'
              ? "External Images"
              : "Internal Images",
          onBackPress: () {
            context.pop();
          },
        ),
        body: Consumer<BasicInspectionReportController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return inspectionShimmerList();
            }
            List<Map<String, dynamic>> groups = widget.type == 'external'
                ? controller.externalGroups
                : controller.internalGroups;
            if (groups.isEmpty) {
              return const Center(child: Text("No images available"));
            }
            String toTitleCase(String text) {
              if (text.isEmpty) return text;
              return text
                  .split(' ')
                  .map(
                    (word) => word.isEmpty
                        ? word
                        : word[0].toUpperCase() +
                              word.substring(1).toLowerCase(),
                  )
                  .join(' ');
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final images = group["images"] as List? ?? [];
                        final videoUrl = group["videoUrl"];
                        final comment = group["comment"] ?? "";
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (images.isNotEmpty || videoUrl != null) ...[
                              Text(
                                toTitleCase(group["label"] ?? ""),
                                style: ApptextstyleConstants.mediumText(
                                  fontSize: 16,
                                  color: ColorConstants.blackColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3, // ALWAYS 3
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1, // PERFECT SQUARE
                                  ),
                              itemCount: 3, // ALWAYS 3 SLOTS
                              itemBuilder: (context, index) {
                                if (index >= images.length) {
                                  // 👉 Empty placeholder
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: ColorConstants.whiteColor
                                          .withOpacity(0.3),
                                    ),
                                  );
                                }
                                final image = images[index];
                                return InkWell(
                                  onTap: () {
                                    context.push(
                                      '/fullScreenImage',
                                      extra: {
                                        'imageUrl': image['url'],
                                        'label': group["label"],
                                      },
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow:
                                          ColorConstants.dashboardboxShadow,
                                      borderRadius: BorderRadius.circular(15),
                                      color: ColorConstants.whiteColor,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          image["url"] ?? "",
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.broken_image,
                                                );
                                              },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            if (videoUrl != null)
                              GroupVideoPlayer(videoUrl: videoUrl),
                            SizedBox(height: 10),
                            if (comment.isNotEmpty) ...[
                              Text(
                                "Inspection Comments",
                                style: ApptextstyleConstants.lightText(
                                  fontSize: 12,
                                  color: ColorConstants.blackColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ColorConstants.whiteColor,
                                  border: Border.all(
                                    color: ColorConstants.greyColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: ColorConstants.dashboardboxShadow,
                                ),
                                child: Text(
                                  comment,
                                  style: ApptextstyleConstants.boldItalicText(
                                    fontSize: 13,
                                    color: ColorConstants.blackColor,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButtonWidget(
                        text: "Close",
                        textSize: 16,
                        textColor: ColorConstants.whiteColor,
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget inspectionShimmerList() {
    return Shimmer(
      duration: const Duration(seconds: 2),
      color: Colors.white,
      colorOpacity: 0.3,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              shimmerBox(height: 14, radius: 4),
              const SizedBox(height: 6),
              shimmerGrid(),
              const SizedBox(height: 10),
              shimmerBox(height: 12, radius: 4),
              const SizedBox(height: 6),
              shimmerBox(height: 40, radius: 8),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget shimmerBox({double height = 100, double radius = 10}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget shimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: 3,
      itemBuilder: (_, __) => shimmerBox(),
    );
  }
}

class GroupVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const GroupVideoPlayer({super.key, required this.videoUrl});
  @override
  State<GroupVideoPlayer> createState() => _GroupVideoPlayerState();
}

class _GroupVideoPlayerState extends State<GroupVideoPlayer> {
  late VideoPlayerController _controller;
  bool isInitialized = false;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        duration = _controller.value.duration;
        setState(() {
          isInitialized = true;
        });
      });
    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (!mounted) return;
    setState(() {
      position = _controller.value.position;
      isPlaying = _controller.value.isPlaying;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _seek(Duration d) {
    _controller.seekTo(d);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.whiteColor,
        boxShadow: ColorConstants.dashboardboxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: !isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    Center(
                      child: IconButton(
                        iconSize: 52,
                        color: ColorConstants.lightGreyColor,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      left: 8,
                      right: 8,
                      child: Column(
                        children: [
                          Slider(
                            min: 0,
                            max: duration.inSeconds.toDouble(),
                            value: position.inSeconds
                                .clamp(0, duration.inSeconds)
                                .toDouble(),
                            onChanged: (value) =>
                                _seek(Duration(seconds: value.toInt())),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [_time(position), _time(duration)],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FullScreenVideos(controller: _controller),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _time(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return Text(
      "${two(d.inMinutes)}:${two(d.inSeconds % 60)}",
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }
}
