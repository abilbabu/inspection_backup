import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/basicInspectionReport_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/dummyDB/Dummydb.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/fullScreenVideos.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:video_player/video_player.dart';

class BasicInspectionReport extends StatefulWidget {
  final int jobId;

  const BasicInspectionReport({super.key, required this.jobId});

  @override
  State<BasicInspectionReport> createState() => _BasicInspectionReportState();
}

class _BasicInspectionReportState extends State<BasicInspectionReport> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reportController = context.read<BasicInspectionReportController>();
      await Future.wait([
        reportController.getVehicleEssentialList(),
        reportController.getBasicInspection(widget.jobId),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Basic Inspection Report",
          onBackPress: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        body: Consumer<BasicInspectionReportController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _inspectionShimmer(),
                    _inspectionShimmer(),
                    _inspectionShimmer(),
                    _inspectionShimmer(),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    VehicleSummaryWidget(jobId: widget.jobId),
                    SizedBox(height: 12),
                    _registrationCardSection(controller),
                    SizedBox(height: 15),
                    _imageViewSection(context, controller),
                    SizedBox(height: 15),
                    _360VideoSection(),
                    SizedBox(height: 15),
                    _cardiagramSection(context, controller),
                    SizedBox(height: 15),
                    // _additionalCommentSection(controller),
                    // SizedBox(height: 15),
                    _signatureSection(controller, context),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Container _signatureSection(
    BasicInspectionReportController controller,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: ColorConstants.dashboardboxShadow,
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.whiteColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Service Advisor Signature Captured",
              style: ApptextstyleConstants.mediumText(
                fontSize: 14,
                color: ColorConstants.blackColor,
              ),
            ),
            SizedBox(height: 12),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: ColorConstants.dashboardboxShadow,
                borderRadius: BorderRadius.circular(15),
                color: ColorConstants.whiteColor,
              ),
              child:
                  controller.signature != null &&
                      controller.signature!["url"] != null
                  ? Image.network(
                      controller.signature!["url"],
                      fit: BoxFit.contain,
                    )
                  : const Center(child: Text("No Signature Available")),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomButtonWidget(
                textSize: 16,
                text: "Close",
                textColor: ColorConstants.whiteColor,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/jobcarddetails', extra: widget.jobId);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Container _additionalCommentSection(
  //   BasicInspectionReportController controller,
  // ) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(15),
  //       color: ColorConstants.whiteColor,
  //       boxShadow: ColorConstants.dashboardboxShadow,
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             " Customer Complaint:",
  //             style: ApptextstyleConstants.mediumText(
  //               fontSize: 14,
  //               color: ColorConstants.blackColor,
  //             ),
  //           ),
  //           Container(
  //             decoration: BoxDecoration(
  //               color: ColorConstants.whiteColor,
  //               border: Border.all(color: ColorConstants.greyColor),
  //               borderRadius: BorderRadius.circular(8),
  //               boxShadow: ColorConstants.dashboardboxShadow,
  //             ),
  //             child: TextField(
  //               controller: controller.additionalCommentsController,
  //               readOnly: true,
  //               maxLines: 4,
  //               style: ApptextstyleConstants.lightText(
  //                 color: ColorConstants.blackColor,
  //                 fontSize: 14,
  //               ),
  //               decoration: InputDecoration(
  //                 hintText: "No additional comments available",
  //                 hintStyle: ApptextstyleConstants.lightText(
  //                   color: ColorConstants.greyColor,
  //                   fontSize: 13,
  //                 ),
  //                 contentPadding: const EdgeInsets.all(12),
  //                 border: InputBorder.none,
  //                 filled: true,
  //                 fillColor: ColorConstants.whiteColor,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Container _cardiagramSection(
    BuildContext context,
    BasicInspectionReportController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.whiteColor,
        boxShadow: ColorConstants.dashboardboxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inspection Diagram",
              style: ApptextstyleConstants.mediumText(
                fontSize: 14,
                color: ColorConstants.blackColor,
              ),
            ),
            SizedBox(height: 12),
            InkWell(
              onTap: () {
                context.push(
                  '/fullScreenImage',
                  extra: {
                    'imageUrl': controller.diagram!["url"],
                    'label': "Inspection Diagram",
                  },
                );
              },
              child: Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: ColorConstants.whiteColor,
                  boxShadow: ColorConstants.dashboardboxShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child:
                          controller.diagram != null &&
                              controller.diagram!["url"] != null
                          ? Image.network(
                              controller.diagram!["url"],
                              fit: BoxFit.contain,
                            )
                          : const Center(child: Text("No Diagram Available")),
                    ),
                    SizedBox(height: 5),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: ColorConstants.activecolor,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Legend",
                                  style: ApptextstyleConstants.regularText(
                                    fontSize: 12,
                                    color: ColorConstants.blackColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(
                                    DummyDB.damageList.length,
                                    (index) {
                                      final item = DummyDB.damageList[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          "${item["emoji"]} ${item["label"]}",
                                          style:
                                              ApptextstyleConstants.lightText(
                                                color: item["color"],
                                                fontSize: 11,
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
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _imageViewSection(
    BuildContext context,
    BasicInspectionReportController controller,
  ) {
    String toTitleCase(String text) {
      if (text.isEmpty) return text;
      return text
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : word[0].toUpperCase() + word.substring(1).toLowerCase(),
          )
          .join(' ');
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ColorConstants.dashboardboxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Text(
              "Inspection Images",
              style: ApptextstyleConstants.mediumText(
                fontSize: 14,
                color: ColorConstants.blackColor,
              ),
            ),
            SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      Text(
                        "External Images",
                        style: ApptextstyleConstants.boldItalicText(
                          fontSize: 14,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          context.push(
                            '/galleryview',
                            extra: {'jobId': widget.jobId, 'type': 'external'},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.syanColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "View All",
                            style: ApptextstyleConstants.mediumText(
                              fontSize: 12,
                              color: ColorConstants.syanColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.externalGroups.length > 5
                        ? 5
                        : controller.externalGroups.length,
                    itemBuilder: (context, index) {
                      final group = controller.externalGroups[index];
                      final images = group["images"] as List? ?? [];
                      if (images.isEmpty) return const SizedBox();
                      final firstImage = images.first;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            context.push(
                              '/fullScreenImage',
                              extra: {
                                'imageUrl': images.first["url"] ?? "",
                                'label': group["label"] ?? "",
                              },
                            );
                          },
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: ColorConstants.toastgrey,
                              border: Border.all(
                                color: ColorConstants.activecolor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    firstImage["url"] ?? "",
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      toTitleCase(group["label"] ?? ""),
                                      style: ApptextstyleConstants.thinText(
                                        fontSize: 12,
                                        color: ColorConstants.whiteColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(thickness: 1, color: ColorConstants.greyColor),
            SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    children: [
                      Text(
                        "Internal Images",
                        style: ApptextstyleConstants.boldItalicText(
                          fontSize: 14,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          context.push(
                            '/galleryview',
                            extra: {'jobId': widget.jobId, 'type': 'internal'},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.syanColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "View All",
                            style: ApptextstyleConstants.mediumText(
                              fontSize: 12,
                              color: ColorConstants.syanColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.internalGroups.length > 5
                        ? 5
                        : controller.internalGroups.length,
                    itemBuilder: (context, index) {
                      final group = controller.internalGroups[index];
                      final images = group["images"] as List? ?? [];
                      if (images.isEmpty) return const SizedBox();
                      final firstImage = images.first;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {
                            context.push(
                              '/fullScreenImage',
                              extra: {
                                'imageUrl': images.first["url"] ?? "",
                                'label': group["label"] ?? "",
                              },
                            );
                          },
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: ColorConstants.toastgrey,
                              border: Border.all(
                                color: ColorConstants.activecolor,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    firstImage["url"] ?? "",
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      toTitleCase(group["label"] ?? ""),
                                      style: ApptextstyleConstants.thinText(
                                        fontSize: 12,
                                        color: ColorConstants.whiteColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _360VideoSection() {
    return Consumer<BasicInspectionReportController>(
      builder: (context, controller, _) {
        final hasExternalVideo =
            controller.externalVideoController != null ||
            (controller.external360Video != null &&
                controller.external360Video!.isNotEmpty);
        final hasInternalVideo =
            controller.internalVideoController != null ||
            (controller.internal360Video != null &&
                controller.internal360Video!.isNotEmpty);
        if (!hasExternalVideo && !hasInternalVideo) {
          return const SizedBox();
        }
        final externalComment = controller.external360Comment ?? "";
        final internalComment = controller.internal360Comment ?? "";
        return Container(
          decoration: BoxDecoration(
            color: ColorConstants.whiteColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "360° Video",
                  style: ApptextstyleConstants.mediumText(
                    fontSize: 14,
                    color: ColorConstants.blackColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (hasExternalVideo) ...[
                  Text(
                    "External 360 Video",
                    style: ApptextstyleConstants.boldItalicText(
                      fontSize: 14,
                      color: ColorConstants.blackColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildVideoPlayer(
                    context: context,
                    controller: controller.externalVideoController,
                    isInitialized: controller.isExternalVideoInitialized,
                    isPlaying: controller.isExternalVideoPlaying,
                    position: controller.externalVideoPosition,
                    duration: controller.externalVideoDuration,
                    onPlayPause: controller.toggleExternalPlayPause,
                    onSeek: controller.seekExternalVideo,
                  ),
                  const SizedBox(height: 10),
                  if (externalComment.isNotEmpty) ...[
                    Text(
                      "360 External Video Inspection Comments",
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
                        border: Border.all(color: ColorConstants.greyColor),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: ColorConstants.dashboardboxShadow,
                      ),
                      child: Text(
                        externalComment,
                        style: ApptextstyleConstants.boldItalicText(
                          fontSize: 13,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 15),
                ],
                if (hasInternalVideo) ...[
                  Text(
                    "Internal 360 Video",
                    style: ApptextstyleConstants.boldItalicText(
                      fontSize: 14,
                      color: ColorConstants.blackColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildVideoPlayer(
                    context: context,
                    controller: controller.internalVideoController,
                    isInitialized: controller.isInternalVideoInitialized,
                    isPlaying: controller.isInternalVideoPlaying,
                    position: controller.internalVideoPosition,
                    duration: controller.internalVideoDuration,
                    onPlayPause: controller.toggleInternalPlayPause,
                    onSeek: controller.seekInternalVideo,
                  ),
                  const SizedBox(height: 10),
                  if (internalComment.isNotEmpty) ...[
                    Text(
                      "360 Internal Video Comments",
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
                        border: Border.all(color: ColorConstants.greyColor),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: ColorConstants.dashboardboxShadow,
                      ),
                      child: Text(
                        internalComment,
                        style: ApptextstyleConstants.boldItalicText(
                          fontSize: 13,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer({
    required BuildContext context,
    required VideoPlayerController? controller,
    required bool isInitialized,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required VoidCallback onPlayPause,
    required Function(Duration) onSeek,
  }) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: ColorConstants.whiteColor,
        boxShadow: ColorConstants.dashboardboxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: controller == null
            ? Center(
                child: Text(
                  "No Video Available",
                  style: ApptextstyleConstants.lightText(
                    color: ColorConstants.holdorangeColor,
                    fontSize: 14,
                  ),
                ),
              )
            : !isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
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
                      onPressed: onPlayPause,
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
                              onSeek(Duration(seconds: value.toInt())),
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
                                FullScreenVideos(controller: controller),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Container _registrationCardSection(
    BasicInspectionReportController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ColorConstants.dashboardboxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Registration Card",
              style: ApptextstyleConstants.mediumText(
                fontSize: 14,
                color: ColorConstants.blackColor,
              ),
            ),
            Row(
              children: [
                IgnorePointer(
                  ignoring: true,
                  child: Radio<String>(
                    value: controller.documentTypeText,
                    groupValue: controller.documentTypeText,
                    onChanged: (_) {},
                    activeColor: ColorConstants.syanColor,
                  ),
                ),

                Text(
                  controller.documentTypeText,
                  style: ApptextstyleConstants.lightText(
                    fontSize: 14,
                    color: ColorConstants.blackColor,
                  ),
                ),
              ],
            ),
            Text(
              "Vehicle Essentials",
              style: ApptextstyleConstants.mediumText(
                fontSize: 14,
                color: ColorConstants.blackColor,
              ),
            ),
            SizedBox(height: 5),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.selectedEssentialIds.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 6,
              ),
              itemBuilder: (context, index) {
                final essentialName = controller.getEssentialNameById(
                  controller.selectedEssentialIds[index],
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.check,
                          size: 18,
                          color: ColorConstants.syanColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          essentialName,
                          style: ApptextstyleConstants.thinText(
                            color: ColorConstants.blackColor,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Text(
              "Contents and Additional Notes ",
              style: ApptextstyleConstants.mediumText(
                color: ColorConstants.blackColor,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: ColorConstants.greyColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                child: Text(
                  controller.note?.trim().isNotEmpty == true
                      ? controller.note!
                      : "No notes available",
                  style: ApptextstyleConstants.lightText(
                    fontSize: 14,
                    color: ColorConstants.blackColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex:
                      controller.essentialImageUrl != null &&
                          controller.essentialImageUrl!.isNotEmpty
                      ? 5
                      : 1,
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorConstants.greyColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fuel Mark",
                          style: ApptextstyleConstants.lightText(
                            fontSize: 14,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: controller.fuelMarks.asMap().entries.map((
                            entry,
                          ) {
                            int index = entry.key;
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: index <= controller.fuelValue.round()
                                    ? ColorConstants.greenColor
                                    : ColorConstants.activecolor,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: controller.fuelMarks.asMap().entries.map((
                            entry,
                          ) {
                            int index = entry.key;
                            String label = entry.value;
                            return Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: index <= controller.fuelValue.round()
                                    ? ColorConstants.greenColor
                                    : ColorConstants.activecolor,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (controller.essentialImageUrl != null &&
                    controller.essentialImageUrl!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: ColorConstants.borderGreyColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: ColorConstants.dashboardboxShadow,
                      ),
                      child: InkWell(
                        onTap: () {
                          context.push(
                            '/fullScreenImage',
                            extra: {
                              'imageUrl': controller.essentialImageUrl!,
                              'label': "Essential Image",
                            },
                          );
                        },
                        child: Stack(
                          children: [
                            FutureBuilder<ImageInfo>(
                              future: _getNetworkImageSize(
                                controller.essentialImageUrl!,
                              ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final isLandscape =
                                    snapshot.data!.image.width >
                                    snapshot.data!.image.height;

                                return Container(
                                  height: double.infinity,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: ColorConstants.whiteColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: Transform.rotate(
                                        angle: isLandscape ? 1.5708 : 0,
                                        child: Image.network(
                                          controller.essentialImageUrl!,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Essential Image",
                                  style: ApptextstyleConstants.thinText(
                                    fontSize: 8,
                                    color: ColorConstants.whiteColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget _inspectionShimmer() {
    return Shimmer(
      duration: const Duration(seconds: 15),
      interval: const Duration(seconds: 500),
      color: Colors.white,
      colorOpacity: 0.3,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        height: 150,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade300,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 150, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Container(height: 12, width: double.infinity, color: Colors.grey),
            const SizedBox(height: 6),
            Container(height: 12, width: 200, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

Future<ImageInfo> _getNetworkImageSize(String url) async {
  final completer = Completer<ImageInfo>();
  final image = NetworkImage(url);

  final stream = image.resolve(const ImageConfiguration());

  late ImageStreamListener listener;

  listener = ImageStreamListener((ImageInfo info, bool _) {
    if (!completer.isCompleted) {
      completer.complete(info);
    }
    stream.removeListener(listener); // ✅ prevent memory leak
  });

  stream.addListener(listener);

  return completer.future;
}
