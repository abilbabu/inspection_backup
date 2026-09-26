import 'package:inspection/utils/custom_toast.dart';
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
import 'package:inspection/view/inspection_screen/widgets/confirm_submission_dialog.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
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
        if (jobStatus == 18) {
          await detailsCtrl.changeStatus(jobId: widget.jobId, status: 11);
          if (!mounted) return;
          jobStatus = 11;
        }
        final inspections = data["inspections"] ?? [];
        _reInspectionTaskIds.clear();
        _initialCompletedTaskIds.clear();

        final bool isCustom = (summaryCtrl.vimIfMasterId ?? 0) == 0;
        final Set<int> approvedReInspectionTaskIds = {};
        for (final list in summaryCtrl.groupedItems.values) {
          for (final item in list) {
            if (item.viReInspection && item.taskId != null) {
              approvedReInspectionTaskIds.add(item.taskId!);
            }
          }
        }
        _reInspectionTaskIds.addAll(approvedReInspectionTaskIds);

        for (int i = 0; i < inspections.length; i++) {
          final inspection = inspections[i];
          final master = inspection["master"] ?? {};
          final int vimInspectionType = master["vimInspectionType"] is num
              ? (master["vimInspectionType"] as num).toInt()
              : int.tryParse(master["vimInspectionType"]?.toString() ?? "") ?? 0;
          final List completedTasks = [];
          if (inspection["completedTasks"] is List) {
            completedTasks.addAll(inspection["completedTasks"]);
          }
          final rawInspectionTasks = inspection["inspectionTasks"];
          if (rawInspectionTasks is List) {
            for (final item in rawInspectionTasks) {
              if (item is Map) {
                if (item["tasks"] is List) {
                  completedTasks.addAll(item["tasks"]);
                } else {
                  completedTasks.add(item);
                }
              }
            }
          }
          for (final savedTask in completedTasks) {
            if (savedTask is Map) {
              final rawId = savedTask["viTaskId"] ??
                  savedTask["itcId"] ??
                  savedTask["taskId"] ??
                  savedTask["viInspectionTaskId"];
              final int? taskId = rawId is num
                  ? rawId.toInt()
                  : int.tryParse(rawId?.toString() ?? "");
              if (taskId == null) continue;
              if (i == 0 || vimInspectionType != 2) {
                _initialCompletedTaskIds.add(taskId);
              }
              final double reTime =
                  double.tryParse(
                    savedTask["viReInspectionTime"]?.toString() ??
                        savedTask["vi_re_inspection_time"]?.toString() ??
                        "",
                  ) ??
                  0.0;
              final bool isReInsp = savedTask["viReInspection"] == true ||
                  savedTask["viReInspection"] == 1 ||
                  savedTask["viReInspection"]?.toString() == "true" ||
                  savedTask["viReInspection"]?.toString() == "1" ||
                  savedTask["vi_re_inspection"] == true ||
                  savedTask["vi_re_inspection"] == 1 ||
                  savedTask["vi_re_inspection"]?.toString() == "true" ||
                  savedTask["vi_re_inspection"]?.toString() == "1" ||
                  reTime > 0.0;
              if (isReInsp || (i > 0 && vimInspectionType == 2 && !isCustom)) {
                if (approvedReInspectionTaskIds.contains(taskId) || (i > 0 && vimInspectionType == 2)) {
                  _reInspectionTaskIds.add(taskId);
                }
              }
            }
          }
        }
        final Set<int> reinspectedTaskIds = {};
        for (int i = 0; i < inspections.length; i++) {
          final inspection = inspections[i];
          final master = inspection["master"] ?? {};
          final int vimInspectionType = master["vimInspectionType"] is num
              ? (master["vimInspectionType"] as num).toInt()
              : int.tryParse(master["vimInspectionType"]?.toString() ?? "") ?? 0;
          if (i > 0 || vimInspectionType == 2) {
            final List completedTasks = [];
            if (inspection["completedTasks"] is List) {
              completedTasks.addAll(inspection["completedTasks"]);
            }
            final rawInspectionTasks = inspection["inspectionTasks"];
            if (rawInspectionTasks is List) {
              for (final item in rawInspectionTasks) {
                if (item is Map) {
                  if (item["tasks"] is List) {
                    completedTasks.addAll(item["tasks"]);
                  } else {
                    completedTasks.add(item);
                  }
                }
              }
            }
            for (final savedTask in completedTasks) {
              if (savedTask is Map) {
                final rawId = savedTask["viTaskId"] ??
                    savedTask["itcId"] ??
                    savedTask["taskId"] ??
                    savedTask["viInspectionTaskId"];
                final int? taskId = rawId is num
                    ? rawId.toInt()
                    : int.tryParse(rawId?.toString() ?? "");
                if (taskId != null) {
                  reinspectedTaskIds.add(taskId);
                }
              }
            }
          }
        }
        for (final taskId in _reInspectionTaskIds) {
          if (!reinspectedTaskIds.contains(taskId)) {
            formCtrl.prepareTaskForReInspection(taskId);
          }
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> _showExitConfirmation() async {
    final result = await ConfirmSubmissionDialog.showDiscard(context);
    return result ?? false;
  }

  void _handleBackNavigation() async {
    final shouldExit = await _showExitConfirmation();
    if (!shouldExit || !mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go("/home");
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
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: "Re-Inspection Details",
          onBackPress: _handleBackNavigation,
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
                        jobCardCtrl.assignedTechnicianName!.isNotEmpty && ![10, 12, 13, 14].contains(jobStatus)) ...[
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
                      if ((userDepartment == 1 || userDepartment == 2 || userDepartment == 5)) ...[
                        if ([4, 5, 18, 11].contains(jobStatus)) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.sync_alt, color: Colors.white, size: 18),
                              label: const Text(
                                "REASSIGN TECHNICIAN",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstants.textBlueColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                await showReassignTechnicianBottomSheet(context);
                              },
                            ),
                          ),
                        ] else if ([6, 12].contains(jobStatus)) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.block, color: Colors.grey, size: 18),
                              label: const Text(
                                "Reassignment unavailable",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Reassignment is unavailable because the inspection has been completed.",
                            style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
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
                      SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            detailsCtrl.searchAssignedComponents(
                              summaryCtrl.vimIfMasterId ?? 0,
                              value,
                            );
                          },
                          decoration: InputDecoration(
                            hintText: "Search components...",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            suffixIcon: detailsCtrl.isSearchingAssigned
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          detailsCtrl.searchAssignedComponents(
                                            summaryCtrl.vimIfMasterId ?? 0,
                                            "",
                                          );
                                        },
                                      )
                                    : null,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: ColorConstants.activecolor,
                                width: 1.5,
                              ),
                            ),
                          ),
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
    final formCtrl = context.watch<InspectionFormController>();
    final detailsCtrl = context.watch<InspectionTypeDetailsController>();

    final allSummaryItems = summaryController.groupedItems.values
        .expand((list) => list)
        .toList();

    final Set<int> processedTaskIds = {};
    final List<InspectionItem> originalReInspectionItems = [];
    final List<InspectionItem> newlyAddedSummaryItems = [];

    for (final item in allSummaryItems) {
      if (!item.viReInspection || item.taskId == null) continue;

      processedTaskIds.add(item.taskId!);
      final bool isOriginal = _initialCompletedTaskIds.contains(item.taskId!) ||
          item.originalStatus != null;

      if (isOriginal) {
        originalReInspectionItems.add(item);
      } else {
        newlyAddedSummaryItems.add(item);
      }
    }

    originalReInspectionItems.sort((a, b) {
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

    final List<Map<String, dynamic>> extraNewlyAdded = [];
    for (final taskId in formCtrl.savedTaskIds) {
      if (!processedTaskIds.contains(taskId) &&
          !_initialCompletedTaskIds.contains(taskId)) {
        processedTaskIds.add(taskId);
        Map<String, dynamic>? componentData;
        for (final task in detailsCtrl.allTaskComponents) {
          final id = task["itcId"];
          final int idInt = id is num ? id.toInt() : int.tryParse(id?.toString() ?? "") ?? 0;
          if (idInt == taskId) {
            componentData = task;
            break;
          }
        }
        if (componentData == null) {
          for (final entry in detailsCtrl.groupedTasks.entries) {
            for (final t in entry.value) {
              final comp = t["components"];
              final id = comp?["itcId"];
              final int idInt = id is num ? id.toInt() : int.tryParse(id?.toString() ?? "") ?? 0;
              if (idInt == taskId) {
                componentData = comp;
                break;
              }
            }
            if (componentData != null) break;
          }
        }

        final taskSavedData = formCtrl.getTaskById(taskId);
        final String title = componentData?["itcName"]?.toString() ?? "Component #$taskId";
        final String assemblyDesc = componentData?["assemblyCodeDesc"]?.toString().trim() ?? "";
        final String assemblyName = componentData?["assemblyCodeName"]?.toString().trim() ?? "";
        final String repairGroup = componentData?["repairGroupName"]?.toString().trim() ?? "";

        String category = "";
        if (assemblyDesc.isNotEmpty && assemblyDesc != "D") {
          category = assemblyDesc;
        } else if (assemblyName.isNotEmpty && assemblyName != "D") {
          category = assemblyName;
        } else if (repairGroup.isNotEmpty && repairGroup != "D") {
          category = repairGroup;
        }

        InspectionStatus status = InspectionStatus.repair;
        if (taskSavedData != null && taskSavedData.condition != null) {
          final cond = taskSavedData.condition!.toLowerCase();
          if (cond == "good") {
            status = InspectionStatus.good;
          } else if (cond == "repair") {
            status = InspectionStatus.repair;
          } else if (cond == "replace") {
            status = InspectionStatus.replace;
          } else if (cond == "poor") {
            status = InspectionStatus.poor;
          } else if (cond == "n/a") {
            status = InspectionStatus.na;
          }
        }

        extraNewlyAdded.add({
          "title": title,
          "category": category,
          "status": status,
          "taskId": taskId,
        });
      }
    }

    if (originalReInspectionItems.isEmpty &&
        newlyAddedSummaryItems.isEmpty &&
        extraNewlyAdded.isEmpty) {
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
            ...originalReInspectionItems.map((item) {
              final originalStatus = item.originalStatus ?? item.status;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      (item.category.isNotEmpty && item.category != "D")
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
                                : originalStatus == InspectionStatus.poor
                                    ? Colors.amber.shade800
                                    : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }),
            ...newlyAddedSummaryItems.map((item) {
              final displayStatus = item.originalStatus ?? item.status;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (item.category.isNotEmpty && item.category != "D")
                                ? "${item.title} (${item.category})"
                                : item.title,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.greenColor.withOpacity(0.15),
                            border: Border.all(
                              color: ColorConstants.greenColor,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "NEW",
                            style: TextStyle(
                              color: ColorConstants.greenColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      displayStatus.name.toUpperCase(),
                      style: TextStyle(
                        color: displayStatus == InspectionStatus.replace
                            ? Colors.red
                            : displayStatus == InspectionStatus.repair
                                ? Colors.orange
                                : displayStatus == InspectionStatus.poor
                                    ? Colors.amber.shade800
                                    : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }),
            ...extraNewlyAdded.map((item) {
              final InspectionStatus displayStatus =
                  item["status"] as InspectionStatus;
              final String title = item["title"] as String;
              final String category = item["category"] as String;
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (category.isNotEmpty && category != "D")
                                ? "$title ($category)"
                                : title,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.greenColor.withOpacity(0.15),
                            border: Border.all(
                              color: ColorConstants.greenColor,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "NEW",
                            style: TextStyle(
                              color: ColorConstants.greenColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      displayStatus.name.toUpperCase(),
                      style: TextStyle(
                        color: displayStatus == InspectionStatus.replace
                            ? Colors.red
                            : displayStatus == InspectionStatus.repair
                                ? Colors.orange
                                : displayStatus == InspectionStatus.poor
                                    ? Colors.amber.shade800
                                    : Colors.blue,
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
          final int idInt = taskId is num ? taskId.toInt() : int.tryParse(taskId.toString()) ?? 0;
          final isReInspectionItem = _reInspectionTaskIds.contains(idInt);
          final isSaved = formController.isTaskSaved(idInt);
          final isNewComponent =
              !_initialCompletedTaskIds.contains(idInt) && isSaved;
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
            final int idInt = taskId is num ? taskId.toInt() : int.tryParse(taskId.toString()) ?? 0;
            final isReInspectionItem = _reInspectionTaskIds.contains(idInt);
            final isSaved = formController.isTaskSaved(idInt);
            final isNewComponent =
                !_initialCompletedTaskIds.contains(idInt) && isSaved;
            if (isReInspectionItem || isNewComponent) {
              visibleTasks.add(Map<String, dynamic>.from(task));
              addedTaskIds.add(idInt);
            }
          }
        }
      }
      for (final task in controller.allTaskComponents) {
        final taskId = task["itcId"];
        if (taskId != null) {
          final int idInt = taskId is num ? taskId.toInt() : int.tryParse(taskId.toString()) ?? 0;
          if (!addedTaskIds.contains(idInt)) {
            final isReInspectionItem = _reInspectionTaskIds.contains(idInt);
            final isSaved = formController.isTaskSaved(idInt);
            final isNewComponent =
                !_initialCompletedTaskIds.contains(idInt) && isSaved;
            if (isReInspectionItem || isNewComponent) {
              visibleTasks.add({"components": Map<String, dynamic>.from(task)});
              addedTaskIds.add(idInt);
            }
          }
        }
      }
    }

    final String query = _searchController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> filteredTasks = query.isEmpty
        ? visibleTasks
        : visibleTasks.where((task) {
            final components = isCustom ? task : (task["components"] ?? task);
            final name = (components["itcName"] ?? "").toString().toLowerCase();
            return name.contains(query);
          }).toList();

    if (filteredTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            _searchController.text.isNotEmpty
                ? "No items found"
                : "No re-inspection items assigned.",
            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
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
      create: (_) => InspectionsummarypageController(),
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
                                      await speechController.startListening(
                                        controller: _commentController,
                                        context: context,
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
    final confirm = await ConfirmSubmissionDialog.show(context);
    if (confirm != true) return;

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

      if (taskToSaveId == 0) {
        if (isCustom) {
          for (final task in controller.allTaskComponents) {
            final taskId = task["itcId"];
            if (taskId != null) {
              final int parsedId = taskId is num ? taskId.toInt() : int.tryParse(taskId.toString()) ?? 0;
              if (parsedId > 0) {
                taskToSaveId = parsedId;
                break;
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
                final int parsedId = taskId is num ? taskId.toInt() : int.tryParse(taskId.toString()) ?? 0;
                if (parsedId > 0) {
                  taskToSaveId = parsedId;
                  break;
                }
              }
            }
            if (taskToSaveId > 0) break;
          }
        }
      }

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
        CustomToast.showSuccess(context, "Re-inspection report submitted successfully");
        context.go(
          "/inspectionsummarypage",
          extra: {"jobId": widget.jobId, "flag": 2},
        );
      } else {
        CustomToast.showError(context, "Failed to submit re-inspection report");
      }
    } catch (e) {
      CustomToast.showError(context, "Unexpected error: $e");
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
                            subtitle: Text("Active: ${technician["activeJobCardCount"] ?? 0} | Completed: ${technician["completedJobCardCount"] ?? 0}"),
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
                                CustomToast.showSuccess(parentContext, "Technician Assigned for Re-Inspection");
                                parentContext.go("/home");
                              } else {
                                CustomToast.showError(parentContext, "Technician Assignment Failed");
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
                                    categoryId:
                                        components["itcCategoryId"] ??
                                        components["categoryId"] ??
                                        0,
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

  Future<void> showReassignTechnicianBottomSheet(BuildContext context) async {
    final parentContext = context;
    final controller = context.read<InspectionDetailsController>();
    final jobCtrl = context.read<JobcarddetailsController>();
    final currentTechId = int.tryParse(jobCtrl.jobCardData?["jobcard"]?["jobTechnicianId"]?["userId"]?.toString() ?? "") ?? -1;

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
                    "Reassign Technician",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Current: ${jobCtrl.assignedTechnicianName ?? 'None'}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
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
                    height: 300,
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final technician = filteredList[index];
                        final isCurrentTech = int.tryParse(technician["userId"].toString()) == currentTechId;
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          color: isCurrentTech ? Colors.green.shade50 : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrentTech ? Colors.green.shade100 : Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                color: isCurrentTech ? Colors.green : Colors.blue,
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
                            subtitle: Text(
                              isCurrentTech 
                                  ? "Current Technician" 
                                  : "Active: ${technician["activeJobCardCount"] ?? 0} | Completed: ${technician["completedJobCardCount"] ?? 0}",
                              style: TextStyle(
                                color: isCurrentTech ? Colors.green.shade700 : Colors.grey.shade600,
                                fontWeight: isCurrentTech ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isCurrentTech
                                ? const Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.sync_alt,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                            onTap: isCurrentTech ? null : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Confirm Reassignment"),
                                  content: Text("Are you sure you want to reassign this job card to ${technician["userName"]}?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("CANCEL"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("REASSIGN"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                Navigator.pop(context); // close bottom sheet
                                final res = await controller.reassignTechnician(
                                  jobId: widget.jobId,
                                  newTechnicianId: int.tryParse(technician["userId"].toString()) ?? 0,
                                  reassignedById: controller.loginTechnicianId ?? 0,
                                  technicianName: technician["userName"].toString(),
                                );
                                if (res["success"] == true) {
                                  CustomToast.showSuccess(parentContext, res["message"] ?? "Technician Reassigned Successfully");
                                } else {
                                  CustomToast.showError(parentContext, res["message"] ?? "Technician Reassignment Failed");
                                }
                                parentContext.read<JobcarddetailsController>().postJobCardDetails(widget.jobId, forceRefresh: true);
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
}
