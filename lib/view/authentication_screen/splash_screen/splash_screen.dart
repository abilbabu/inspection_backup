import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/constant/image_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((_) async {
      // ignore: use_build_context_synchronously
      // context.go("/login"); // login screen push
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

      if (!mounted) return;

      if (isLoggedIn) {
        context.go("/home");
      } else {
        context.go("/login");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ColorConstants.containergradientColor,
        ),
        child: Center(
          child: Image.asset(
            height: 300,
            width: 250,
            ImageConstants.Splachscreenlogo,
          ),
        ),
      ),
    );
  }
}
