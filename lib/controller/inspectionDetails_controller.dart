import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectionDetailsController extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> inspectiontypesList = [];

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
}
