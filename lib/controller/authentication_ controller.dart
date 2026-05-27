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

  /// LOAD SAVED DEPARTMENT
  Future<void> loadUserDepartment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userDepartment =
        int.tryParse(prefs.getString("userDepartment") ?? "0") ?? 0;
    isDepartmentLoaded = true;
    // log("Loaded Department : $userDepartment");
    notifyListeners();
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
        String userName = body["data"]["userName"];
        String userEmail = body["data"]["userEmail"];
        String userPhone = body["data"]["userPhone"] ?? "";
        String userPhoneCode = body["data"]["userPhoneCode"] ?? "";
        String userToken = body["data"]["userToken"] ?? "";
        String userRole = body["data"]["userRole"]["roleName"] ?? "";
        String userPassword = passwordController.text.trim();
        String department = body["data"]["userDepartment"].toString();

        userDepartment = int.tryParse(department) ?? 0;
        // log("Controller Department : $userDepartment");

        SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setBool("isLoggedIn", true);
        await prefs.setString("userId", userId);
        await prefs.setString("userName", userName);
        await prefs.setString("userEmail", userEmail);
        await prefs.setString("userPassword", userPassword);
        await prefs.setString("userToken", userToken);
        await prefs.setString("userRole", userRole);
        await prefs.setString("userPhone", userPhone);
        await prefs.setString("userPhoneCode", userPhoneCode);
        await prefs.setString("userDepartment", department);
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
    isLoading = false;
    isSuccess = false;
    notifyListeners();
  }

  void getPasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }
}
