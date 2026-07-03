import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionCard_controller.dart';
import 'package:inspection/controller/inspectionFormController.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/inspection_screen/widgets/fullscreen_image_screen.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_fullscreenvideo.dart';
import 'package:provider/provider.dart';

class InspectionCard extends StatefulWidget {
  final int? categoryId;
  final int jobid;
  final int taskid;
  final int formid;
  final String title;
  final bool inspectionTaskGoodFlag;
  final bool inspectionTaskRepairFlag;
  final bool inspectionTaskReplaceFlag;
  final bool inspectionTaskPoorFlag;
  final bool inspectionTaskPhotoFlag;
  final bool inspectionTaskAudioFlag;
  final bool inspectionTaskNotApplicable;
  final bool inspectionPhotoMandatory;
  final bool inspectionAudioMandatory;
  final String? inspectionTaskInstruction;
  final bool allowMultipleImage;
  final bool allowVideo;
  // To Check it Is Custom Or Not
  final int? inspectionTypeid;
  final String? assemblyCodeName;
  final String? assemblyCodeDesc;
  final String? repairGroupName;
  final String? repairGroupDesc;
  final bool isReInspection;
  final bool isInBottomSheet;

  const InspectionCard({
    super.key,
    this.categoryId,
    required this.jobid,
    required this.taskid,
    required this.formid,
    required this.title,
    required this.inspectionTaskGoodFlag,
    required this.inspectionTaskRepairFlag,
    required this.inspectionTaskReplaceFlag,
    required this.inspectionTaskPoorFlag,
    required this.inspectionTaskPhotoFlag,
    required this.inspectionTaskAudioFlag,
    required this.inspectionPhotoMandatory,
    required this.inspectionAudioMandatory,
    this.inspectionTaskInstruction,
    required this.inspectionTaskNotApplicable,
    required this.allowMultipleImage,
    required this.allowVideo,
    // To Check it Is Custom Or Not
    this.inspectionTypeid,
    this.assemblyCodeName,
    this.assemblyCodeDesc,
    this.repairGroupName,
    this.repairGroupDesc,
    this.isReInspection = false,
    this.isInBottomSheet = false,
  });

  @override
  State<InspectionCard> createState() => _InspectionCardState();
}

