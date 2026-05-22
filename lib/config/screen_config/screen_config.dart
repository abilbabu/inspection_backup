// import 'dart:math';
// import 'package:flutter/material.dart';

// class DeviceTypeUtil {
//   static bool isTablet(BuildContext context) {
//     final mediaQuery = MediaQuery.of(context);
//     final size = mediaQuery.size;
//     final diagonal = sqrt(
//       size.width * size.width + size.height * size.height,
//     ); // Use sqrt here
//     return diagonal > 1100; // Adjust this threshold based on your criteria
//   }
// }

// class ScreenUtil {
//   static ScreenUtil instance = ScreenUtil();

//   ///width of the phone in UI Design , px
//   int width;

//   ///height of the phone in UI Design , px
//   int height;

//   /// allowFontScaling Specifies whether fonts should scale to respect Text Size accessibility settings. The default is false.
//   bool allowFontScaling;

//   static double _pixelRatio = 0;
//   static double _screenWidth = 0;
//   static double _screenHeight = 0;
//   static double _statusBarHeight = 0;
//   static double _bottomBarHeight = 0;
//   static double _textScaleFactor = 0;

//   // change this for different screen size design for particular screen

//   // ScreenUtil.instance =
//   //         ScreenUtil(width: 375, height: 812, allowFontScaling: true)
//   //           ..init(context);
//   // ScreenUtil screenUtil = ScreenUtil.getInstance();

//   ScreenUtil({
//     this.width = 375,
//     this.height = 812,
//     this.allowFontScaling = false,
//   });

//   // use this method to get instance of this class
//   static ScreenUtil getInstance() {
//     return instance;
//   }

//   void init(BuildContext context) {
//     var mediaQuery = MediaQuery.of(context);
//     _pixelRatio = mediaQuery.devicePixelRatio;
//     _screenWidth = mediaQuery.size.width;
//     _screenHeight = mediaQuery.size.height;
//     _statusBarHeight = mediaQuery.padding.top;
//     _bottomBarHeight = mediaQuery.padding.bottom;
//     // ignore: deprecated_member_use
//     _textScaleFactor = mediaQuery.textScaleFactor;
//   }

//   /// The number of font pixels for each logical pixel.
//   double get textScaleFactor => _textScaleFactor;

//   /// The size of the media in logical pixels (e.g, the size of the screen).
//   double get pixelRatio => _pixelRatio;

//   /// The horizontal extent of this size.
//   double get screenWidth => _screenWidth;

//   ///The vertical extent of this size. dp
//   double get screenHeight => _screenHeight;

//   /// The vertical extent of this size. px
//   double get screenWidthPx => _screenWidth * _pixelRatio;

//   /// The vertical extent of this size. px
//   double get screenHeightPx => _screenHeight * _pixelRatio;

//   /// The offset from the top. px
//   double get statusBarHeightPx => _statusBarHeight * _pixelRatio;

//   /// The offset from the top
//   double get statusBarHeight => _statusBarHeight;

//   /// The offset from the bottom. px
//   double get bottomBarHeightPx => _bottomBarHeight * _pixelRatio;

//   /// The offset from the bottom
//   double get bottomBarHeight => _bottomBarHeight;

//   /// The ratio of the actual dp to the design draft px
//   double get scaleWidth => _screenWidth / instance.width;

//   double get scaleHeight => _screenHeight / instance.height;

//   double get scaleText => min(scaleWidth, scaleHeight);

//   /// Adapted to the device width of the UI Design.
//   /// Height can also be adapted according to this to ensure no deformation ,
//   /// if you want a square
//   double setWidth(int width) => width * scaleWidth;

//   /// Highly adaptable to the device according to UI Design
//   /// It is recommended to use this method to achieve a high degree of adaptation
//   /// when it is found that one screen in the UI design
//   /// does not match the current style effect, or if there is a difference in shape.
//   double setHeight(int height) => height * scaleHeight;

//   ///Adapt according to the larger of width or height
//   double radius(int r) => r * max(scaleWidth, scaleHeight) as double;

//   ///Font size adaptation method
//   ///- [fontSize] The size of the font on the UI design, in px.
//   double setSp(int fontSize, {bool allowFontScalingSelf = false}) =>
//       (allowFontScaling
//       ? (fontSize * scaleText) * _textScaleFactor
//       : (fontSize * scaleText));
// }
