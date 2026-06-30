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
  final TextEditingController _commentController = TextEditingController();
  final Set<int> _reInspectionTaskIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final detailsController = context.read<InspectionTypeDetailsController>();

      final formController = context.read<InspectionFormController>();

      detailsController.isLoading = true;
      // ignore: invalid_use_of_protected_member
      detailsController.notifyListeners();

      try {
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
            inspectionResponse.data as Map<String, dynamic>,
            formController,
          );

          final data = inspectionResponse.data as Map<String, dynamic>;
          final inspections = data["inspections"] ?? [];
          if (inspections.isNotEmpty) {
            final master = inspections[0]["master"];
            if (master != null && master["vimAdditionalComments"] != null) {
              _commentController.text = master["vimAdditionalComments"].toString();
            }
            final completedTasks = inspections[0]["completedTasks"] ?? [];
            for (final savedTask in completedTasks) {
              if (savedTask["viReInspection"] == true) {
                _reInspectionTaskIds.add(savedTask["viTaskId"]);
              }
            }
          }
        }

        final totalTasks = detailsController.groupedTasks.values
            .expand((e) => e)
            .length;

        formController.setTotalTasks(totalTasks);
      } finally {
        detailsController.isLoading = false;
        // ignore: invalid_use_of_protected_member
        detailsController.notifyListeners();
      }
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
                                            assemblyCodeName:
                                                components["assemblyCodeName"] ??
                                                "",
                                            assemblyCodeDesc:
                                                components["assemblyCodeDesc"] ??
                                                "",
                                            repairGroupName:
                                                components["repairGroupName"] ??
                                                "",
                                            repairGroupDesc:
                                                components["repairGroupDesc"] ??
                                                "",
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
                                //
                                CustomButtonWidget(
                                  text: "SAVE",
                                  isDisabled: completedTasks.isEmpty,
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
                                              color: Colors.white,
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
                              itemCount: validEntries.length + 1,
                              itemBuilder: (context, index) {
                                if (index == validEntries.length) {
                                  return _buildBottomSection(context, formController, controller);
                                }
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
                                              // log(
                                              //   "assemblyCodeName: ${components["assemblyCodeName"]}",
                                              // );
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
                                                  assemblyCodeName:
                                                      components["assemblyCodeName"]
                                                          ?.toString() ??
                                                      "",
                                                  assemblyCodeDesc:
                                                      components["assemblyCodeDesc"]
                                                          ?.toString() ??
                                                      "",
                                                  repairGroupName:
                                                      components["repairGroupName"]
                                                          ?.toString() ??
                                                      "",
                                                  repairGroupDesc:
                                                      components["repairGroupDesc"]
                                                          ?.toString() ??
                                                      "",
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
                                              // log(
                                              //   "assemblyCodeName: ${components["assemblyCodeName"]}",
                                              // );
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
                                                  assemblyCodeName:
                                                      components["assemblyCodeName"]
                                                          ?.toString() ??
                                                      "",
                                                  assemblyCodeDesc:
                                                      components["assemblyCodeDesc"]
                                                          ?.toString() ??
                                                      "",
                                                  repairGroupName:
                                                      components["repairGroupName"]
                                                          ?.toString() ??
                                                      "",
                                                  repairGroupDesc:
                                                      components["repairGroupDesc"]
                                                          ?.toString() ??
                                                      "",
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
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      requestFocus: false,

      isScrollControlled: true,
      enableDrag: false, // Prevent dragging down to close
      isDismissible: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: inspectionFormController),
              ChangeNotifierProvider.value(value: controller), // 👈 ADD THIS
            ],
            child:
                Consumer2<
                  InspectionFormController,
                  InspectionTypeDetailsController
                >(
                  builder: (context, formController, detailsController, _) {
                    return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.95,
                      maxChildSize: 0.95,
                      minChildSize: 0.95,
                      shouldCloseOnMinExtent: false,
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
                            // const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(parentContext);
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  detailsController.searchTaskComponents(value);
                                },
                                decoration: InputDecoration(
                                  hintText: "Search Inspection",
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: detailsController.isSearching
                                      ? const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : null,
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
                                child: Center(
                                  child: Text("No inspections found"),
                                ),
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.green,
                                          ),
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
                                            components["photoMandatory"] ??
                                            false,
                                        inspectionAudioMandatory:
                                            components["audioMandatory"] ??
                                            false,
                                        allowMultipleImage:
                                            components["allowMultipleImage"] ==
                                            true,
                                        allowVideo:
                                            components["allowVideo"] == true,
                                        assemblyCodeName:
                                            components["assemblyCodeName"] ??
                                            "",
                                        assemblyCodeDesc:
                                            components["assemblyCodeDesc"] ??
                                            "",
                                        repairGroupName:
                                            components["repairGroupName"] ?? "",
                                        repairGroupDesc:
                                            components["repairGroupDesc"] ?? "",
                                        inspectionTypeid:
                                            widget.inspectionTypeId,
                                        isInBottomSheet: true,
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
                                    assemblyCodeName:
                                        components["assemblyCodeName"] ?? "",
                                    assemblyCodeDesc:
                                        components["assemblyCodeDesc"] ?? "",
                                    repairGroupName:
                                        components["repairGroupName"] ?? "",
                                    repairGroupDesc:
                                        components["repairGroupDesc"] ?? "",
                                    inspectionTypeid: widget.inspectionTypeId,
                                    isInBottomSheet: true,
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

  Widget _buildBottomSection(
    BuildContext context,
    InspectionFormController formController,
    InspectionTypeDetailsController controller,
  ) {
    final reInspectionItems = formController.orderedTasks.where((task) {
      return formController.isTaskSaved(task.taskId) &&
          (task.condition == "Replace" || task.condition == "Repair" || task.condition == "Poor");
    }).toList();

    reInspectionItems.sort((a, b) {
      int getWeight(String? cond) {
        if (cond == "Replace") return 0;
        if (cond == "Repair") return 1;
        if (cond == "Poor") return 2;
        return 3;
      }
      return getWeight(a.condition).compareTo(getWeight(b.condition));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Technician Comments",
                style: ApptextstyleConstants.mediumText(
                  color: ColorConstants.textBlueColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter inspection comments...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              if (reInspectionItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Needs Re-Inspection Checklist",
                  style: ApptextstyleConstants.mediumText(
                    color: ColorConstants.textBlueColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                  },
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Component", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Re-Insp", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    ...reInspectionItems.map((task) {
                      final componentName = _getComponentName(task.taskId, controller);
                      final isChecked = _reInspectionTaskIds.contains(task.taskId);
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(componentName, style: const TextStyle(fontSize: 12)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              task.condition ?? "",
                              style: TextStyle(
                                color: task.condition == "Replace"
                                    ? Colors.red
                                    : task.condition == "Repair"
                                        ? Colors.orange
                                        : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _reInspectionTaskIds.add(task.taskId);
                                } else {
                                  _reInspectionTaskIds.remove(task.taskId);
                                }
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButtonWidget(
                      text: "SUBMIT INSPECTION REPORT",
                      textSize: 16,
                      isDisabled: formController.savedTasks == 0,
                      onPressed: () async {
                        if (_reInspectionTaskIds.isNotEmpty && _commentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: ColorConstants.errorcolor,
                              content: Text("Technician Comments are mandatory", style: TextStyle(color: Colors.white)),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _isSubmitting = true;
                        });
                        try {
                          final itemsToSave = reInspectionItems.isNotEmpty
                              ? reInspectionItems
                              : (formController.orderedTasks.isNotEmpty ? [formController.orderedTasks.first] : []);
                          
                          for (final task in itemsToSave) {
                            final isChecked = _reInspectionTaskIds.contains(task.taskId);
                            final tempCardController = InspectioncardController();
                            tempCardController.setSelectedOption(task.condition ?? "Good");
                            tempCardController.noteController.text = task.note;
                            tempCardController.descriptionController.text = task.description;
                            if (task.imageFiles != null && task.imageFiles!.isNotEmpty) {
                              for (int i = 0; i < task.imageFiles!.length && i < tempCardController.capturedImages.length; i++) {
                                tempCardController.capturedImages[i] = task.imageFiles![i];
                              }
                            }
                            await tempCardController.saveSingleInspectionTask(
                              status: 5,
                              jobId: widget.jobId,
                              taskId: task.taskId,
                              formId: widget.inspectionFormId,
                              viReInspection: isChecked,
                              vimAdditionalComments: _commentController.text,
                              vimInspectionType: 1,
                            );
                          }

                          final success = await controller.changeStatus(jobId: widget.jobId);
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: ColorConstants.greenColor,
                                content: Text("Inspection report submitted successfully", style: TextStyle(color: Colors.white)),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: ColorConstants.errorcolor,
                                content: Text("Failed to submit inspection report", style: TextStyle(color: Colors.white)),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: ColorConstants.errorcolor,
                              content: Text("Unexpected error: $e", style: const TextStyle(color: Colors.white)),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String _getComponentName(int taskId, InspectionTypeDetailsController controller) {
    for (final categoryTasks in controller.groupedTasks.values) {
      for (final task in categoryTasks) {
        final comp = task["components"];
        if (comp != null && comp["itcId"] == taskId) {
          final compName = comp["itcName"] ?? "Unknown";
          final categoryName = task["categoryName"] ?? "";
          if (categoryName.isNotEmpty) {
            return "$compName ($categoryName)";
          }
          return compName;
        }
      }
    }
    return "Task $taskId";
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
