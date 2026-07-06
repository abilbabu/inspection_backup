import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspection/controller/inspectionCard_controller.dart';
import 'package:inspection/controller/inspectionFormController.dart';
import 'package:inspection/controller/inspectionTypeDetails_controller.dart';
import 'package:inspection/controller/inspectionDetails_controller.dart';
import 'package:inspection/controller/inspectionSummaryPage_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_card.dart';
import 'package:inspection/view/inspection_screen/inspection_summary_page.dart';

class ReassignedDetailsPage extends StatefulWidget {
  final int jobId;
  const ReassignedDetailsPage({super.key, required this.jobId});

  @override
  State<ReassignedDetailsPage> createState() => _ReassignedDetailsPageState();
}

class _ReassignedDetailsPageState extends State<ReassignedDetailsPage> {
  int userDepartment = 0;
  bool isLoading = true;
  final Set<int> _reInspectionTaskIds = {};
  final Set<int> _initialCompletedTaskIds = {};
  final TextEditingController _commentController = TextEditingController();
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
      if (!mounted) return;
      await loadUserDepartment();
      await loadData();
    });
  }

  Future<void> loadUserDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userDepartment =
          int.tryParse(prefs.getString("userDepartment") ?? "0") ?? 0;
    });
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final summaryCtrl = context.read<InspectionsummarypageController>();
      final detailsCtrl = context.read<InspectionTypeDetailsController>();
      final formCtrl = context.read<InspectionFormController>();
      final detailsCtrl2 = context.read<InspectionDetailsController>();
      final jobCardCtrl = context.read<JobcarddetailsController>();

      await summaryCtrl.getInspectionSummary(widget.jobId);

      final inspectionResponse = await detailsCtrl.getInspectionDetailsById(
        widget.jobId,
      );

      int inspectionFormId = summaryCtrl.vimIfMasterId ?? 0;
      await detailsCtrl.postInspectionTypeDetails(inspectionFormId);
      await detailsCtrl.getComponentList();
      await detailsCtrl2.loadLoginTechnicianId();
      await jobCardCtrl.postJobCardDetails(widget.jobId);

      if (inspectionResponse.success == true &&
          inspectionResponse.data != null) {
        detailsCtrl.applySavedInspection(
          inspectionResponse.data as Map<String, dynamic>,
          formCtrl,
        );
        detailsCtrl.applySavedCustomInspection(
          inspectionResponse.data as Map<String, dynamic>,
          formCtrl,
        );

        final data = inspectionResponse.data as Map<String, dynamic>;
        int jobStatus = summaryCtrl.jobStatus;
        if (jobStatus == 10 || jobStatus == 18) {
          await detailsCtrl.changeStatus(jobId: widget.jobId, status: 11);
          if (!mounted) return;
          jobStatus = 11;
        }
        final inspections = data["inspections"] ?? [];
        _reInspectionTaskIds.clear();
        _initialCompletedTaskIds.clear();

        final bool isCustom = (summaryCtrl.vimIfMasterId ?? 0) == 0;
        for (final list in summaryCtrl.groupedItems.values) {
          for (final item in list) {
            if (item.viReInspection && item.taskId != null) {
              _reInspectionTaskIds.add(item.taskId!);
            }
          }
        }
        for (int i = 0; i < inspections.length; i++) {
          final inspection = inspections[i];
          final master = inspection["master"] ?? {};
          final int vimInspectionType = master["vimInspectionType"] ?? 0;
          final completedTasks = inspection["completedTasks"] ?? [];
          for (final savedTask in completedTasks) {
            final int taskId = savedTask["viTaskId"];
            _initialCompletedTaskIds.add(taskId);
            final double reTime =
                double.tryParse(
                  savedTask["viReInspectionTime"]?.toString() ?? "",
                ) ??
                0.0;
            if (savedTask["viReInspection"] == true ||
                savedTask["viReInspection"] == 1 ||
                savedTask["viReInspection"]?.toString() == "true" ||
                reTime > 0.0 ||
                (i > 0 && vimInspectionType == 2 && !isCustom)) {
              _reInspectionTaskIds.add(taskId);
            }
          }
        }
        final Set<int> reinspectedTaskIds = {};
        for (int i = 1; i < inspections.length; i++) {
          final completedTasks = inspections[i]["completedTasks"] ?? [];
          for (final savedTask in completedTasks) {
            final int taskId = savedTask["viTaskId"];
            reinspectedTaskIds.add(taskId);
          }
        }
        for (final taskId in _reInspectionTaskIds) {
          if (!reinspectedTaskIds.contains(taskId) ||
              jobStatus == 10 ||
              jobStatus == 11 ||
              jobStatus == 18) {
            formCtrl.makeTaskEditable(taskId);
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading reassigned data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryCtrl = context.watch<InspectionsummarypageController>();
    final detailsCtrl = context.watch<InspectionTypeDetailsController>();
    final formCtrl = context.watch<InspectionFormController>();
    final detailsCtrl2 = context.watch<InspectionDetailsController>();
    final jobCardCtrl = context.watch<JobcarddetailsController>();

    final int jobStatus = summaryCtrl.jobStatus;
    final bool showEditable = (userDepartment == 4) ||
        ((userDepartment == 0 || userDepartment == 1) &&
            (jobStatus == 18 || jobStatus == 11));

    final bool showAssignment = (userDepartment == 2 || userDepartment == 5) ||
        ((userDepartment == 0 || userDepartment == 1) &&
            (jobStatus != 18 && jobStatus != 11));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go("/home");
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: "Re-Inspection Details",
          onBackPress: () {
            context.go("/home");
          },
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleSummaryWidget(jobId: widget.jobId),
                    const SizedBox(height: 16),
                    _buildCommentsSummaryCard(summaryCtrl),
                    if (jobCardCtrl.isTechnicianAssigned == true &&
                        jobCardCtrl.assignedTechnicianName != null &&
                        jobCardCtrl.assignedTechnicianName!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorConstants.greenColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ColorConstants.greenColor),
                        ),
                        child: Center(
                          child: Text(
                            "Assigned Technician : ${jobCardCtrl.assignedTechnicianName?.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ')}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ColorConstants.greenColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (showAssignment) ...[
                      _buildReadOnlyReInspectionList(summaryCtrl),
                      const SizedBox(height: 24),
                      CustomButtonWidget(
                        text: "ASSIGN TECHNICIAN",
                        textSize: 16,
                        onPressed: () =>
                            showTechnicianBottomSheet(context, detailsCtrl2),
                      ),
                    ] else if (showEditable) ...[
                      _buildReadOnlyReInspectionList(summaryCtrl),
                      const SizedBox(height: 20),
                      Text(
                        "Re-Inspection Checklist Items",
                        style: ApptextstyleConstants.mediumText(
                          color: ColorConstants.textBlueColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildEditableReInspectionList(
                        detailsCtrl,
                        formCtrl,
                        summaryCtrl,
                      ),
                      const SizedBox(height: 16),
                      CustomButtonTwo(
                        text: "+ ADD COMPONENT",
                        onPressed: () {
                          _showGeneralInspectionBottomSheet(
                            context,
                            detailsCtrl,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTechnicianCommentsField(),
                      const SizedBox(height: 24),
                      _isSubmitting
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButtonWidget(
                              text: "SUBMIT RE-INSPECTION REPORT",
                              textSize: 16,
                              onPressed: () => _submitReInspectionReport(
                                detailsCtrl,
                                formCtrl,
                                summaryCtrl,
                              ),
                            ),
                    ] else ...[
                      _buildReadOnlyReInspectionList(summaryCtrl),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCommentsSummaryCard(
    InspectionsummarypageController summaryCtrl,
  ) {
    final String techComm = summaryCtrl.previousTechnicianComment.trim().isEmpty
        ? (summaryCtrl.technicianComment.trim().isEmpty ? "" : summaryCtrl.technicianComment)
        : summaryCtrl.previousTechnicianComment;

    final String supComm = summaryCtrl.previousSupervisorComment.trim().isEmpty
        ? (summaryCtrl.supervisorComment.trim().isEmpty ? "" : summaryCtrl.supervisorComment)
        : summaryCtrl.previousSupervisorComment;

    final String saComm = summaryCtrl.previousSaComment.trim().isEmpty
        ? (summaryCtrl.saComment.trim().isEmpty ? "" : summaryCtrl.saComment)
        : summaryCtrl.previousSaComment;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Previous Feedback Summary",
              style: ApptextstyleConstants.mediumText(
                color: ColorConstants.textBlueColor,
                fontSize: 15,
              ),
            ),
            const Divider(height: 20),
            _buildCommentRow(
              "Technician Comment",
              techComm,
            ),
            const SizedBox(height: 12),
            _buildCommentRow(
              "Supervisor Comment",
              supComm,
            ),
            const SizedBox(height: 12),
            _buildCommentRow("Service Advisor Comment", saComm),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentRow(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content.isEmpty ? "No comments provided" : content,
          style: TextStyle(
            fontSize: 14,
            color: content.isEmpty ? Colors.grey.shade400 : Colors.black87,
            fontStyle: content.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyReInspectionList(
    InspectionsummarypageController summaryController,
  ) {
    final reInspectionItems = summaryController.groupedItems.values
        .expand((list) => list)
        .where((item) => item.viReInspection)
        .toList();

    reInspectionItems.sort((a, b) {
      int getWeight(InspectionStatus status) {
        if (status == InspectionStatus.replace) return 0;
        if (status == InspectionStatus.repair) return 1;
        if (status == InspectionStatus.poor) return 2;
        return 3;
      }

      return getWeight(
        a.originalStatus ?? a.status,
      ).compareTo(getWeight(b.originalStatus ?? b.status));
    });

    if (reInspectionItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Items Requesting Re-Inspection",
          style: ApptextstyleConstants.mediumText(
            color: ColorConstants.textBlueColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2)},
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: const [
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Component",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Original Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            ...reInspectionItems.map((item) {
              final originalStatus = item.originalStatus ?? item.status;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      item.category.isNotEmpty
                          ? "${item.title} (${item.category})"
                          : item.title,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      originalStatus.name.toUpperCase(),
                      style: TextStyle(
                        color: originalStatus == InspectionStatus.replace
                            ? Colors.red
                            : originalStatus == InspectionStatus.repair
                            ? Colors.orange
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableReInspectionList(
    InspectionTypeDetailsController controller,
    InspectionFormController formController,
    InspectionsummarypageController summaryCtrl,
  ) {
    final List<Map<String, dynamic>> visibleTasks = [];
    final bool isCustom =
        summaryCtrl.vimIfMasterId == null || summaryCtrl.vimIfMasterId == 0;

    if (isCustom) {
      for (final task in controller.allTaskComponents) {
        final taskId = task["itcId"];
        if (taskId != null) {
          final isReInspectionItem = _reInspectionTaskIds.contains(taskId);
          final isSaved = formController.isTaskSaved(taskId);
          final isNewComponent =
              !_initialCompletedTaskIds.contains(taskId) && isSaved;
          if (isReInspectionItem || isNewComponent) {
            visibleTasks.add(Map<String, dynamic>.from(task));
          }
        }
      }
    } else {
      final Set<int> addedTaskIds = {};
      for (final entry in controller.groupedTasks.entries) {
        final rawTasks = entry.value;
        for (final task in rawTasks) {
          final components = task["components"];
          final taskId = components?["itcId"];
          if (taskId != null) {
            final isReInspectionItem = _reInspectionTaskIds.contains(taskId);
            final isSaved = formController.isTaskSaved(taskId);
            final isNewComponent =
                !_initialCompletedTaskIds.contains(taskId) && isSaved;
            if (isReInspectionItem || isNewComponent) {
              visibleTasks.add(Map<String, dynamic>.from(task));
              addedTaskIds.add(taskId);
            }
          }
        }
      }
      for (final task in controller.allTaskComponents) {
        final taskId = task["itcId"];
        if (taskId != null && !addedTaskIds.contains(taskId)) {
          final isReInspectionItem = _reInspectionTaskIds.contains(taskId);
          final isSaved = formController.isTaskSaved(taskId);
          final isNewComponent =
              !_initialCompletedTaskIds.contains(taskId) && isSaved;
          if (isReInspectionItem || isNewComponent) {
            visibleTasks.add({"components": Map<String, dynamic>.from(task)});
            addedTaskIds.add(taskId);
          }
        }
      }
    }

    if (visibleTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "No re-inspection items assigned.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleTasks.length,
      itemBuilder: (context, index) {
        final task = visibleTasks[index];
        final bool isCustom =
            summaryCtrl.vimIfMasterId == null || summaryCtrl.vimIfMasterId == 0;
        final components = isCustom ? task : task["components"];
        final categoryId = isCustom
            ? (components["itcCategoryId"] ?? 0)
            : (task["categoryId"] ?? 0);
        final formId = summaryCtrlMasterId();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ChangeNotifierProvider(
            key: ValueKey(components["itcId"]),
            create: (_) => InspectioncardController(),
            child: InspectionCard(
              categoryId: categoryId,
              jobid: widget.jobId,
              taskid: components["itcId"],
              formid: formId,
              title: components["itcName"],
              inspectionTaskGoodFlag: components["allowGood"] ?? false,
              inspectionTaskRepairFlag: components["allowRepair"] ?? false,
              inspectionTaskReplaceFlag: components["allowReplace"] ?? false,
              inspectionTaskPoorFlag: components["allowPoor"] ?? false,
              inspectionTaskNotApplicable:
                  components["allowNotApplicable"] ?? false,
              inspectionTaskPhotoFlag: components["allowPhoto"] ?? false,
              inspectionTaskAudioFlag: components["allowAudio"] ?? false,
              inspectionTaskInstruction: components["instructionText"],
              inspectionPhotoMandatory: components["photoMandatory"] ?? false,
              inspectionAudioMandatory: components["audioMandatory"] ?? false,
              allowMultipleImage: components["allowMultipleImage"] == true,
              allowVideo: components["allowVideo"] == true,
              assemblyCodeName:
                  components["assemblyCodeName"]?.toString() ?? "",
              assemblyCodeDesc:
                  components["assemblyCodeDesc"]?.toString() ?? "",
              repairGroupName: components["repairGroupName"]?.toString() ?? "",
              repairGroupDesc: components["repairGroupDesc"]?.toString() ?? "",
              inspectionTypeid: summaryCtrl.vimInspectionTypeId ?? 2,
              isReInspection: true,
            ),
          ),
        );
      },
    );
  }

  int summaryCtrlMasterId() {
    final summaryCtrl = context.read<InspectionsummarypageController>();
    return summaryCtrl.vimIfMasterId ?? 0;
  }

  Widget _buildTechnicianCommentsField() {
    return ChangeNotifierProvider(
      create: (_) => InspectionsummarypageController()..initSpeech(),
      child: Consumer<InspectionsummarypageController>(
        builder: (context, cardController, _) {
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Re-Inspection Additional Comments",
                    style: ApptextstyleConstants.mediumText(
                      color: ColorConstants.textBlueColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Enter inspection comments...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            12,
                            50,
                            12,
                          ),
                        ),
                      ),

                      Consumer<InspectionsummarypageController>(
                        builder: (context, speechController, child) {
                          return Positioned(
                            right: 8,
                            top: 8,
                            child: speechController.isListening
                                ? _buildSmallWaveMic(speechController)
                                : IconButton(
                                    icon: const Icon(
                                      Icons.mic_none,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      await speechController.initSpeech();
                                      await speechController.startListening(
                                        controller: _commentController,
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallWaveMic(InspectionsummarypageController controller) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 4, end: 12),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  builder: (_, value, __) {
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
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: controller.stopListening,
            child: const Icon(Icons.close, size: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReInspectionReport(
    InspectionTypeDetailsController controller,
    InspectionFormController formController,
    InspectionsummarypageController summaryController,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final bool isCustom =
          summaryController.vimIfMasterId == null ||
          summaryController.vimIfMasterId == 0;
      final List<int> visibleTaskIds = [];
      if (isCustom) {
        for (final task in controller.allTaskComponents) {
          final taskId = task["itcId"];
          if (taskId != null) {
            final isReInspectionItem = _reInspectionTaskIds.contains(taskId);
            final isSaved = formController.isTaskSaved(taskId);
            final isNewComponent =
                !_initialCompletedTaskIds.contains(taskId) && isSaved;
            if (isReInspectionItem || isNewComponent) {
              visibleTaskIds.add(taskId);
            }
          }
        }
      } else {
        for (final entry in controller.groupedTasks.entries) {
          final rawTasks = entry.value;
          for (final task in rawTasks) {
            final components = task["components"];
            final taskId = components?["itcId"];
            if (taskId != null) {
              final isReInspectionItem = _reInspectionTaskIds.contains(taskId);
              final isSaved = formController.isTaskSaved(taskId);
              final isNewComponent =
                  !_initialCompletedTaskIds.contains(taskId) && isSaved;
              if (isReInspectionItem || isNewComponent) {
                visibleTaskIds.add(taskId);
              }
            }
          }
        }
      }

      int formId = summaryController.vimIfMasterId ?? 0;
      int taskToSaveId = visibleTaskIds.isNotEmpty ? visibleTaskIds.first : 0;

      if (taskToSaveId > 0) {
        final tempCardController = InspectioncardController();
        await tempCardController.loadExistingTask(
          formController: formController,
          taskId: taskToSaveId,
          isReInspection: true,
        );

        await tempCardController.saveSingleInspectionTask(
          status: 11,
          jobId: widget.jobId,
          taskId: taskToSaveId,
          formId: formId,
          viReInspection: true,
          vimAdditionalComments: _commentController.text,
          vimInspectionType: 2,
        );
      }

      final success = await controller.changeStatus(
        jobId: widget.jobId,
        status: 12,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: ColorConstants.greenColor,
            content: Text(
              "Re-inspection report submitted successfully",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        context.go(
          "/inspectionsummarypage",
          extra: {"jobId": widget.jobId, "flag": 2},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: ColorConstants.errorcolor,
            content: Text(
              "Failed to submit re-inspection report",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ColorConstants.errorcolor,
          content: Text(
            "Unexpected error: $e",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> showTechnicianBottomSheet(
    BuildContext context,
    InspectionDetailsController controller,
  ) async {
    final parentContext = context;
    await controller.getTechnicianList();

    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredList = List.from(
      controller.technicianList,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Technician List",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search Technician",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filteredList = controller.technicianList
                              .where(
                                (e) => e["userName"]
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                              )
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final technician = filteredList[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(
                                Icons.person,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              technician["userName"]
                                  .toString()
                                  .split(' ')
                                  .map(
                                    (word) => word.isNotEmpty
                                        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                        : '',
                                  )
                                  .join(' '),
                            ),
                            subtitle: const Text("Technician"),
                            trailing: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.green,
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              final success = await controller.assignTechnician(
                                jobId: widget.jobId,
                                assigneeId:
                                    int.tryParse(
                                      technician["userId"].toString(),
                                    ) ??
                                    0,
                                supervisorId: controller.loginTechnicianId ?? 0,
                                technicianName: technician["userName"].toString(),
                                formMasterId: parentContext.read<InspectionsummarypageController>().vimIfMasterId,
                                status: 18,
                              );
                              if (success) {
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: ColorConstants.greenColor,
                                    content: Text(
                                      "Technician Assigned for Re-Inspection",
                                    ),
                                  ),
                                );
                                parentContext.go("/home");
                              } else {
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: ColorConstants.errorcolor,
                                    content: Text(
                                      "Technician Assignment Failed",
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    final summaryCtrl = Provider.of<InspectionsummarypageController>(
      context,
      listen: false,
    );
    final int inspectionTypeId = summaryCtrl.vimInspectionTypeId ?? 2;
    FocusManager.instance.primaryFocus?.unfocus();
    final searchController = TextEditingController();
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      requestFocus: false,
      isScrollControlled: true,
      enableDrag: false,
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
              ChangeNotifierProvider.value(value: controller),
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

                            if (pendingTasks.isNotEmpty)
                              ...pendingTasks.map((components) {
                                final formId = summaryCtrlMasterId();
                                return ChangeNotifierProvider(
                                  key: ValueKey(components["itcId"]),
                                  create: (_) => InspectioncardController(),
                                  child: InspectionCard(
                                    jobid: widget.jobId,
                                    taskid: components["itcId"],
                                    formid: formId,
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
                                    inspectionTypeid: inspectionTypeId,
                                    isReInspection: true,
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
}
