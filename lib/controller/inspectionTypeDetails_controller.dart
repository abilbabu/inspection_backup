import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/inspectionFormController.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/model/inspectionTaskModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectionTypeDetailsController extends ChangeNotifier {
  String inspectionFormName = "";
  List<Map<String, dynamic>> taskMapping = [];
  List<Map<String, dynamic>> taskCategoryList = [];
  Map<int, List<Map<dynamic, dynamic>>> groupedTasks = {};
  List<dynamic> allTaskComponents = [];
  List<dynamic> filteredTaskComponents = [];
  List<dynamic> suggestionTaskComponents = [];

  bool isLoading = false;
  bool isSearching = false;

  Timer? _debounceTimer;
  String _lastQuery = '';

  void searchTaskComponents(String query) {
    _debounceTimer?.cancel();
    if (query.trim() == _lastQuery) return;
    if (query.trim().isEmpty) {
      _lastQuery = '';
      filteredTaskComponents = List.from(allTaskComponents);
      isSearching = false;
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      await _fetchSearchResults(query.trim());
    });
  }

  Future<void> _fetchSearchResults(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      if (userToken == null || userToken.isEmpty) {
        isSearching = false;
        notifyListeners();
        return;
      }
      final uri = Uri.parse(
        ApiServices.componentSearch,
      ).replace(queryParameters: {"query": query});
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      final result = jsonDecode(response.body);
      final data = result["data"];
      if (data != null && result["statusCode"] == 200) {
        _lastQuery = query;
        filteredTaskComponents = List.from(data);
      }
    } catch (e) {
      debugPrint("❌ Search fetch error: $e");
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void selectSuggestion(String name) {
    filteredTaskComponents = allTaskComponents.where((item) {
      return (item["itcName"] ?? "").toString().toLowerCase().contains(
        name.toLowerCase(),
      );
    }).toList();
    suggestionTaskComponents = [];
    notifyListeners();
  }

  Future<ApiResponse> getInspectionDetailsById(int jobId) async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      if (userToken == null || userToken.isEmpty) {
        return ApiResponse(success: false, status: "Unauthorized");
      }
      final response = await http.post(
        Uri.parse(ApiServices.getInspectionDetailsById),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({"jobId": jobId}),
      );
      final result = jsonDecode(response.body);
      final data = result["data"];
      if (data == null) {
        return ApiResponse(
          success: false,
          statusCode: result["statusCode"],
          status: "No data",
          timeStamp: result["timeStamp"],
        );
      }
      return ApiResponse(
        success: result["statusCode"] == 200,
        statusCode: result["statusCode"],
        timeStamp: result["timeStamp"],
        status: result["status"],
        data: data,
      );
    } catch (e) {
      return ApiResponse(success: false, status: "Unexpected Error");
    } finally {
      notifyListeners();
    }
  }

  void applySavedCustomInspection(
    Map<String, dynamic> data,
    InspectionFormController formController,
  ) {
    final inspections = data["inspections"] ?? [];
    for (final inspection in inspections) {
      final completedTasks = inspection["completedTasks"] ?? [];
      for (final savedTask in completedTasks) {
        final int taskId = savedTask["viTaskId"];
        final component = allTaskComponents.firstWhere(
          (e) => e["itcId"] == taskId,
          orElse: () => null,
        );
        if (component != null) {
          formController.updateTask(
            InspectionTaskData(
              jobId: data["jobId"],
              taskId: taskId,
              formId: inspection["inspectionFormId"],
              condition: savedTask["viGood"] == true
                  ? "Good"
                  : savedTask["viRepair"] == true
                  ? "Repair"
                  : savedTask["viReplace"] == true
                  ? "Replace"
                  : savedTask["viPoor"] == true
                  ? "Poor"
                  : savedTask["viNotApplicable"] == true
                  ? "N/A"
                  : null,
              note: savedTask["viNote"] ?? "",
              description: savedTask["viDescription"] ?? "",
              inserted: true,
              isSaved: true,
            ),
          );
          formController.markTaskSaved(taskId);
        }
      }
    }
    notifyListeners();
  }

  Future<ApiResponse> getComponentList() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      if (userToken == null || userToken.isEmpty) {
        return ApiResponse(success: false, status: "Unauthorized");
      }

      final response = await http.get(
        Uri.parse(ApiServices.componentList),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      final result = jsonDecode(response.body);
      final data = result["data"];
      debugPrint(
        "📦 getComponentList → statusCode: ${result["statusCode"]}, count: ${data?.length}",
      );
      if (data == null) {
        return ApiResponse(
          success: false,
          statusCode: result["statusCode"],
          status: "No data",
          timeStamp: result["timeStamp"],
        );
      }
      allTaskComponents = List.from(data);
      filteredTaskComponents = List.from(data);
      return ApiResponse(
        success: result["statusCode"] == 200,
        statusCode: result["statusCode"],
        timeStamp: result["timeStamp"],
        status: result["status"],
        data: data,
      );
    } catch (e) {
      debugPrint("❌ getComponentList error: $e");
      return ApiResponse(success: false, status: "Unexpected Error");
    } finally {
      notifyListeners();
    }
  }

  Future<bool> changeStatus({required int jobId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");
      final response = await http.post(
        Uri.parse(ApiServices.statusChange),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "jobId": jobId,
          "status": 6,
          "vimIfMasterId": "",
          "assigneeId": "",
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void applySavedInspection(
    Map<String, dynamic> data,
    InspectionFormController formController,
  ) {
    final inspections = data["inspections"] ?? [];
    if (inspections.isEmpty) {
      return;
    }
    for (final inspection in inspections) {
      final completedTasks = inspection["completedTasks"] ?? [];
      for (final savedTask in completedTasks) {
        final int savedTaskId = savedTask["viTaskId"];
        final List attachments = savedTask["attachments"] ?? [];
        String? videoUrl;
        final List<String> imageUrl = [];
        String? audioUrl;
        for (final a in attachments) {
          if (a["type"] == 0) {
            imageUrl.add(a["url"]);
          } else if (a["type"] == 1) {
            audioUrl = a["url"];
          } else if (a["type"] == 2) {
            videoUrl = a["url"];
          }
        }
        groupedTasks.forEach((categoryId, taskList) {
          for (final task in taskList) {
            final components = task["components"];
            if (components == null) continue;
            if (components["itcId"] == savedTaskId) {
              components["viGood"] = savedTask["viGood"];
              components["viRepair"] = savedTask["viRepair"];
              components["viReplace"] = savedTask["viReplace"];
              components["viPoor"] = savedTask["viPoor"];
              components["viNotApplicable"] =
                  savedTask["viNotApplicable"] ?? false;
              components["viNote"] = savedTask["viNote"];
              components["viDescription"] = savedTask["viDescription"];
              components["attachments"] = attachments;
              formController.updateTask(
                InspectionTaskData(
                  categoryId: categoryId,
                  jobId: data["jobId"],
                  taskId: savedTaskId,
                  formId: inspection["inspectionFormId"],
                  condition: savedTask["viGood"] == true
                      ? "Good"
                      : savedTask["viRepair"] == true
                      ? "Repair"
                      : savedTask["viReplace"] == true
                      ? "Replace"
                      : savedTask["viPoor"] == true
                      ? "Poor"
                      : savedTask["viNotApplicable"] == true
                      ? "N/A"
                      : null,
                  note: savedTask["viNote"] ?? "",
                  description: savedTask["viDescription"] ?? "",
                  imageUrls: imageUrl.isNotEmpty ? imageUrl : null,
                  audioUrl: audioUrl,
                  videoUrl: videoUrl,
                  inserted: true,
                  isSaved: true,
                ),
              );
              formController.markTaskSaved(savedTaskId);
              formController.setTaskReadOnly(savedTaskId, true);
            }
          }
        });
      }
    }
    notifyListeners();
  }

  Future<ApiResponse> postInspectionTypeDetails(int inspectionFormId) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("userToken");
      final url = Uri.parse(ApiServices.postInspectionFormById);
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"inspectionFormId": inspectionFormId}),
      );
      final responseBody = jsonDecode(response.body);
      final data = responseBody["data"];
      inspectionFormName = data?["inspectionFormName"] ?? "";
      final taskMappings = List<Map<String, dynamic>>.from(
        data?["componentMappings"] ?? [],
      );
      final categoryIds = taskMappings
          .map((t) => t["inspectionFormComponentCategoryId"])
          .whereType<int>()
          .toSet();
      groupedTasks.clear();
      final taskCategoryList = await getTaskCategoryList();
      for (final categoryId in categoryIds) {
        final categoryMeta = taskCategoryList.firstWhere(
          (c) => c['taskCategoryId'] == categoryId,
          orElse: () => {},
        );
        final mappingsForCategory = taskMappings.where(
          (m) => m["inspectionFormComponentCategoryId"] == categoryId,
        );
        final List<Map<String, dynamic>> mergedTasks = [];
        for (final mapping in mappingsForCategory) {
          final components = Map<String, dynamic>.from(
            mapping["taskComponent"] ?? {},
          );
          if (components.isEmpty) {
            continue;
          }
          final merged = <String, dynamic>{
            "categoryId": categoryId,
            "categoryName":
                categoryMeta['taskCategoryName'] ?? 'Category $categoryId',
            "components": components,
          };
          mergedTasks.add(merged);
        }
        groupedTasks[categoryId] = mergedTasks;
      }
      isLoading = false;
      notifyListeners();
      return ApiResponse(success: true, status: "Success");
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return ApiResponse(success: false, status: e.toString());
    }
  }

  Future<Map<String, dynamic>?> fetchCategoryDetails(int categoryId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('userToken');
    final url = Uri.parse(ApiServices.postInspectionCategoryDetailsField);
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"taskCategoryId": categoryId}),
    );
    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final data = raw['data'];
      if (data is List && data.isNotEmpty) {
        return {"taskList": data};
      } else {
        return {"taskList": []};
      }
    }
    return null;
  }

  void groupTasksDynamically() {
    groupedTasks.clear();
    for (var task in taskMapping) {
      int categoryId = task["inspectionFormComponentCategoryId"];
      if (!groupedTasks.containsKey(categoryId)) {
        groupedTasks[categoryId] = [];
      }
      groupedTasks[categoryId]!.add(task);
    }
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getTaskCategoryList() async {
    final url = Uri.parse(ApiServices.taskCategoryList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        taskCategoryList = List<Map<String, dynamic>>.from(res['data']);
        notifyListeners();
        return taskCategoryList;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("EXCEPTION in getTaskCategoryList(): $e");
      return [];
    }
  }
}
