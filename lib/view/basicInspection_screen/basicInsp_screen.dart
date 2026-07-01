// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/basicInsp_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/fullScreenVideos.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:video_player/video_player.dart';

class BasicinspScreen extends StatefulWidget {
  final int jobId;
  const BasicinspScreen({super.key, required this.jobId});
  @override
  State<BasicinspScreen> createState() => _BasicinspScreenState();
}

class _BasicinspScreenState extends State<BasicinspScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = BasicinspController(jobId: widget.jobId);
        Future.microtask(() async {
          await controller.getBasicimageList();
          await controller.initSpeech();
        });
        return controller;
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (_) async {
          if (await _showExitConfirmation()) {
            context.go('/home');
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: CustomAppBar(
            title: "Basic Inspection",
            onBackPress: () async {
              if (await _showExitConfirmation()) {
                context.go('/home');
              }
            },
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Consumer<BasicinspController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(4, (_) => _inspectionShimmer()),
                      ),
                    );
                  }
                  controller.checkAndShowResumeStage(context);
                  if (!controller.isBackendFullyConfigured) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 280),
                            Icon(
                              Icons.warning_amber_rounded,
                              color: ColorConstants.orangecolor,
                              size: 120,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Inspection Image Settings Incomplete",
                              textAlign: TextAlign.center,
                              style: ApptextstyleConstants.lightText(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Please define External image lists in backend.",
                              textAlign: TextAlign.center,
                              style: ApptextstyleConstants.thinText(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 20),
                            CustomButtonWidget(
                              text: 'Go To Home',
                              textSize: 14,
                              onPressed: () {
                                context.go('/home');
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final isImageStage =
                      controller.currentStage ==
                          InspectionStage.externalImages ||
                      controller.currentStage == InspectionStage.internalImages;
                  if (isImageStage && controller.currentImages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  Map<String, dynamic>? item = controller.currentItem;
                  int imageCount = item?['imageCount'] ?? 0;
                  bool videoFlag = item?['videoFlag'] ?? false;
                  int videoDuration = item?['videoDuration'] ?? 0;
                  final String title = controller.isExternalSelected
                      ? "External Image"
                      : "Internal Image";
                  final String label =
                      controller.currentStage == InspectionStage.external360
                      ? "External 360 Video"
                      : controller.currentStage == InspectionStage.internal360
                      ? "Internal 360 Video"
                      : (item?['imageLabel'] ?? "");

                  final bool isMandatory = item?['imageMandatory'] ?? false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 25,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title.toUpperCase(),
                              style: ApptextstyleConstants.lightText(
                                fontSize: 18,
                                color: ColorConstants.blackColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  label.toUpperCase(),
                                  style: ApptextstyleConstants.italicText(
                                    fontSize: 16,
                                    color: ColorConstants.greenColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildDynamicLayout(
                          context,
                          controller,
                          imageCount,
                          videoFlag,
                          videoDuration,
                        ),
                        const SizedBox(height: 10),
                        _textfield(controller, context),
                        Row(
                          children: [
                            if (controller.shouldShowSkip) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomButtonTwo(
                                  text: "SKIP",
                                  isDisabled:
                                      controller.isVideoLoading ||
                                      controller.isUploading,
                                  onPressed: () => controller.skipStep(context),
                                ),
                              ),
                            ],
                            SizedBox(width: 5),
                            Expanded(
                              child: CustomButtonWidget(
                                text: "PROCEED",
                                textSize: 16,
                                isDisabled:
                                    controller.isUploading ||
                                    controller.isVideoLoading ||
                                    (!controller.isCurrentMandatory &&
                                        !controller.hasAnyMedia),
                                showLoader: controller.isUploading,
                                onPressed: () async {
                                  final isValid = controller
                                      .validateMandatoryImage();
                                  if (!isValid) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            ColorConstants.errorcolor,
                                        content: Text(
                                          controller.is360Stage
                                              ? "External 360 Video is mandatory"
                                              : "Please capture required image",
                                          style: ApptextstyleConstants.thinText(
                                            color: ColorConstants.whiteColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final success = await controller.proceedStep(
                                    jobId: widget.jobId,
                                    status: 2,
                                  );
                                  if (success) {
                                    controller.nextStep(context);
                                    controller.notesController.clear();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        if (isMandatory && !controller.is360Stage)
                          Builder(
                            builder: (context) {
                              final hasImage = controller
                                  .capturedImages
                                  .isNotEmpty; // already filtered list
                              final hasNote = controller.notesController.text
                                  .trim()
                                  .isNotEmpty;

                              if (hasImage && hasNote) return const SizedBox();

                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 6,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.deepOrange.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.deepOrange,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Capture at least one image",
                                          style: ApptextstyleConstants.thinText(
                                            fontSize: 12,
                                            color: ColorConstants.blackColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textfield(BasicinspController controller, BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: controller.notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) =>
                context.read<BasicinspController>().notes = value,
            decoration: InputDecoration(
              hintText: "Contents & Additional Notes",
              hintStyle: ApptextstyleConstants.thinText(
                color: Colors.grey,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.only(
                left: 12,
                right: 60,
                top: 12,
                bottom: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: ColorConstants.activecolor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            child: controller.showListeningUI
                ? _buildWaveMic(controller)
                : IconButton(
                    icon: Icon(
                      Icons.mic_none,
                      color: ColorConstants.greenColor,
                    ),
                    onPressed: () => controller.startListening(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLayout(
    BuildContext context,
    BasicinspController controller,
    int imageCount,
    bool videoFlag,
    int videoDuration,
  ) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    final bool isLandscape = orientation == Orientation.landscape;

    double h(double portrait, double landscape) {
      return isLandscape ? size.height * landscape : size.height * portrait;
    }

    final boxHeight = isLandscape ? size.height * 0.45 : size.height * 0.22;
    final largeBoxHeight = isLandscape ? size.height * 0.7 : size.height * 0.60;

    final is360Stage =
        controller.currentStage == InspectionStage.external360 ||
        controller.currentStage == InspectionStage.internal360;
    Widget imageBox(int index, {double? height}) {
      final file = controller.imageAt(index);
      return GestureDetector(
        onTap: () => controller.handleImageTap(
          context,
          imageIndex: index,
          mediaType: MediaType.image,
        ),
        child: Stack(
          children: [
            Container(
              height: height ?? boxHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                // color: ColorConstants.whiteColor,
                border: Border.all(color: const Color(0xFFDADADA), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: file != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : const Center(child: Icon(Icons.camera_alt, size: 30)),
            ),
            if (file != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    controller.handleImageTap(
                      context,
                      imageIndex: index,
                      mediaType: MediaType.image,
                    );
                  },
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
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget videoBox({double? height}) {
      final videoFile = controller.capturedVideo;
      final duration = is360Stage
          ? controller.current360Duration
          : videoDuration;
      return GestureDetector(
        onTap: controller.isVideoLoading
            ? null
            : () {
                final rootContext = Navigator.of(
                  context,
                  rootNavigator: true,
                ).context;
                controller.handleImageTap(
                  rootContext,
                  imageIndex: 0,
                  mediaType: MediaType.video,
                  maxDuration: duration,
                );
              },
        child: Stack(
          children: [
            Container(
              height: height ?? boxHeight,
              decoration: BoxDecoration(
                border:Border.all(color: const Color(0xFFDADADA), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: videoFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPreviewWidget(file: videoFile),
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          if (controller.isVideoLoading)
                            Container(
                              color: Colors.black.withOpacity(0.4),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : controller.isVideoLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ColorConstants.syanColor,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.videocam,
                        color: ColorConstants.greyColor,
                        size: 35,
                      ),
                    ),
            ),
            if (videoFile != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    final rootContext = Navigator.of(
                      context,
                      rootNavigator: true,
                    ).context;
                    controller.handleImageTap(
                      rootContext,
                      imageIndex: 0,
                      mediaType: MediaType.video,
                      maxDuration: duration,
                    );
                  },
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
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () async {
                  if (videoFile == null) return;
                  final videoController = VideoPlayerController.file(videoFile);
                  await videoController.initialize();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullScreenVideos(controller: videoController),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    if (is360Stage) {
      return videoBox(height: largeBoxHeight);
    }
    if (imageCount == 1 && !videoFlag) {
      return imageBox(0, height: h(0.60, 0.75));
    }
    if (imageCount == 1 && videoFlag) {
      return Column(
        children: [
          imageBox(
            0,
            height: isLandscape ? size.height * 0.6 : size.height * 0.35,
          ),
          const SizedBox(height: 10),
          videoBox(height: boxHeight),
        ],
      );
    }
    if (imageCount == 2 && !videoFlag) {
      return Column(
        children: [
          imageBox(0, height: h(0.28, 0.45)),
          const SizedBox(height: 10),
          imageBox(1, height: h(0.28, 0.45)),
        ],
      );
    }
    if (imageCount == 2 && videoFlag) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: imageBox(0, height: h(0.35, 0.55))),
              const SizedBox(width: 10),
              Expanded(child: imageBox(1, height: h(0.35, 0.55))),
            ],
          ),
          const SizedBox(height: 10),
          videoBox(height: h(0.22, 0.40)),
        ],
      );
    }
    if (imageCount == 3 && !videoFlag) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: imageBox(0)),
          const SizedBox(width: 8),
          Expanded(child: imageBox(1)),
          const SizedBox(width: 8),
          Expanded(child: imageBox(2)),
        ],
      );
      // GridView.builder(
      //   shrinkWrap: true,
      //   physics: const NeverScrollableScrollPhysics(),
      //   itemCount: 3,
      //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      //     crossAxisCount: 2,
      //     crossAxisSpacing: 10,
      //     mainAxisSpacing: 10,
      //     childAspectRatio: 0.7,
      //   ),
      //   itemBuilder: (_, index) => imageBox(index),
      // );
    }
    if (imageCount == 3 && videoFlag) {
      return Column(
        children: [
          // GridView.builder(
          //   shrinkWrap: true,
          //   physics: const NeverScrollableScrollPhysics(),
          //   itemCount: 3,
          //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //     crossAxisCount: 3,
          //     crossAxisSpacing: 8,
          //     mainAxisSpacing: 8,
          //     childAspectRatio: 0.6,
          //   ),
          //   itemBuilder: (_, index) => imageBox(index),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: imageBox(0)),
              const SizedBox(width: 8),
              Expanded(child: imageBox(1)),
              const SizedBox(width: 8),
              Expanded(child: imageBox(2)),
            ],
          ),
          const SizedBox(height: 10),
          videoBox(height: boxHeight),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildWaveMic(BasicinspController controller) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            width: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 6, end: 20),
                  duration: Duration(milliseconds: 400 + (index * 150)),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 4,
                      height: controller.isListening ? value : 6,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                  onEnd: () {
                    if (controller.isListening) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: controller.stopListening,
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Discard changes?"),
            content: const Text(
              "Unsaved changes will be cleared. Are you sure you want to go back?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("NO"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("YES"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _inspectionShimmer() {
    return Shimmer(
      color: Colors.white,
      colorOpacity: 0.3,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}
