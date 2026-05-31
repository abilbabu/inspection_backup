import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectionDetailsController extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> inspectiontypesList = [];
  List<Map<String, dynamic>> technicianList = [];
  String assignedTechnicianName = "";
  int? assignedTechnicianId;
  bool isTechnicianLoading = false;
  bool technicianAssigned = false;
  int? assignedInspectionType;
  String selectedInspectionName = "";
  int? jobTechnicianId;
  int? jobSuperVisorId;
  int? loginTechnicianId;


  Future<void> loadLoginTechnicianId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final value = prefs.get("userId");

    loginTechnicianId = int.tryParse(value.toString());

    notifyListeners();
  }

  Future<void> getTechnicianList() async {
    try {
      isTechnicianLoading = true;
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');

      final response = await http.post(
        Uri.parse(ApiServices.allTechnicianList),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        technicianList = List<Map<String, dynamic>>.from(decoded['data']);
      }
    } catch (e) {
      debugPrint("Error : $e");
    } finally {
      isTechnicianLoading = false;
      notifyListeners();
    }
  }

  Future<void> getInspectionTypes() async {
    isLoading = true;
    notifyListeners();
    final url = Uri.parse(ApiServices.inspectionFormList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      var response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        inspectiontypesList = List<Map<String, dynamic>>.from(res['data']);
      } else {
        inspectiontypesList = [];
      }
    } catch (e) {
      print("Brand list error: $e");
      inspectiontypesList = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> searchInspectionForms(String name) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse(ApiServices.inspectionFormSearch),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": name}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        inspectiontypesList = List<Map<String, dynamic>>.from(
          result['data'] ?? [],
        );
      } else {
        inspectiontypesList = [];
      }
    } catch (e) {
      print("Search error: $e");
      inspectiontypesList = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> assignTechnician({
    required int jobId,
    required int assigneeId,
    required int supervisorId,
    required String technicianName,
    int? formMasterId,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? userToken = prefs.getString('userToken');

      Map<String, dynamic> payload = {
        "jobId": jobId,
        "status": 5,
        "assignedBy": assigneeId,
        "vimIfMasterId": formMasterId ?? "",
        "vimInspectionType": formMasterId != null ? 1 : 2,
      };

      // log("Payload : ${jsonEncode(payload)}");

      final response = await http.post(
        Uri.parse(ApiServices.assignTechnician),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode(payload),
      );

      // log("Status Code : ${response.statusCode}");
      // log("Response : ${response.body}");

      if (response.statusCode == 200) {
        technicianAssigned = true;

        assignedTechnicianName = technicianName;

        assignedTechnicianId = assigneeId;

        jobTechnicianId = assigneeId;

        jobSuperVisorId = supervisorId;

        notifyListeners();

        return true;
      }

      return false;
    } catch (e) {
      log("Assign Error : $e");
      return false;
    }
  }
}
