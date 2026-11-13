import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationController with ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isSuccess = false;
  bool _passwordVisible = false;
  bool get passwordVisible => _passwordVisible;
  bool isDepartmentLoaded = false;
  int currentIndex = 0;
  int userDepartment = 0;
  String userRoleName = "";
  int userRoleLevel = 0;
  List<Map<String, dynamic>> _userFeaturesMappings = [];
  List<Map<String, dynamic>> get userFeaturesMappings => _userFeaturesMappings;

  bool get isAdmin {
    if (userRoleLevel == 1) return true;
    final name = userRoleName.toUpperCase();
    if (name.contains("ADMIN")) return true;
    return userDepartment == 0 || userDepartment == 1;
  }

  bool hasPermission(int featureId, {String action = 'view'}) {
    if (isAdmin) return true;
    for (final mapping in _userFeaturesMappings) {
      final detail = mapping['userFeatureDetail'];
      int? id;
      if (detail is Map) {
        id = int.tryParse(detail['featureId']?.toString() ?? '');
      } else if (mapping['featureId'] != null) {
        id = int.tryParse(mapping['featureId']?.toString() ?? '');
      }
      if (id == featureId) {
        dynamic val;
        switch (action.toLowerCase()) {
          case 'add':
            val = mapping['userFeatureAddAction'] ?? mapping['featureAddFlag'];
            break;
          case 'edit':
            val = mapping['userFeatureEditAction'] ?? mapping['featureEditFlag'];
            break;
          case 'delete':
          case 'remove':
            val = mapping['userFeatureDeleteAction'] ?? mapping['featureRemoveFlag'];
            break;
          case 'export':
            val = mapping['userFeatureExportAction'] ?? mapping['featureExportFlag'];
            break;
          case 'approve':
            val = mapping['userFeatureApproveAction'] ?? mapping['featureApproveFlag'];
            break;
          case 'view':
          default:
            val = mapping['userFeatureViewAction'] ?? mapping['featureViewFlag'];
            break;
        }
        return val == true || val == 1 || val == 'true' || val == '1';
      }
    }
    return false;
  }

  bool get canViewGeneralInspection => hasPermission(4, action: 'view');
  bool get canAddGeneralInspection => hasPermission(4, action: 'add');
  bool get canViewQuickInspection => hasPermission(5, action: 'view');
  bool get canAddQuickInspection => hasPermission(5, action: 'add');
  bool get canViewJobCardInspection => hasPermission(6, action: 'view');
  bool get canViewCreationTimeAnalysis => hasPermission(7, action: 'view');
  bool get canViewQuotation => hasPermission(9, action: 'view');
  bool get canViewJobCardList => hasPermission(11, action: 'view');

  bool get canViewInspectionMode =>
      canViewGeneralInspection || canViewQuickInspection || canViewJobCardInspection;

  bool get isSupervisor {
    if (isAdmin) return false;
    final name = userRoleName.toUpperCase();
    if (name.contains("SUPERVISOR")) return true;
    return userDepartment == 2;
  }

  bool get isServiceAdvisor {
    if (isAdmin) return false;
    final name = userRoleName.toUpperCase();
    if (name.contains("ADVISOR") || name.contains("SERVICE")) return true;
    return userDepartment == 3;
  }

  bool get isTechnician {
    if (isAdmin) return false;
    final name = userRoleName.toUpperCase();
    if (name.contains("TECHNICIAN") || name.contains("TECH")) return true;
    return userDepartment == 4;
  }

  bool get isJobController {
    if (isAdmin) return false;
    final name = userRoleName.toUpperCase();
    if (name.contains("CONTROLLER")) return true;
    return userDepartment == 5;
  }

  bool get canAssignInspection => isAdmin || isSupervisor || isJobController;

  /// Special Exception (Section 3): Department-based access for Technician Report
  bool get canViewTechnicianReportDept => userDepartment == 0 || userDepartment == 1 || userDepartment == 2;
  bool get canVerifyTechnicianReportDept => userDepartment == 0 || userDepartment == 1 || userDepartment == 3;

  /// LOAD SAVED DEPARTMENT
  Future<void> loadUserDepartment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userDepartment =
        int.tryParse(prefs.getString("userDepartment") ?? "0") ?? 0;
    userRoleName = prefs.getString("userRole") ?? "";
    userRoleLevel = prefs.getInt("userRoleLevel") ?? 0;
    final permStr = prefs.getString("userPermissions");
    if (permStr != null && permStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(permStr);
        if (decoded is List) {
          _userFeaturesMappings = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (e) {
        log("Error loading permissions: $e");
        _userFeaturesMappings = [];
      }
    } else {
      _userFeaturesMappings = [];
    }
    isDepartmentLoaded = true;
    // log("Loaded Department : $userDepartment");
    notifyListeners();
    refreshPermissions();
  }

  Future<void> refreshPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail");
      final password = prefs.getString("userPassword");
      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        return;
      }
      final url = Uri.parse(ApiServices.loginUrl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userEmail": email,
          "userPassword": password,
        }),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["statusCode"] == 200) {
          final rawMappings = body["data"]?["userFeaturesMappings"];
          if (rawMappings is List) {
            _userFeaturesMappings = rawMappings
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            await prefs.setString("userPermissions", jsonEncode(rawMappings));
            notifyListeners();
          }
        }
      }
    } catch (e) {
      log("Silent permission refresh failed: $e");
    }
  }

  void setIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  Future<bool> postAuthUser() async {
    isSuccess = false;
    isLoading = true;
    notifyListeners();
    final url = Uri.parse(ApiServices.loginUrl);
    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userEmail": emailController.text.trim(),
          "userPassword": passwordController.text.trim(),
        }),
      );

      // log(response.body);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body["statusCode"] == 200) {
        String userId = body["data"]["userId"].toString();
        String userName = body["data"]["userName"] ?? "";
        String userEmail = body["data"]["userEmail"] ?? "";
        String userLoginId = body["data"]["userLoginId"] ?? "";
        String userPhone = body["data"]["userPhone"] ?? "";
        String userPhoneCode = body["data"]["userPhoneCode"] ?? "";
        String userToken = body["data"]["userToken"] ?? "";
        String userRole = body["data"]["userRole"]?["roleName"] ?? "";
        int roleLevel = int.tryParse((body["data"]["userRole"]?["roleLevelFlag"] ?? "0").toString()) ?? 0;
        String userPassword = passwordController.text.trim();
        String department = (body["data"]["userDepartment"] ?? "").toString();

        userDepartment = int.tryParse(department) ?? 0;
        userRoleName = userRole;
        userRoleLevel = roleLevel;
        // log("Controller Department : $userDepartment");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("userId", userId);
        await prefs.setString("userName", userName);
        await prefs.setString("userEmail", userEmail);
        await prefs.setString("userLoginId", userLoginId);
        await prefs.setString("userPassword", userPassword);
        await prefs.setString("userToken", userToken);
        await prefs.setString("userRole", userRole);
        await prefs.setInt("userRoleLevel", roleLevel);
        await prefs.setString("userPhone", userPhone);
        await prefs.setString("userPhoneCode", userPhoneCode);
        await prefs.setString("userDepartment", department);
        final rawMappings = body["data"]?["userFeaturesMappings"];
        if (rawMappings is List) {
          _userFeaturesMappings = rawMappings
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          await prefs.setString("userPermissions", jsonEncode(rawMappings));
        } else {
          _userFeaturesMappings = [];
          await prefs.remove("userPermissions");
        }
        // log("Saved Department : ${prefs.getString("userDepartment")}");
        isSuccess = true;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      log("Login Error : $e");
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emailController.clear();
    passwordController.clear();
    currentIndex = 0;
    userDepartment = 0;
    userRoleName = "";
    userRoleLevel = 0;
    _userFeaturesMappings = [];
    isLoading = false;
    isSuccess = false;
    notifyListeners();
  }

  void getPasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }
}
