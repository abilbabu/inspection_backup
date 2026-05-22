import 'package:flutter/material.dart';
import 'package:inspection/controller/authentication_%20controller.dart';
import 'package:inspection/controller/cardiagram_controller.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/controller/inspectionCard_controller.dart';
import 'package:inspection/controller/inspectionFullScreenVideo_controller.dart';
import 'package:inspection/controller/inspectionReportshare_controller.dart';
import 'package:inspection/controller/inspectionScreenImage_controller.dart';
import 'package:inspection/controller/inspectionSummaryPage_controller.dart';
import 'package:inspection/controller/inspectionTypeDetails_controller.dart';
import 'package:inspection/controller/inspectionDetails_controller.dart';
import 'package:inspection/controller/basicInspectionReport_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/controller/vehicleDetails_controller.dart';
import 'package:inspection/controller/vehicleEssential_controller.dart';
import 'package:inspection/main.dart';
import 'package:provider/provider.dart';

class MultiProviderAccess extends StatelessWidget {
  const MultiProviderAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthenticationController()),
        ChangeNotifierProvider(create: (context) => VehicleDetailsController()),
        ChangeNotifierProvider(
          create: (context) => CustomerDetailsController(),
        ),
        ChangeNotifierProvider(create: (context) => JobcarddetailsController()),
        ChangeNotifierProvider(
          create: (context) => InspectionDetailsController(),
        ),
        ChangeNotifierProvider(
          create: (context) => InspectionTypeDetailsController(),
        ),
        ChangeNotifierProvider(
          create: (context) => VehicleessentialController(),
        ),
        ChangeNotifierProvider(
          create: (context) => BasicInspectionReportController(),
        ),
        ChangeNotifierProvider(
          create: (context) => InspectionsummarypageController(),
        ),
        ChangeNotifierProvider(create: (context) => CardiagramController()),
        ChangeNotifierProvider(
          create: (context) => InspectionscreenimageController(),
        ),
        ChangeNotifierProvider(create: (context) => InspectioncardController()),
        ChangeNotifierProvider(create: (context) => HomescreenController()),
        ChangeNotifierProvider(
          create: (context) => InspectionreportshareController(),
        ),
        ChangeNotifierProvider(
          create: (context) => InspectionFullscreenVideoController(),
        ),
      ],
      child: const MyApp(),
    );
  }
}
