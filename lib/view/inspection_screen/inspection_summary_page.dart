import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionSummaryPage_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/customShimmerLoader.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:provider/provider.dart';

enum InspectionStatus { good, repair, poor, replace, na }

class InspectionItem {
  final String title;
  final InspectionStatus status;
  final String category;
  final int? taskId;

  final bool allowGood;
  final bool allowRepair;
  final bool allowPoor;
  final bool allowReplace;
  final bool allowNA;

  final List<String> imageUrls;
  final String? videoUrl;

  final String? audioUrl;
  final String note;
  final String initialNote;
  final bool viReInspection;

  InspectionItem({
    required this.title,
    required this.status,
    required this.category,
    this.taskId,
    required this.note,
    required this.initialNote,
    this.audioUrl,
    required this.allowGood,
    required this.allowRepair,
    required this.allowPoor,
    required this.allowReplace,
    required this.allowNA,
    required this.imageUrls,
    this.videoUrl,
    this.viReInspection = false,
  });
}

class InspectionSummaryPage extends StatefulWidget {
  final int jobId;
  final int flag; // 0 = home, 1 = job details
  const InspectionSummaryPage({
    super.key,
    required this.jobId,
    required this.flag,
  });

  @override
  State<InspectionSummaryPage> createState() => InspectionSummaryPageState();
}

