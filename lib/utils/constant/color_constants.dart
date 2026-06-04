import 'package:flutter/material.dart';

class ColorConstants {
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Colors.black;
  static const Color transparentColor = Colors.transparent;
  static const Color syanColor = Color(0xFF00BFA6);
  static const Color holdorangeColor = Color(0xffFF1E00);
  static const Color lightblueColor = Color(0xFF0066A6);
  static const Color lightorangeColor = Color(0xFFFFAB40);
  static const Color greyColor = Color(0xff999999);
  static const Color lightblackColor = Color(0xff333333);
  static const Color activecolor = Color(0xff707070);
  static const Color borderGreyColor = Color(0xffCCCCCC);
  static const Color orangecolor = Color(0xFFFF9800);
  static const Color warningcolor = Color(0xfff7941e);
  static const Color toastgrey = Color(0xff414042);
  static const Color errorcolor = Color(0xffff0000);
  static const Color lightGreyColor = Color(0xffEFEFEF);
  static const Color containergreycolor = Color(0xffF1F1F1);
  static const Color dividergreycolor = Color(0xffE2E2E2);
  static const Color greenColor = Color(0xFF359238);
  static const Color bottamNavBarButton = Color(0xFF067AFF);
  static const Color textBlueColor = Color(0xFF035BC0);
  static const Color signoutButton = Color(0xFF4D9EB7);
  static const Color textcolor2 = Color(0xFF2b658c);
  static final Color boxColor = const Color(0xffEFEFEF);

  static const List<BoxShadow> boxShadow = [
    BoxShadow(
      color: Color(0x3F000000),
      blurRadius: 10,
      spreadRadius: 5,
      offset: Offset(5, 5),
    ),
  ];

  static const List<BoxShadow> dashboardboxShadow = [
    BoxShadow(
      color: Color(0x3F000000),
      blurRadius: 5,
      spreadRadius: 1,
      offset: Offset(2, 2),
    ),
  ];
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientColor = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromARGB(255, 241, 242, 242),
      ColorConstants.lightblueColor,
      ColorConstants.syanColor,
      ColorConstants.syanColor,
    ],
    stops: [0.0, 0.2, 8.0, 0.0],
  );

  static LinearGradient containergradientColor = LinearGradient(
    colors: [const Color(0xFFFFFFFF), const Color(0xFF858585)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    // stops: [0.0, 0.0],
  );

  static LinearGradient tabgradientColor = LinearGradient(
    colors: [const Color(0xFFFFFFFF), const Color(0xFFEDFFFD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    // stops: [0.0, 0.0],
  );
}