class _InspectionCardState extends State<InspectionCard> {
  final FocusNode noteFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  @override
  void dispose() {
    noteFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formController = context.read<InspectionFormController>();
      final cardController = context.read<InspectioncardController>();
      cardController.initSpeech();
      cardController.loadExistingTask(
        formController: formController,
        taskId: widget.taskid,
        isReInspection: widget.isReInspection,
      );
      formController.setActiveCard(widget.taskid, cardController);
    });
  }

  @override
  Widget build(BuildContext context) {
    // final assemblyCode =
    //     ((widget.assemblyCodeName?.trim().isNotEmpty ?? false) &&
    //         (widget.assemblyCodeDesc?.trim().isNotEmpty ?? false))
    //     ? "${widget.assemblyCodeName}-${widget.assemblyCodeDesc}"
    //     : "####";

    // final groupName =
    //     ((widget.repairGroupName?.trim().isNotEmpty ?? false) &&
    //         (widget.repairGroupDesc?.trim().isNotEmpty ?? false))
    //     ? "${widget.repairGroupName}-${widget.repairGroupDesc}"
    //     : "####";

    double fieldHeight = MediaQuery.of(context).size.width > 600 ? 45 : 40;
    return Consumer<InspectioncardController>(
      builder: (context, cardController, child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          color: ColorConstants.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: ApptextstyleConstants.lightText(
                    color: ColorConstants.blackColor,
                    fontSize: 14,
                  ),
                ),
                // SizedBox(height: 5),
                // Row(
                //   children: [
                //     Container(
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 5,
                //         vertical: 2,
                //       ),
                //       decoration: BoxDecoration(
                //         color: ColorConstants.holdorangeColor.withOpacity(0.12),
                //         borderRadius: BorderRadius.circular(20),
                //         border: Border.all(
                //           color: ColorConstants.holdorangeColor,
                //         ),
                //       ),
                //       child: Text(
                //         "Assembly Code : $assemblyCode",
                //         style: const TextStyle(
                //           color: ColorConstants.holdorangeColor,
                //           fontSize: 10,
                //         ),
                //       ),
                //     ),
                //     SizedBox(width: 5),
                //     Container(
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 5,
                //         vertical: 2,
                //       ),
                //       decoration: BoxDecoration(
                //         color: Colors.deepPurple.withOpacity(0.12),
                //         borderRadius: BorderRadius.circular(20),
                //         border: Border.all(color: Colors.deepPurple),
                //       ),
                //       child: Text(
                //         "Group Name : $groupName",
                //         style: const TextStyle(
                //           color: Colors.deepPurple,
                //           fontSize: 10,
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (widget.inspectionTaskGoodFlag) _buildRadio("Good"),
                    if (widget.inspectionTaskRepairFlag) _buildRadio("Repair"),
                    if (widget.inspectionTaskPoorFlag) _buildRadio("Poor"),
                    if (widget.inspectionTaskReplaceFlag)
                      _buildRadio("Replace"),
                    if (widget.inspectionTaskNotApplicable) _buildRadio("N/A"),
                  ],
                ),
                SizedBox(height: 5),
                if (!cardController.isNotApplicable) ...[
                  Builder(
                    builder: (context) {
                      final bool canShowImages =
                          widget.inspectionTaskPhotoFlag ||
                          widget.allowMultipleImage;
                      final bool hasVideo = widget.allowVideo;
                      final int imageCount = canShowImages
                          ? (widget.allowMultipleImage ? (hasVideo ? 3 : 3) : 1)
                          : 0;
                      if (imageCount == 0 && !hasVideo) {
                        return _noteField(cardController);
                      }
                      if (imageCount == 1 && !hasVideo) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _imageBox(cardController, 0, context),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 70,
                                child: _noteField(cardController),
                              ),
                            ),
                          ],
                        );
                      }
                      if (imageCount == 0 && hasVideo) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _videoBox(cardController, context),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 70,
                                child: _noteField(cardController),
                              ),
                            ),
                          ],
                        );
                      }
                      if (imageCount == 1 && hasVideo) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _imageBox(cardController, 0, context),
                                const SizedBox(width: 12),
                                _videoBox(cardController, context),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _noteField(cardController),
                          ],
                        );
                      }
                      if (imageCount == 2) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _imageBox(cardController, 0, context),
                                const SizedBox(width: 10),
                                _imageBox(cardController, 1, context),
                                if (hasVideo) ...[
                                  const SizedBox(width: 10),
                                  _videoBox(cardController, context),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            _noteField(cardController),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ...List.generate(imageCount, (i) {
                                return _imageBox(cardController, i, context);
                              }),
                              if (hasVideo) _videoBox(cardController, context),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _noteField(cardController),
                        ],
                      );
                    },
                  ),
                ],
                SizedBox(height: 10),
                if (widget.inspectionTaskAudioFlag &&
                    !cardController.isNotApplicable)
                  _audioSection(
                    cardController.recordedFilePath,
                    cardController.isRecording,
                    cardController.toggleRecording,
                    cardController.playRecording,
                    cardController.deleteRecording,
                  ),
                SizedBox(height: 8),
                cardController.showSaveButton
                    ? Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: SizedBox(
                              height: fieldHeight,
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  TextField(
                                    focusNode: descriptionFocusNode,
                                    controller:
                                        cardController.descriptionController,
                                    canRequestFocus: true,

                                    readOnly: cardController.isSuccess,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    maxLines: 18,
                                    decoration: InputDecoration(
                                      labelText: "Initial Note",
                                      isDense: true,
                                      contentPadding: const EdgeInsets.only(
                                        left: 12,
                                        right: 60,
                                        top: 10,
                                        bottom: 12,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: ColorConstants.lightblackColor,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: ColorConstants.lightblackColor,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (_) async {
                                      final formController = context
                                          .read<InspectionFormController>();
                                      final allowed = await formController
                                          .checkUnsavedBeforeEditing(
                                            context,
                                            widget.taskid,
                                            cardController,
                                          );
                                      if (!allowed) {
                                        cardController
                                            .descriptionController
                                            .text = cardController
                                            .descriptionController
                                            .text;
                                        return;
                                      }
                                      cardController.markChanged();
                                    },
                                  ),
                                  Positioned(
                                    right: 8,
                                    child:
                                        cardController.isListening &&
                                            cardController.activeSpeechField ==
                                                SpeechField.description
                                        ? _buildSmallWaveMic()
                                        : IconButton(
                                            icon: Icon(
                                              Icons.mic_none,
                                              size: 16,
                                              weight: 2,
                                              color: ColorConstants.greenColor,
                                            ),
                                            onPressed: () async {
                                              final formController = context
                                                  .read<
                                                    InspectionFormController
                                                  >();
                                              final allowed =
                                                  await formController
                                                      .checkUnsavedBeforeEditing(
                                                        context,
                                                        widget.taskid,
                                                        cardController,
                                                      );
                                              if (!allowed) return;
                                              cardController.startListening(
                                                SpeechField.description,
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: fieldHeight,
                              child: CustomButtonWidget(
                                text:
                                    cardController.isLoading ||
                                        cardController.isVideoLoading ||
                                        cardController.isAudioDownloading
                                    ? "Please Wait..."
                                    : cardController.isSuccess
                                    ? (widget.isReInspection ? "SAVED" : "UPLOADED")
                                    : "SAVE",
                                textSize: 12,
                                isDisabled:
                                    cardController.isLoading ||
                                    cardController.isSuccess ||
                                    cardController.isVideoLoading ||
                                    cardController.isAudioDownloading,
                                showLoader:
                                    cardController.isLoading ||
                                    cardController.isVideoLoading ||
                                    cardController.isAudioDownloading,
                                onPressed: () async {
                                  if (widget.formid == 0 || widget.categoryId == null || widget.categoryId == 0) {
                                    final formController = context
                                        .read<InspectionFormController>();
                                    final isCompleted = await cardController
                                        .onCustomSavePressed(
                                          context: context,
                                          formController: formController,
                                          inspectionPhotoMandatory:
                                              widget.inspectionPhotoMandatory,
                                          inspectionAudioMandatory:
                                              widget.inspectionAudioMandatory,
                                          jobId: widget.jobid,
                                          taskId: widget.taskid,
                                          formId: widget.formid,
                                          inspectionTypeId:
                                              widget.inspectionTypeid ?? (widget.isReInspection ? 2 : 1),
                                          isReInspection: widget.isReInspection,
                                        );
                                    if (isCompleted) {
                                      context.go(
                                        "/inspectionsummarypage",
                                        extra: {
                                          "jobId": widget.jobid,
                                          "flag": 0,
                                        },
                                      );
                                    }
                                  } else {
                                    final formController = context
                                        .read<InspectionFormController>();
                                    final isCompleted = await cardController
                                        .onSavePressed(
                                          context: context,
                                          formController: formController,
                                          inspectionPhotoMandatory:
                                              widget.inspectionPhotoMandatory,
                                          inspectionAudioMandatory:
                                              widget.inspectionAudioMandatory,
                                          jobId: widget.jobid,
                                          taskId: widget.taskid,
                                          formId: widget.formid,
                                          categoryId: widget.categoryId ?? 0,
                                          inspectionTypeId: widget.inspectionTypeid,
                                          isReInspection: widget.isReInspection,
                                        );
                                    if (isCompleted) {
                                      context.go(
                                        "/inspectionsummarypage",
                                        extra: {
                                          "jobId": widget.jobid,
                                          "flag": 0,
                                        },
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        height: fieldHeight,
                        width: double.infinity,
                        child: TextField(
                          focusNode: descriptionFocusNode,
                          controller: cardController.descriptionController,
                          canRequestFocus: true,
                          readOnly: true,
                          maxLines: 18,
                          decoration: InputDecoration(
                            labelText: "Initial Note",
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: ColorConstants.lightblackColor,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                if (widget.allowMultipleImage &&
                    widget.inspectionPhotoMandatory)
                  Builder(
                    builder: (context) {
                      final hasImage = cardController.capturedImages.any(
                        (img) => img != null,
                      );
                      final hasNote = cardController.noteController.text
                          .trim()
                          .isNotEmpty;
                      if (hasImage && hasNote) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 6),
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
                                  "Capture at least one image & add note",
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
                if (widget.inspectionTaskInstruction != null &&
                    widget.inspectionTaskInstruction!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.yellowAccent.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.inspectionTaskInstruction!,
                              style: ApptextstyleConstants.thinText(
                                fontSize: 12,
                                color: ColorConstants.blackColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageBox(
    InspectioncardController controller,
    int index,
    BuildContext context,
  ) {
    final image = controller.imageAt(index);
    final int currentAngle = controller.getAngleAt(index);
    return GestureDetector(
      onTap: () async {
        final formController = context.read<InspectionFormController>();
        final allowed = await formController.checkUnsavedBeforeEditing(
          context,
          widget.taskid,
          controller,
        );
        if (!allowed) return;
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        if (image == null || !controller.isSuccess) {
          await controller.handleImageTap(
            rootContext,
            imageIndex: index,
            mediaType: MediaType.image,
          );
          controller.markChanged();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FullScreenImageScreen(imageFile: image, angle: currentAngle),
            ),
          );
        }
      },
      child: _mediaBox(
        child: image != null
            ? Transform.rotate(
                // Converts integer degrees to radians for Flutter Transform
                angle: currentAngle * (3.1415926535897932 / 180),
                child: Image.file(
                  image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.camera_alt, color: Colors.grey),
      ),
    );
  }

  Widget _videoBox(InspectioncardController controller, BuildContext context) {
    return GestureDetector(
      onTap: controller.isVideoLoading
          ? null
          : () async {
              final rootContext = Navigator.of(
                context,
                rootNavigator: true,
              ).context;
              if (controller.capturedVideo == null) {
                final formController = context.read<InspectionFormController>();
                final allowed = await formController.checkUnsavedBeforeEditing(
                  context,
                  widget.taskid,
                  controller,
                );
                if (!allowed) return;
                await controller.handleImageTap(
                  rootContext,
                  imageIndex: 0,
                  mediaType: MediaType.video,
                );
                controller.markChanged();
              } else {
                if (!controller.isSuccess) {
                  final action = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Video Options"),
                      content: const Text("Would you like to play the video or recapture/delete it?"),
                      actions: [
                        TextButton(
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          onPressed: () => Navigator.pop(context, "delete"),
                        ),
                        TextButton(
                          child: const Text("Play"),
                          onPressed: () => Navigator.pop(context, "play"),
                        ),
                        TextButton(
                          child: const Text("Recapture"),
                          onPressed: () => Navigator.pop(context, "recapture"),
                        ),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context, "cancel"),
                        ),
                      ],
                    ),
                  );
                  if (action == "play") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InspectionFullScreenVideo(
                          videoUrl: controller.capturedVideo!.path,
                          label: "Video",
                        ),
                      ),
                    );
                  } else if (action == "recapture") {
                    final formController = context.read<InspectionFormController>();
                    final allowed = await formController.checkUnsavedBeforeEditing(
                      context,
                      widget.taskid,
                      controller,
                    );
                    if (!allowed) return;
                    await controller.deleteVideo();
                    await controller.handleImageTap(
                      rootContext,
                      imageIndex: 0,
                      mediaType: MediaType.video,
                    );
                    controller.markChanged();
                  } else if (action == "delete") {
                    await controller.deleteVideo();
                    controller.markChanged();
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspectionFullScreenVideo(
                        videoUrl: controller.capturedVideo!.path,
                        label: "Video",
                      ),
                    ),
                  );
                }
              }
            },
      child: _mediaBox(
        child: controller.isVideoLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : controller.capturedVideo != null
            ? const Icon(
                Icons.play_circle_fill,
                color: ColorConstants.syanColor,
                size: 32,
              )
            : const Icon(Icons.videocam, color: Colors.grey),
      ),
    );
  }

  Widget _mediaBox({required Widget child}) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
        border: Border.all(color: Colors.black12, width: 1.5),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }

  Widget _noteField(InspectioncardController controller) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            focusNode: noteFocusNode,
            controller: controller.noteController,
            canRequestFocus: true,
            readOnly: controller.isSuccess || controller.isNotApplicable,
            expands: true,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) async {
              final formController = context.read<InspectionFormController>();
              final allowed = await formController.checkUnsavedBeforeEditing(
                context,
                widget.taskid,
                controller,
              );
              if (!allowed) return;
              controller.markChanged();
            },
            decoration: InputDecoration(
              labelText: "Inspection Note",
              isDense: true,
              contentPadding: const EdgeInsets.only(
                left: 12,
                right: 60,
                top: 12,
                bottom: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
          Positioned(
            right: 8,
            child:
                controller.isListening &&
                    controller.activeSpeechField == SpeechField.note
                ? _buildWaveMic()
                : IconButton(
                    icon: Icon(
                      Icons.mic_none,
                      color: ColorConstants.greenColor,
                    ),
                    onPressed: () async {
                      final formController = context
                          .read<InspectionFormController>();
                      final allowed = await formController
                          .checkUnsavedBeforeEditing(
                            context,
                            widget.taskid,
                            controller,
                          );
                      if (!allowed) return;
                      controller.startListening(SpeechField.note);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallWaveMic() {
    final controller = context.watch<InspectioncardController>();
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 20,
            width: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 4, end: 12),
                  duration: Duration(milliseconds: 300 + (index * 120)),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 3,
                      height: controller.isListening ? value : 4,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(3),
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
          const SizedBox(width: 4),
          GestureDetector(
            onTap: controller.stopListening,
            child: const Icon(Icons.close, size: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveMic() {
    final controller = context.watch<InspectioncardController>();
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

  Widget _buildRadio(String value) {
    return Consumer<InspectioncardController>(
      builder: (context, radioButtonController, child) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: radioButtonController.selectedOption,
            onChanged: radioButtonController.isSuccess
                ? null
                : (val) async {
                    final formController = context
                        .read<InspectionFormController>();
                    final controller = context.read<InspectioncardController>();
                    final allowed = await formController
                        .checkUnsavedBeforeEditing(
                          context,
                          widget.taskid,
                          controller,
                        );
                    if (!allowed) return;
                    radioButtonController.setSelectedOption(val!);
                    radioButtonController.markChanged();
                  },
            activeColor: ColorConstants.bottamNavBarButton,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(value, style: ApptextstyleConstants.thinText(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _audioSection(
    String? recordedFilePath,
    bool isRecording,
    Future<void> Function() toggleRecording,
    Future<void> Function() playRecording,
    Future<void> Function() deleteRecording,
  ) {
    return Consumer<InspectioncardController>(
      builder: (context, audioController, child) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: audioController.validationType == ValidationType.audio
                ? Colors.red
                : ColorConstants.blackColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (audioController.isAudioDownloading) ...[
                SizedBox(
                  height: 45 - 8,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Loading audio...",
                        style: ApptextstyleConstants.thinText(
                          fontSize: 12,
                          color: ColorConstants.lightblackColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (recordedFilePath == null) ...[
                SizedBox(
                  height: 45 - 8,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: audioController.isSuccess
                        ? null
                        : () async {
                            final formController = context
                                .read<InspectionFormController>();
                            final allowed = await formController
                                .checkUnsavedBeforeEditing(
                                  context,
                                  widget.taskid,
                                  audioController,
                                );
                            if (!allowed) return;
                            await toggleRecording();
                            audioController.markChanged();
                          },
                    child: Row(
                      children: [
                        Icon(
                          isRecording ? Icons.stop_circle : Icons.mic,
                          size: 20,
                          color: isRecording
                              ? ColorConstants.errorcolor
                              : ColorConstants.greyColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRecording ? "Recording..." : "Tap mic to record",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 13,
                            color: isRecording
                                ? ColorConstants.errorcolor
                                : ColorConstants.lightblackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 45 - 8,
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
                          Text(
                            "Recorded Audio",
                            style: ApptextstyleConstants.thinText(
                              fontSize: 12,
                              color: ColorConstants.lightblackColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              audioController.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 20,
                              color: ColorConstants.greenColor,
                            ),
                            onPressed: () {
                              audioController.togglePlayPause(recordedFilePath);
                            },
                          ),
                        ],
                      ),
                      if (!audioController.isSuccess)
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 20,
                            color: ColorConstants.errorcolor,
                          ),
                          onPressed: deleteRecording,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> showUnsavedWarning(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Unsaved Changes"),
            content: const Text(
              "You have unsaved changes in this card. Continue without saving?",
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text("Continue"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }
}
