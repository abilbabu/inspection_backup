import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/view/inspection_screen/inspection_summary_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectionsummarypageController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, List<InspectionItem>> groupedItems = {};
  int? vimInspectionTypeId;
  int? vimIfMasterId;
  String inspectionFormName = "";
  bool isInspectionAssigned = false;
  bool isPredefinedInspectionAssigned = false;
  bool isCustomInspectionAssigned = false;
  String technicianComment = "";
  String supervisorComment = "";
  String saComment = "";

  Future<ApiResponse> getInspectionSummary(int jobId) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse(ApiServices.getInspectionSummary),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"jobId": jobId}),
      );
      final result = jsonDecode(response.body);
      final inspections = List.from(result["data"]["inspections"] as List? ?? []);
      for (int i = 0; i < inspections.length; i++) {
        final insp = inspections[i];
        final master = insp["master"] ?? {};
        final tasks = insp["inspectionTasks"] as List? ?? [];
      }
      inspections.sort((a, b) {
        final aId = a["master"]?["vimId"] as num? ?? 0;
        final bId = b["master"]?["vimId"] as num? ?? 0;
        return aId.compareTo(bId);
      });
      final attachments =
          result["data"]["jobCard"]["attachments"] as List? ?? [];
      final Map<int, List<String>> imageMap = {};
      final Map<int, String> videoMap = {};
      final Map<int, String> audioMap = {};
      for (final att in attachments) {
        final taskId = att["iaInspectionTaskId"];
        if (taskId == null) continue;
        if (att["iaType"] == 0) {
          imageMap.putIfAbsent(taskId, () => []).add(att["iaUrl"]);
        }
        if (att["iaType"] == 1) audioMap[taskId] = att["iaUrl"];
        if (att["iaType"] == 2) videoMap[taskId] = att["iaUrl"];
      }
      groupedItems.clear();
      inspectionFormName = "";
      isInspectionAssigned = false;
      isPredefinedInspectionAssigned = false;
      isCustomInspectionAssigned = false;
      technicianComment = "";
      supervisorComment = "";
      saComment = "";
      if (inspections.length > 1) {
        isInspectionAssigned = true;
        final assignedInspection = inspections[1];
        final master = assignedInspection["master"];
        if (master["vimIfMasterId"] == null) {
          isCustomInspectionAssigned = true;
          isInspectionAssigned = true;
        } else {
          isPredefinedInspectionAssigned = true;
          isInspectionAssigned = true;
        }
      }
      final Map<String, Map<String, InspectionItem>> categoryTaskMap = {};
      for (final inspection in inspections) {
        final master = inspection["master"];
        if (master == null) continue;
        final int? inspType = master["vimInspectionType"];
        final int? ifMasterId = master["vimIfMasterId"];
        final tasks = inspection["inspectionTasks"] as List? ?? [];
        vimInspectionTypeId = inspType;
        vimIfMasterId = ifMasterId;
        if (ifMasterId != null && ifMasterId == 0) continue;
        final String techComm = master["vimAdditionalComments"]?.toString() ?? "";
        final String supComm = master["vimSupervisorComment"]?.toString() ?? "";
        final String serviceComm = master["vimSaComment"]?.toString() ?? "";

        technicianComment = techComm;
        if (supComm.trim().isNotEmpty) {
          supervisorComment = supComm;
        }
        if (serviceComm.trim().isNotEmpty) {
          saComment = serviceComm;
        }
        if (inspType == 1) {
          inspectionFormName = master["formName"]?.toString() ?? "";
        } else if (inspType == 2 || ifMasterId == null) {
          inspectionFormName = "Custom Inspection";
        }
        if (tasks.isEmpty) continue;
        for (final category in tasks) {
          final name = category["taskCategoryName"]?.toString() ?? "General";
          final categoryTasks = category["tasks"] as List? ?? [];
          if (categoryTasks.isEmpty) continue;
          
          final categoryMap = categoryTaskMap.putIfAbsent(name, () => {});
          for (final task in categoryTasks) {
            final taskId = task["viTaskId"];
            final taskKey = taskId?.toString() ?? task["taskName"]?.toString() ?? "";
            if (taskKey.isEmpty) continue;
            final flags = task["inspectionTaskFlags"] ?? {};
            
            final existing = categoryMap[taskKey];
            final wasReInspection = existing?.viReInspection ?? false;
            final double reTime = double.tryParse(task["viReInspectionTime"]?.toString() ?? "") ?? 0.0;
            final isReInspection = task["viReInspection"] == true ||
                task["viReInspection"] == 1 ||
                task["viReInspection"]?.toString() == "true" ||
                reTime > 0.0 ||
                inspType == 2;
            
            final String note = (task["viNote"] ?? "").toString();
            final String initialNote = (task["viDescription"] ?? "").toString();
            
            final String finalNote = note.trim().isNotEmpty ? note : (existing?.note ?? "");
            final String finalInitialNote = initialNote.trim().isNotEmpty ? initialNote : (existing?.initialNote ?? "");
            
            final List<String> images = imageMap[taskId] ?? [];
            final List<String> finalImages = images.isNotEmpty ? images : (existing?.imageUrls ?? []);
            final String? finalVideo = videoMap[taskId] ?? existing?.videoUrl;
            final String? finalAudio = audioMap[taskId] ?? existing?.audioUrl;

            final InspectionStatus? finalOriginalStatus = existing != null ? (existing.originalStatus ?? existing.status) : null;

            categoryMap[taskKey] = InspectionItem(
              title: task["taskName"] ?? "",
              category: name,
              taskId: taskId is num ? taskId.toInt() : int.tryParse(taskId?.toString() ?? ""),
              status: _mapStatus(task),
              originalStatus: finalOriginalStatus,
              allowGood: flags["good"] == true,
              allowRepair: flags["repair"] == true,
              allowPoor: flags["poor"] == true,
              allowReplace: flags["replace"] == true,
              allowNA: flags["notApplicable"] == true,
              imageUrls: finalImages,
              videoUrl: finalVideo,
              audioUrl: finalAudio,
              note: finalNote,
              initialNote: finalInitialNote,
              viReInspection: isReInspection || wasReInspection,
            );
          }
        }
      }
      categoryTaskMap.forEach((categoryName, tasksMap) {
        groupedItems[categoryName] = tasksMap.values.toList();
      });
      return ApiResponse(
        success: result["statusCode"] == 200,
        statusCode: result['statusCode'],
        timeStamp: result['timeStamp'],
        status: result['status'],
        data: result['data'],
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  InspectionStatus _mapStatus(Map task) {
    final replace = task["viReplace"] == true || task["viReplace"] == 1 || task["viReplace"]?.toString() == "true";
    final repair = task["viRepair"] == true || task["viRepair"] == 1 || task["viRepair"]?.toString() == "true";
    final poor = task["viPoor"] == true || task["viPoor"] == 1 || task["viPoor"]?.toString() == "true";
    final good = task["viGood"] == true || task["viGood"] == 1 || task["viGood"]?.toString() == "true";
    if (replace) return InspectionStatus.replace;
    if (repair) return InspectionStatus.repair;
    if (poor) return InspectionStatus.poor;
    if (good) return InspectionStatus.good;
    return InspectionStatus.na;
  }
}
