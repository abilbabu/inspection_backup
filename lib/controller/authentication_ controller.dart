import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationController with ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isSuccess = false;

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
    isLoading = false;
    isSuccess = false;
    notifyListeners();
  }

  bool _passwordVisible = false;
  bool get passwordVisible => _passwordVisible;
  void getPasswordVisibility() {
    _passwordVisible = !_passwordVisible;
    notifyListeners();
  }

  int currentIndex = 0;
  void setIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }
}