class InspectionSummaryPageState extends State<InspectionSummaryPage> {
  final GlobalKey _shareKey = GlobalKey();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectionsummarypageController>().getInspectionSummary(
        widget.jobId,
      );
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InspectionsummarypageController>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (widget.flag == 1) {
          context.go("/jobcarddetails", extra: widget.jobId);
        } else {
          context.go("/home", extra: widget.jobId);
        }
      },
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor,
        appBar: CustomAppBar(
          title: widget.flag == 2 ? 'Re-Inspection Summary' : 'Inspection Summary',
          onBackPress: () {
            if (widget.flag == 1) {
              context.go("/jobcarddetails", extra: widget.jobId);
            } else {
              context.go("/home", extra: widget.jobId);
            }
          },
        ),
        body: controller.isLoading
            ? CustomShimmerLoader(isLoading: true)
            : RepaintBoundary(
                key: _shareKey,

                child: Container(
                  color: ColorConstants.whiteColor,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        VehicleSummaryWidget(jobId: widget.jobId),
                        SizedBox(height: 10),
                        Text(
                          controller.inspectionFormName,
                          style: const TextStyle(
                            color: ColorConstants.textBlueColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                             final allItems = controller.groupedItems.values.expand((list) => list).toList();
                             final reInspectionItems = allItems.where((item) => item.viReInspection).toList();
                             reInspectionItems.sort((a, b) {
                               int getWeight(InspectionStatus status) {
                                 if (status == InspectionStatus.replace) return 0;
                                 if (status == InspectionStatus.repair) return 1;
                                 if (status == InspectionStatus.poor) return 2;
                                 return 3;
                               }
                               return getWeight(a.status).compareTo(getWeight(b.status));
                             });
                             if (reInspectionItems.isEmpty) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                border: Border.all(color: Colors.amber.shade400),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "RE-INSPECTION ITEMS REQUESTED",
                                        style: ApptextstyleConstants.mediumText(
                                          color: Colors.amber.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(3),
                                      1: FlexColumnWidth(1.2),
                                    },
                                    border: TableBorder.all(color: Colors.amber.shade200, width: 1),
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(color: Colors.amber.shade100),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Text("Component", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                      ...reInspectionItems.map((item) {
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Text(
                                                item.category.isNotEmpty
                                                    ? "${item.title} (${item.category})"
                                                    : item.title,
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Text(
                                                item.status.name.toUpperCase(),
                                                style: TextStyle(
                                                  color: item.status == InspectionStatus.replace
                                                      ? Colors.red
                                                      : item.status == InspectionStatus.repair
                                                          ? Colors.orange
                                                          : Colors.grey,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (controller.technicianComment.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: Border.all(color: Colors.blue.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TECHNICIAN COMMENTS",
                                  style: ApptextstyleConstants.mediumText(
                                    color: Colors.blue.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  controller.technicianComment,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Builder(
                          builder: (context) {
                            final entries = controller.groupedItems.entries.map((entry) {
                              final filteredList = entry.value.where((item) {
                                if (widget.flag == 2) {
                                  return item.viReInspection;
                                }
                                return true;
                              }).toList();
                              return MapEntry(entry.key, filteredList);
                            }).where((entry) => entry.value.isNotEmpty).toList();

                            return Column(
                              children: entries
                                  .asMap()
                                  .entries
                                  .map((mapEntry) {
                                    final entry = mapEntry.value;

                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 5),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: ColorConstants.whiteColor,
                                          border: Border.all(
                                            color: ColorConstants.activecolor,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow:
                                              ColorConstants.dashboardboxShadow,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: ExpansionTile(
                                            initiallyExpanded: true,
                                            iconColor: ColorConstants.blackColor,
                                            collapsedIconColor: Colors.black54,
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,

                                              children: [
                                                Text(
                                                  entry.key,
                                                  style:
                                                      ApptextstyleConstants.regularText(
                                                        fontSize: 14,
                                                        color: ColorConstants
                                                            .blackColor,
                                                      ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: ColorConstants
                                                        .activecolor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    "${entry.value.length}",
                                                    style:
                                                        ApptextstyleConstants.thinText(
                                                          fontSize: 14,
                                                          color: ColorConstants
                                                              .activecolor,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            children: entry.value
                                                .map(
                                                  (item) =>
                                                      _buildInspectionItem(item),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            );
                          }
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: SizedBox(
                            width: double.infinity,
                            child: CustomButtonWidget(
                              text: "CLOSE",
                              textColor: ColorConstants.whiteColor,
                              textSize: 16,
                              onPressed: () {
                                if (widget.flag == 1) {
                                  context.go(
                                    "/jobcarddetails",
                                    extra: widget.jobId,
                                  );
                                } else {
                                  context.go("/home", extra: widget.jobId);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Color _borderColor(InspectionStatus status) {
    switch (status) {
      case InspectionStatus.good:
        return ColorConstants.greenColor;
      case InspectionStatus.repair:
        return ColorConstants.orangecolor;
      case InspectionStatus.poor:
        return ColorConstants.textBlueColor;
      case InspectionStatus.replace:
        return ColorConstants.errorcolor;
      case InspectionStatus.na:
        return ColorConstants.borderGreyColor;
    }
  }

  Widget _summaryRadio(
    String label,
    InspectionStatus status,
    InspectionItem item,
  ) {
    final bool isSelected = item.status == status;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          size: 16,
          color: isSelected ? _borderColor(status) : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(label, style: ApptextstyleConstants.thinText(fontSize: 12)),
      ],
    );
  }

  Future<void> _toggleAudio(String url) async {
    if (_currentlyPlayingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
    setState(() {
      _currentlyPlayingUrl = url;
      _isPlaying = true;
    });
  }

  Widget _buildInspectionItem(InspectionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _borderColor(item.status), width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                _borderColor(item.status).withOpacity(0.08),
                _borderColor(item.status).withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: ApptextstyleConstants.lightText(
                    color: ColorConstants.blackColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (item.allowGood)
                      _summaryRadio("Good", InspectionStatus.good, item),

                    if (item.allowRepair)
                      _summaryRadio("Repair", InspectionStatus.repair, item),

                    if (item.allowPoor)
                      _summaryRadio("Poor", InspectionStatus.poor, item),

                    if (item.allowReplace)
                      _summaryRadio("Replace", InspectionStatus.replace, item),

                    if (item.allowNA)
                      _summaryRadio("N/A", InspectionStatus.na, item),
                  ],
                ),

                SizedBox(height: 8),

                if (item.imageUrls.isNotEmpty || item.videoUrl != null) ...[
                  SizedBox(height: 8),
                  _buildMediaWithNote(item, context),
                ],

                SizedBox(height: 8),
                if (item.audioUrl != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorConstants.blackColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      height: 45,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.audio_file,
                                size: 20,
                                color: ColorConstants.greenColor,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Recorded Audio",
                                style: ApptextstyleConstants.thinText(
                                  fontSize: 12,
                                  color: ColorConstants.lightblackColor,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              (_currentlyPlayingUrl == item.audioUrl &&
                                      _isPlaying)
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 22,
                              color: ColorConstants.greenColor,
                            ),
                            onPressed: () => _toggleAudio(item.audioUrl!),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (item.initialNote.trim().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: ColorConstants.blackColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item.initialNote,
                        style: ApptextstyleConstants.thinText(
                          color: ColorConstants.blackColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaWithNote(InspectionItem item, BuildContext context) {
    final images = item.imageUrls.take(3).toList();
    final int imageCount = images.length;
    final bool hasVideo = item.videoUrl != null;
    Widget noteWidget() {
      if (item.note.trim().isEmpty) return const SizedBox.shrink();
      return Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: ColorConstants.blackColor),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            item.note,
            style: ApptextstyleConstants.thinText(fontSize: 14),
          ),
        ),
      );
    }
    if (imageCount == 1 && !hasVideo) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mediaImage(images[0], item.title, context),
          const SizedBox(width: 12),
          Expanded(child: noteWidget()),
        ],
      );
    }
    if (imageCount == 0 && hasVideo) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mediaVideo(item.videoUrl!, item.title, context),
          const SizedBox(width: 12),
          Expanded(child: noteWidget()),
        ],
      );
    }
    if (imageCount == 1 && hasVideo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _mediaImage(images[0], item.title, context),
              const SizedBox(width: 10),
              _mediaVideo(item.videoUrl!, item.title, context),
            ],
          ),
          const SizedBox(height: 10),
          noteWidget(),
        ],
      );
    }
    if (hasVideo && imageCount >= 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...images.map(
                (img) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _mediaImage(img, item.title, context),
                ),
              ),
              _mediaVideo(item.videoUrl!, item.title, context),
            ],
          ),
          const SizedBox(height: 10),
          noteWidget(),
        ],
      );
    }
    if (!hasVideo && imageCount >= 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: imageCount == 3
                ? MainAxisAlignment
                      .spaceAround // ✅ 3 images
                : MainAxisAlignment.start, // ✅ 2 images
            children: [
              for (int i = 0; i < imageCount; i++) ...[
                _mediaImage(images[i], item.title, context),
                if (imageCount == 2 && i == 0) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 10),
          noteWidget(),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _mediaImage(String url, String title, BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          '/fullScreenImage',
          extra: {'imageUrl': url, 'label': title},
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConstants.blackColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  Widget _mediaVideo(String url, String title, BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          '/inspectionFullScreenVideo',
          extra: {'videoUrl': url, 'label': title},
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConstants.blackColor),
        ),
        child: Icon(
          Icons.play_circle_fill,
          color: ColorConstants.syanColor,
          size: 32,
        ),
      ),
    );
  }
}
