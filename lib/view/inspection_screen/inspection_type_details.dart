import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionCard_controller.dart';
import 'package:inspection/controller/inspectionFormController.dart';
import 'package:inspection/controller/inspectionTypeDetails_controller.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_card.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class InspectionTypeDetailspage extends StatefulWidget {
  final int inspectionFormId;
  final int jobId;
  final int? inspectionTypeId;
  const InspectionTypeDetailspage({
    super.key,
    required this.inspectionFormId,
    required this.jobId,
    this.inspectionTypeId,
  });

  @override
  State<InspectionTypeDetailspage> createState() =>
      _InspectionTypeDetailspageState();
}

class _InspectionTypeDetailspageState extends State<InspectionTypeDetailspage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final detailsController = Provider.of<InspectionTypeDetailsController>(
        context,
        listen: false,
      );
      final formController = Provider.of<InspectionFormController>(
        context,
        listen: false,
      );
      final ApiResponse inspectionResponse = await detailsController
          .getInspectionDetailsById(widget.jobId);
      await detailsController.postInspectionTypeDetails(
        widget.inspectionFormId,
      );
      await detailsController.getComponentList();
      if (inspectionResponse.success == true &&
          inspectionResponse.data != null) {
        detailsController.applySavedInspection(
          inspectionResponse.data as Map<String, dynamic>,
          formController,
        );
        detailsController.applySavedCustomInspection(
          inspectionResponse.data,
          formController,
        );
      }
      final totalTasks = detailsController.groupedTasks.values
          .expand((e) => e)
          .length;
      formController.setTotalTasks(totalTasks);
    });
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Discard changes?"),
              content: const Text("Are you sure you want to go back?"),
              actions: [
                TextButton(
                  onPressed: () {
                    context.go("/jobcarddetails", extra: widget.jobId);
                  },
                  child: const Text("NO"),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.go("/jobcarddetails", extra: widget.jobId);
                  },
                  child: const Text("YES"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation();
        if (!shouldExit) return;
        final formController = context.read<InspectionFormController>();
        if (formController.savedTasks == 0) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go("/jobcarddetails", extra: widget.jobId);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Inspection Details',
          onBackPress: () async {
            final shouldExit = await _showExitConfirmation();
            if (!shouldExit) return;
            final formController = context.read<InspectionFormController>();
            if (formController.savedTasks == 0) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go("/jobcarddetails", extra: widget.jobId);
              }
            }
          },
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Consumer<InspectionTypeDetailsController>(
            builder: (context, controller, _) {
              if (controller.isLoading) {
                return ListView(
                  children: List.generate(4, (_) => _inspectionShimmer()),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  VehicleSummaryWidget(jobId: widget.jobId),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      controller.inspectionFormName.toUpperCase(),
                      style: ApptextstyleConstants.mediumText(
                        color: ColorConstants.textBlueColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (widget.inspectionTypeId == 2) ...[
                    Consumer<InspectionFormController>(
                      builder: (context, formController, _) {
                        final completedTasks = controller.allTaskComponents
                            .where((task) {
                              final taskId = task["itcId"];
                              return taskId != null &&
                                  formController.isTaskSaved(taskId);
                            })
                            .toList();
                        return Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (completedTasks.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ExpansionTile(
                                      initiallyExpanded: false,
                                      iconColor: Colors.green,
                                      collapsedIconColor: Colors.green,
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Completed Inspections",
                                              style:
                                                  ApptextstyleConstants.lightText(
                                                    color: ColorConstants
                                                        .greenColor,
                                                    fontSize: 16,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.green,
                                              ),
                                            ),
                                            child: Text(
                                              completedTasks.length.toString(),
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: completedTasks.map((
                                        components,
                                      ) {
                                        return ChangeNotifierProvider(
                                          key: ValueKey(components["itcId"]),
                                          create: (_) =>
                                              InspectioncardController(),
                                          child: InspectionCard(
                                            jobid: widget.jobId,
                                            taskid: components["itcId"],
                                            formid: widget.inspectionFormId,
                                            title: components["itcName"] ?? "",

                                            inspectionTaskGoodFlag:
                                                components["allowGood"] ??
                                                false,
                                            inspectionTaskRepairFlag:
                                                components["allowRepair"] ??
                                                false,
                                            inspectionTaskReplaceFlag:
                                                components["allowReplace"] ??
                                                false,
                                            inspectionTaskPoorFlag:
                                                components["allowPoor"] ??
                                                false,
                                            inspectionTaskNotApplicable:
                                                components["allowNotApplicable"] ??
                                                false,
                                            inspectionTaskPhotoFlag:
                                                components["allowPhoto"] ??
                                                false,
                                            inspectionTaskAudioFlag:
                                                components["allowAudio"] ??
                                                false,
                                            inspectionTaskInstruction:
                                                components["instructionText"] ??
                                                "",
                                            inspectionPhotoMandatory:
                                                components["photoMandatory"] ??
                                                false,
                                            inspectionAudioMandatory:
                                                components["audioMandatory"] ??
                                                false,
                                            allowMultipleImage:
                                                components["allowMultipleImage"] ==
                                                true,
                                            allowVideo:
                                                components["allowVideo"] ==
                                                true,
                                            inspectionTypeid:
                                                widget.inspectionTypeId,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                CustomButtonTwo(
                                  text: "+ CUSTOM INSPECTIONS",
                                  onPressed: () {
                                    _showGeneralInspectionBottomSheet(
                                      context,
                                      controller,
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                CustomButtonWidget(
                                  text: "SAVE",
                                  onPressed: () async {
                                    final success = await controller
                                        .changeStatus(jobId: widget.jobId);
                                    if (!context.mounted) return;
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor:
                                              ColorConstants.greenColor,
                                          content: Text(
                                            "Custom inspection complete",
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                255,
                                                201,
                                                170,
                                                170,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                      context.go(
                                        "/inspectionsummarypage",
                                        extra: {
                                          "jobId": widget.jobId,
                                          "flag": 0,
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor:
                                              ColorConstants.errorcolor,
                                          content: Text(
                                            "Failed to Custom inspection",
                                            style: TextStyle(
                                              color: ColorConstants.whiteColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  textSize: 16,
                                ),
                                SizedBox(height: 40),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  SizedBox(height: 10),
                  if (widget.inspectionTypeId != 2) ...[
                    Consumer<InspectionFormController>(
                      builder: (context, formController, _) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: ColorConstants.activecolor,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${formController.savedTasks} / ${formController.totalTasks} completed",
                                style: ApptextstyleConstants.lightText(
                                  color: ColorConstants.blackColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: formController.progress,
                                ),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                builder: (context, value, _) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      ColorConstants.syanColor,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  SizedBox(height: 12),
                  if (widget.inspectionTypeId != 2) ...[
                    Expanded(
                      child: Consumer<InspectionFormController>(
                        builder: (context, formController, _) {
                          final validEntries = controller.groupedTasks.entries
                              .where((e) => e.value.isNotEmpty)
                              .toList();
                          if (validEntries.isEmpty) {
                            return const Center(
                              child: Text("No inspection tasks available"),
                            );
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 20,
                            ),
                            child: ListView.separated(
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemCount: validEntries.length,
                              itemBuilder: (context, index) {
                                final entry = validEntries[index];
                                final categoryId = entry.key;
                                final rawTasks = entry.value;
                                final pendingTasks = rawTasks.where((task) {
                                  final taskId = task["components"]?["itcId"];
                                  return taskId != null &&
                                      !formController.isTaskSaved(taskId);
                                }).toList();
                                final completedTasks = rawTasks.where((task) {
                                  final taskId = task["components"]?["itcId"];
                                  return taskId != null &&
                                      formController.isTaskSaved(taskId);
                                }).toList();
                                final categoryName =
                                    rawTasks.first["categoryName"] ??
                                    "Category $categoryId";
                                return Column(
                                  children: [
                                    if (completedTasks.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.green,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: ExpansionTile(
                                            initiallyExpanded: false,
                                            iconColor: Colors.green,
                                            collapsedIconColor: Colors.green,
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    categoryName,
                                                    style:
                                                        ApptextstyleConstants.lightText(
                                                          color: Colors.black,
                                                          fontSize: 14,
                                                        ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Completed",
                                                    style:
                                                        ApptextstyleConstants.lightText(
                                                          color: Colors.green,
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            children: completedTasks.map((
                                              task,
                                            ) {
                                              final components =
                                                  task["components"];
                                              return ChangeNotifierProvider(
                                                key: ValueKey(
                                                  components["itcId"],
                                                ),
                                                create: (_) =>
                                                    InspectioncardController(),
                                                child: InspectionCard(
                                                  categoryId: categoryId,
                                                  jobid: widget.jobId,
                                                  taskid: components["itcId"],
                                                  formid:
                                                      widget.inspectionFormId,
                                                  title: components["itcName"],
                                                  inspectionTaskGoodFlag:
                                                      components["allowGood"] ??
                                                      false,
                                                  inspectionTaskRepairFlag:
                                                      components["allowRepair"] ??
                                                      false,
                                                  inspectionTaskReplaceFlag:
                                                      components["allowReplace"] ??
                                                      false,
                                                  inspectionTaskPoorFlag:
                                                      components["allowPoor"] ??
                                                      false,
                                                  inspectionTaskNotApplicable:
                                                      components["allowNotApplicable"] ??
                                                      false,
                                                  inspectionTaskPhotoFlag:
                                                      components["allowPhoto"] ??
                                                      false,
                                                  inspectionTaskAudioFlag:
                                                      components["allowAudio"] ??
                                                      false,
                                                  inspectionTaskInstruction:
                                                      components["instructionText"],
                                                  inspectionPhotoMandatory:
                                                      components["photoMandatory"] ??
                                                      false,
                                                  inspectionAudioMandatory:
                                                      components["audioMandatory"] ??
                                                      false,
                                                  allowMultipleImage:
                                                      components["allowMultipleImage"] ==
                                                      true,
                                                  allowVideo:
                                                      components["allowVideo"] ==
                                                      true,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    if (pendingTasks.isNotEmpty)
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: ColorConstants.activecolor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: ExpansionTile(
                                            initiallyExpanded: true,
                                            iconColor:
                                                ColorConstants.blackColor,
                                            collapsedIconColor: Colors.black54,
                                            title: Text(
                                              categoryName,
                                              style:
                                                  ApptextstyleConstants.lightText(
                                                    color: ColorConstants
                                                        .blackColor,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            children: pendingTasks.map((task) {
                                              final components =
                                                  task["components"];
                                              return ChangeNotifierProvider(
                                                key: ValueKey(
                                                  components["itcId"],
                                                ),
                                                create: (_) =>
                                                    InspectioncardController(),
                                                child: InspectionCard(
                                                  categoryId: categoryId,
                                                  jobid: widget.jobId,
                                                  taskid: components["itcId"],
                                                  formid:
                                                      widget.inspectionFormId,
                                                  title: components["itcName"],
                                                  inspectionTaskGoodFlag:
                                                      components["allowGood"] ??
                                                      false,
                                                  inspectionTaskRepairFlag:
                                                      components["allowRepair"] ??
                                                      false,
                                                  inspectionTaskReplaceFlag:
                                                      components["allowReplace"] ??
                                                      false,
                                                  inspectionTaskPoorFlag:
                                                      components["allowPoor"] ??
                                                      false,
                                                  inspectionTaskNotApplicable:
                                                      components["allowNotApplicable"] ??
                                                      false,
                                                  inspectionTaskPhotoFlag:
                                                      components["allowPhoto"] ??
                                                      false,
                                                  inspectionTaskAudioFlag:
                                                      components["allowAudio"] ??
                                                      false,
                                                  inspectionTaskInstruction:
                                                      components["instructionText"],
                                                  inspectionPhotoMandatory:
                                                      components["photoMandatory"] ??
                                                      false,
                                                  inspectionAudioMandatory:
                                                      components["audioMandatory"] ??
                                                      false,
                                                  allowMultipleImage:
                                                      components["allowMultipleImage"] ==
                                                      true,
                                                  allowVideo:
                                                      components["allowVideo"] ==
                                                      true,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showGeneralInspectionBottomSheet(
    BuildContext context,
    InspectionTypeDetailsController controller,
  ) {
    final inspectionFormController = Provider.of<InspectionFormController>(
      context,
      listen: false,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      requestFocus: false,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ChangeNotifierProvider.value(
            value: inspectionFormController,
            child: Consumer<InspectionFormController>(
              builder: (context, formController, _) {
                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.8,
                  maxChildSize: 0.95,
                  minChildSize: 0.5,
                  builder: (context, scrollController) {
                    final completedTasks = controller.filteredTaskComponents
                        .where((task) {
                          final taskId = task["itcId"];
                          return taskId != null &&
                              formController.isTaskSaved(taskId);
                        })
                        .toList();
                    final pendingTasks = controller.filteredTaskComponents
                        .where((task) {
                          final taskId = task["itcId"];
                          return taskId != null &&
                              !formController.isTaskSaved(taskId);
                        })
                        .toList();
                    return ListView(
                      controller: scrollController,
                      primary: false,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(12),
                      children: [
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 40,
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              controller.searchTaskComponents(value);
                            },
                            decoration: InputDecoration(
                              hintText: "Search Inspection",
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (controller.filteredTaskComponents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text("No inspections found")),
                          ),
                        if (completedTasks.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              iconColor: Colors.green,
                              collapsedIconColor: Colors.green,
                              title: Row(
                                children: [
                                  const Expanded(
                                    child: Text("Completed Inspections"),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Text(
                                      completedTasks.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              children: completedTasks.map((components) {
                                return ChangeNotifierProvider(
                                  key: ValueKey(components["itcId"]),
                                  create: (_) => InspectioncardController(),
                                  child: InspectionCard(
                                    jobid: widget.jobId,
                                    taskid: components["itcId"],
                                    formid: widget.inspectionFormId,
                                    title: components["itcName"] ?? "",
                                    inspectionTaskGoodFlag:
                                        components["allowGood"] ?? false,
                                    inspectionTaskRepairFlag:
                                        components["allowRepair"] ?? false,
                                    inspectionTaskReplaceFlag:
                                        components["allowReplace"] ?? false,
                                    inspectionTaskPoorFlag:
                                        components["allowPoor"] ?? false,
                                    inspectionTaskNotApplicable:
                                        components["allowNotApplicable"] ??
                                        false,
                                    inspectionTaskPhotoFlag:
                                        components["allowPhoto"] ?? false,
                                    inspectionTaskAudioFlag:
                                        components["allowAudio"] ?? false,
                                    inspectionTaskInstruction:
                                        components["instructionText"] ?? "",
                                    inspectionPhotoMandatory:
                                        components["photoMandatory"] ?? false,
                                    inspectionAudioMandatory:
                                        components["audioMandatory"] ?? false,
                                    allowMultipleImage:
                                        components["allowMultipleImage"] ==
                                        true,
                                    allowVideo:
                                        components["allowVideo"] == true,
                                    inspectionTypeid: widget.inspectionTypeId,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        if (pendingTasks.isNotEmpty)
                          ...pendingTasks.map((components) {
                            return ChangeNotifierProvider(
                              key: ValueKey(components["itcId"]),
                              create: (_) => InspectioncardController(),
                              child: InspectionCard(
                                jobid: widget.jobId,
                                taskid: components["itcId"],
                                formid: widget.inspectionFormId,
                                title: components["itcName"] ?? "",
                                inspectionTaskGoodFlag:
                                    components["allowGood"] ?? false,
                                inspectionTaskRepairFlag:
                                    components["allowRepair"] ?? false,
                                inspectionTaskReplaceFlag:
                                    components["allowReplace"] ?? false,
                                inspectionTaskPoorFlag:
                                    components["allowPoor"] ?? false,
                                inspectionTaskNotApplicable:
                                    components["allowNotApplicable"] ?? false,
                                inspectionTaskPhotoFlag:
                                    components["allowPhoto"] ?? false,
                                inspectionTaskAudioFlag:
                                    components["allowAudio"] ?? false,
                                inspectionTaskInstruction:
                                    components["instructionText"] ?? "",
                                inspectionPhotoMandatory:
                                    components["photoMandatory"] ?? false,
                                inspectionAudioMandatory:
                                    components["audioMandatory"] ?? false,
                                allowMultipleImage:
                                    components["allowMultipleImage"] == true,
                                allowVideo: components["allowVideo"] == true,
                                inspectionTypeid: widget.inspectionTypeId,
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
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
