import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/authentication_%20controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/constant/image_constants.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
    if (!mounted) return;
    if (isLoggedIn) {
      context.go("/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Consumer<AuthenticationController>(
              builder: (context, auth, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 220),
                  Center(
                    child: Image.asset(ImageConstants.loginlogo, height: 70),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Please log in to access your account.",
                    style: ApptextstyleConstants.lightText(
                      fontSize: 15,
                      color: ColorConstants.blackColor,
                    ),
                  ),
                  SizedBox(height: 25),
                  TextFormField(
                    controller: auth.emailController,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: ApptextstyleConstants.extraLightText(
                        fontSize: 14,
                        color: ColorConstants.blackColor,
                      ),
                      floatingLabelStyle: TextStyle(
                        color: ColorConstants.blackColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 15,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.blackColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.blackColor,
                          width: 1.2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1.2,
                        ),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: auth.passwordController,
                    obscureText: !auth.passwordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: ApptextstyleConstants.extraLightText(
                        fontSize: 14,
                        color: ColorConstants.blackColor,
                      ),
                      floatingLabelStyle: TextStyle(
                        color: ColorConstants.blackColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          color: ColorConstants.blackColor,
                          auth.passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: auth.getPasswordVisibility,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.blackColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.blackColor,
                          width: 1.2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1.2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButtonWidget(
                      text: auth.isLoading
                          ? "Please wait..."
                          : auth.isSuccess
                          ? "LOGIN IS COMPLETED"
                          : "LOGIN",
                      textSize: 16,
                      isDisabled: auth.isLoading || auth.isSuccess,
                      showLoader: auth.isLoading,
                      onPressed: () async {
                        if (!mounted) return;
                        if (_formKey.currentState?.validate() ?? false) {
                          bool success = await auth.postAuthUser();
                          log("Login Success : $success");

                          if (success) {
                            context.go("/home");
                          } else {
                            ScaffoldMessenger.of(context)
                              ..removeCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Login failed. Please check your credentials.",
                                    style: TextStyle(
                                      color: ColorConstants.whiteColor,
                                    ),
                                  ),
                                  backgroundColor: ColorConstants.errorcolor,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                          }
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
