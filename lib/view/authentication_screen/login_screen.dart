import 'package:inspection/utils/custom_toast.dart';
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

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _laabsIdRegex = RegExp(r'^[a-zA-Z0-9._-]+$');

  @override
  void initState() {
    super.initState();
    _checkLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthenticationController>().loadLastLoginType();
    });
  }

  Widget _loginTypeOption(AuthenticationController auth, String type, String label, IconData icon) {
    final selected = auth.loginType == type;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: auth.isLoading
              ? null
              : () {
                  auth.setLoginType(type);
                  _formKey.currentState?.reset();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? ColorConstants.blackColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : ColorConstants.blackColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: ApptextstyleConstants.lightText(
                      fontSize: 13,
                      color: selected ? Colors.white : ColorConstants.blackColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ColorConstants.blackColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        _loginTypeOption(auth, AuthenticationController.loginTypeEmail,
                            "Login Using Email", Icons.email_outlined),
                        const SizedBox(width: 4),
                        _loginTypeOption(auth, AuthenticationController.loginTypeLaabs,
                            "Login Using LAABS ID", Icons.badge_outlined),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: ValueKey("identifier_${auth.loginType}"),
                    controller: auth.emailController,
                    keyboardType: auth.isLaabsLogin
                        ? TextInputType.text
                        : TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: auth.isLaabsLogin ? "LAABS ID" : "Email Address",
                      hintText: auth.isLaabsLogin ? "Enter LAABS ID" : "Enter Email Address",
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
                      final v = value?.trim() ?? '';
                      if (auth.isLaabsLogin) {
                        if (v.isEmpty) return 'Please enter your LAABS ID';
                        if (v.length > 50 || !_laabsIdRegex.hasMatch(v)) {
                          return 'Enter a valid LAABS ID (letters, numbers, ".", "_", "-")';
                        }
                      } else {
                        if (v.isEmpty) return 'Please enter your email address';
                        if (v.length > 100 || !_emailRegex.hasMatch(v)) {
                          return 'Enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    key: ValueKey("password_${auth.loginType}"),
                    controller: auth.passwordController,
                    obscureText: !auth.passwordVisible,
                    decoration: InputDecoration(
                      labelText: auth.isLaabsLogin ? "LAABS Password" : "Email Password",
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
                        return auth.isLaabsLogin
                            ? 'Please enter your LAABS password'
                            : 'Please enter your email password';
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
                          if (!context.mounted) return;

                          if (success) {
                            context.go("/home");
                          } else {
                            CustomToast.showError(
                              context,
                              auth.lastLoginError == "User account is not active"
                                  ? "Your account is not active. Please contact the administrator."
                                  : auth.isLaabsLogin
                                      ? "Login failed. Please check your LAABS ID and LAABS password."
                                      : "Login failed. Please check your email and email password.",
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
