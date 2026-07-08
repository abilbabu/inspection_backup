import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionFormController.dart';
import 'package:inspection/controller/inspectionTypeDetails_controller.dart';
import 'package:inspection/view/authentication_screen/login_screen.dart';
import 'package:inspection/view/basicInspection_screen/basicInsp_screen.dart';
import 'package:inspection/view/basicInspection_screen/basicinspection_previw.dart';
import 'package:inspection/view/basicInspection_screen/vehicleEssential_screen.dart';
import 'package:inspection/view/bottomnavbar_screen/bottomnavbar_screen.dart';
import 'package:inspection/view/global_widgets/fullScreenImage.dart';
import 'package:inspection/view/global_widgets/gallery_view.dart';
import 'package:inspection/view/history_screen/history_screen.dart';
import 'package:inspection/view/home_screen/home_screen.dart';
import 'package:inspection/view/home_screen/technician_dashboard.dart';
import 'package:inspection/view/home_screen/job_controller_dashboard.dart';
import 'package:inspection/view/home_screen/supervisor_dashboard.dart';
import 'package:inspection/controller/authentication_%20controller.dart';
import 'package:inspection/view/home_screen/widget/JobCardDetails.dart';
import 'package:inspection/view/home_screen/widget/allJobCardView.dart';
import 'package:inspection/view/home_screen/widget/allPendingInspection.dart';
import 'package:inspection/view/home_screen/widget/customerDetails.dart';
import 'package:inspection/view/inspection_screen/inspectionDetails.dart';
import 'package:inspection/view/basicInspection_screen/basicInspectionReport.dart';
import 'package:inspection/view/home_screen/widget/vehicleDetails.dart';
import 'package:inspection/view/inspection_screen/inspection_type_details.dart';
import 'package:inspection/view/inspection_screen/inspection_summary_page.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_fullscreenvideo.dart';
import 'package:inspection/view/inspection_screen/reassigned_details_page.dart';
import 'package:inspection/view/jobcard/component_list.dart';
import 'package:inspection/view/quotation_screen/quotation_details.dart';
import 'package:inspection/view/quotation_screen/quotation_screen.dart';
import 'package:inspection/view/settings_screen/settings_screen.dart';
import 'package:inspection/view/authentication_screen/splash_screen/splash_screen.dart';
import 'package:inspection/view/settings_screen/widgets/profile_screen.dart';
import 'package:provider/provider.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'Splash Screen',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),

    GoRoute(
      path: '/login',
      name: 'Login Screen',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),

    ShellRoute(
      builder: (context, state, child) => BottomnavbarScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            return Consumer<AuthenticationController>(
              builder: (context, authCtrl, child) {
                if (!authCtrl.isDepartmentLoaded) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (authCtrl.userDepartment == 4) {
                  return const TechnicianDashboard();
                }
                if (authCtrl.userDepartment == 5) {
                  return const JobControllerDashboard();
                }
                if (authCtrl.userDepartment == 2) {
                  return const SupervisorDashboard();
                }
                return const HomeScreen();
              },
            );
          },
        ),
        GoRoute(
          path: '/quotation',
          builder: (context, state) => const QuotationListPage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreenList(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),

    GoRoute(
      path: '/vehicledetails',
      name: 'Vehicle Details',
      builder: (BuildContext context, GoRouterState state) {
        return VehicleDetails();
      },
    ),

    GoRoute(
      path: '/customerdetails',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return Customerdetails(
          data: extra,
          initialMobileNumber: extra?["mobileNumber"],
          initialCountryCode: extra?["countryCode"],
          make: extra?["make"] ?? "",
          model: extra?["model"] ?? "",
          year: extra?["year"] ?? "",
          engineNo: extra?["engineNo"] ?? "",
          fuelType: extra?["fuelType"]?.toString() ?? "",
          transmissionType: extra?["transmissionType"]?.toString() ?? "",
          serviceType: extra?["serviceType"]?.toString() ?? "",
          customerType: extra?["customerType"]?.toString() ?? "",
        );
      },
    ),

    GoRoute(
      path: '/jobcarddetails',
      name: 'Job Card Details',
      builder: (BuildContext context, GoRouterState state) {
        final jobId = state.extra as int;
        return JobCardDetails(jobId: jobId);
      },
    ),

    GoRoute(
      path: '/vehiclecontents',
      name: 'Vehicle Contents',
      builder: (BuildContext context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;

        final int jobId = data['jobId'];
        final int vId = data['vId'];
        return VehicleEssentialScreen(jobId: jobId, vId: vId);
      },
    ),

    GoRoute(
      path: '/inspectiondetails',
      builder: (context, state) {
        final jobId = state.extra as int;
        return InspectionDetails(jobId: jobId);
      },
    ),

    GoRoute(
      path: "/inspectiontypedetailspage",
      name: 'Inspection Type Details',
      builder: (BuildContext context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        final inspectionFormId = data["inspectionFormId"];
        final jobId = data["jobId"];
        final inspectionTypeId = data["inspectionTypeId"];
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => InspectionFormController()),
            ChangeNotifierProvider(
              create: (_) => InspectionTypeDetailsController(),
            ),
          ],
          child: InspectionTypeDetailspage(
            inspectionFormId: inspectionFormId,
            jobId: jobId,
            inspectionTypeId:inspectionTypeId
          ),
        );
      },
    ),

    GoRoute(
      path: '/inspectionsummarypage',
      name: 'Inspection Summary',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>;
        final int jobId = extra['jobId'];
        final int flag = extra['flag'] ?? 0; // default to home
        return InspectionSummaryPage(jobId: jobId, flag: flag);
      },
    ),

    GoRoute(
      path: '/componentlistpage',
      name: ' Component List',
      builder: (BuildContext context, GoRouterState state) {
        return ComponentListWidget();
      },
    ),

    GoRoute(
      path: '/quotationdetailspage',
      name: ' Quotation Details',
      builder: (BuildContext context, GoRouterState state) {
        return QuotationDetailsPage();
      },
    ),

    // GoRoute(
    //   path: '/historydetailspage',
    //   name: ' History Details',
    //   builder: (BuildContext context, GoRouterState state) {
    //     return HistoryDetailsPage();
    //   },
    // ),

    GoRoute(
      path: '/profile',
      name: 'Profile Screen',
      builder: (context, state) => const ProfileScreen(),
    ),

    GoRoute(
      path: '/basicinspection',
      name: 'Basic inspection Screen',
      builder: (BuildContext context, GoRouterState state) {
        final jobId = state.extra as int;
        return BasicinspScreen(jobId: jobId);
      },
      // builder: (context, state) => const BasicinspectionScreen(),
    ),

    GoRoute(
      path: '/basicInspectionReport',
      name: 'Basic Inspection Report',
      builder: (BuildContext context, GoRouterState state) {
        final jobId = state.extra as int;
        return BasicInspectionReport(jobId: jobId);
      },
    ),

    GoRoute(
      path: '/basicInspectionPreview',
      name: 'Basic Inspection Preview',
      builder: (BuildContext context, GoRouterState state) {
        final jobId = state.extra as int;
        return Scaffold(
          body: SingleChildScrollView(
            child: BasicInspectionPreview(jobId: jobId),
          ),
        );
      },
    ),

    GoRoute(
      path: '/galleryview',
      name: ' Gallery  View',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return GalleryView(jobId: extra['jobId'], type: extra['type']);
      },
    ),

    GoRoute(
      path: '/fullScreenImage',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return FullScreenImage(
          imageUrl: data['imageUrl'],
          label: data['label'],
        );
      },
    ),

    GoRoute(
      path: '/inspectionFullScreenVideo',
      builder: (context, state) {
        final args = state.extra as Map<String, String>;
        return InspectionFullScreenVideo(
          videoUrl: args['videoUrl']!,
          label: args['label']!,
        );
      },
    ),

    GoRoute(
      path: '/alljobcardview',
      name: ' All JobCard View',
      builder: (BuildContext context, GoRouterState state) {
         final jobcardList =
        state.extra as List;
        return Alljobcardview( jobcardList: jobcardList,);
      },
    ),

    GoRoute(
      path: '/allpendinginspection',
      name: 'Basic Inspection Pending List',
      builder: (BuildContext context, GoRouterState state) {
        final inspectionList = state.extra as List;

        return Allpendinginspection(inspectionList: inspectionList);
      },
    ),

    GoRoute(
      path: '/reassigneddetails',
      name: 'Reassigned Details',
      builder: (BuildContext context, GoRouterState state) {
        final jobId = state.extra as int;
        return ChangeNotifierProvider(
          create: (_) => InspectionFormController(),
          child: ReassignedDetailsPage(jobId: jobId),
        );
      },
    ),
  ],
);
