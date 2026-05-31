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
      final inspections = result["data"]["inspections"] as List;
      vimInspectionTypeId = inspections.last["master"]["vimInspectionType"];
      vimIfMasterId = inspections.last["master"]["vimIfMasterId"];
      print("**************************************************");
      print(vimIfMasterId);
      print("**************************************************");
      final attachments =
          result["data"]["jobCard"]["attachments"] as List? ?? [];

      // final Map<int, String> imageMap = {};
      final Map<int, List<String>> imageMap = {};
      final Map<int, String> videoMap = {};
      final Map<int, String> audioMap = {};

      for (final att in attachments) {
        final taskId = att["iaInspectionTaskId"];
        if (taskId == null) continue;

        if (att["iaType"] == 0) {
          imageMap.putIfAbsent(taskId, () => []).add(att["iaUrl"]);
        }

        if (att["iaType"] == 1) {
          audioMap[taskId] = att["iaUrl"];
        }

        if (att["iaType"] == 2) {
          videoMap[taskId] = att["iaUrl"];
        }
      }

      groupedItems.clear();

      final inspectionTask = inspections.firstWhere(
        (e) => e["master"]["vimInspectionType"] == 1,
        orElse: () => null,
      );

      if (inspectionTask != null) {
        inspectionFormName =
            inspectionTask["master"]?["formName"]?.toString() ?? "";

        for (final category in inspectionTask["inspectionTasks"]) {
          final name = category["taskCategoryName"];
          final tasks = category["tasks"] as List;

          groupedItems[name] = tasks.map<InspectionItem>((task) {
            final taskId = task["viTaskId"];

            final flags = task["inspectionTaskFlags"] ?? {};

            return InspectionItem(
              title: task["taskName"] ?? "",
              category: name,
              status: _mapStatus(task),

              allowGood: flags["good"] == true,
              allowRepair: flags["repair"] == true,
              allowPoor: flags["poor"] == true,
              allowReplace: flags["replace"] == true,
              allowNA: flags["notApplicable"] == true,

              imageUrls: imageMap[taskId] ?? [],
              videoUrl: videoMap[taskId],
              audioUrl: audioMap[taskId],
              note: (task["viNote"] ?? "").toString(),
              initialNote: (task["viDescription"] ?? "").toString(),
            );
          }).toList();
        }
      }
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
    if (task["viReplace"] == true) return InspectionStatus.replace;
    if (task["viRepair"] == true) return InspectionStatus.repair;
    if (task["viPoor"] == true) return InspectionStatus.poor;
    if (task["viGood"] == true) return InspectionStatus.good;
    return InspectionStatus.na;
  }
}
