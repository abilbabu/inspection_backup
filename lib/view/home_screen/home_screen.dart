import 'dart:convert';
import 'dart:developer';
// import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/app_theme/app_theme.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  late List inspectionList = [];
  late List jobcardList = [];

  bool isJobcardLoading = true;
  int _currentPage = 0;

  Future<Map<String, dynamic>> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {"name": prefs.getString("userName") ?? ""};
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInspectionListByUserId();
      getJobCardListByUserId();
    });
  }

  Future<void> getInspectionListByUserId() async {
    final url = Uri.parse(ApiServices.allInspectionList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      String? userId = prefs.getString('userId');
      if (userId == null) {
        print("❗ userId not found in prefs");
        return;
      }
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({"userId": int.parse(userId)}),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final List rawList = res["data"] ?? [];
        setState(() {
          inspectionList = rawList
              .where((item) {
                final int status =
                    int.tryParse(item["jobStatus"]?.toString() ?? "") ?? -1;
                return status == 1 || status == 2;
              })
              .map((item) {
                final vehicle = item["vehicle"] ?? {};
                return {
                  "jobId": item["jobId"]?.toString() ?? "",
                  "jobNo": item["jobNo"]?.toString() ?? "",
                  "make": vehicle["vMake"] ?? "",
                  "model": vehicle["vModel"] ?? "",
                  "year": vehicle["vModelYear"]?.toString() ?? "",
                  "odometer": vehicle["vOdometer"]?.toString() ?? "",
                  "plateNo": vehicle["vRegNo"]?.toString() ?? "",
                  "jobStatus": item["jobStatus"]?.toString() ?? "",
                  "vehicleTypeId": vehicle["vTypeId"] ?? -1,
                  "jobCreatedOn": item["jobCreatedOn"] ?? "",
                };
              })
              .toList();
        });
      }
    } catch (e) {
      print("❗ Error in getInspectionListByUserId: $e");
    }
  }

  Future<void> getJobCardListByUserId() async {
    final url = Uri.parse(ApiServices.allInspectionList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      String? userId = prefs.getString('userId');
      if (userId == null) {
        return;
      }
      setState(() {
        isJobcardLoading = true;
      });
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({"userId": int.parse(userId)}),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final List rawList = res["data"] ?? [];
        setState(() {
          jobcardList = rawList
              .where((item) {
                final int status =
                    int.tryParse(item["jobStatus"]?.toString() ?? "") ?? -1;
                return ![0, 1, 2, -1].contains(status);
              })
              .map((item) {
                final vehicle = item["vehicle"] ?? {};
                return {
                  "jobId": item["jobId"]?.toString() ?? "",
                  "jobNo": item["jobNo"]?.toString() ?? "",
                  "make": vehicle["vMake"] ?? "",
                  "model": vehicle["vModel"] ?? "",
                  "year": vehicle["vModelYear"]?.toString() ?? "",
                  "odometer": vehicle["vOdometer"]?.toString() ?? "",
                  "plateNo": vehicle["vRegNo"]?.toString() ?? "",
                  "vinNo": vehicle["vVinNo"]?.toString() ?? "",
                  "jobStatus": item["jobStatus"]?.toString() ?? "",
                  "vehicleTypeId": vehicle["vTypeId"] ?? -1,
                  "jobCreatedOn": item["jobCreatedOn"] ?? "",
                  "inspections": item["inspections"] ?? [],
                };
              })
              .toList();
          isJobcardLoading = false;
        });
      } else {
        setState(() {
          isJobcardLoading = false;
        });
      }
    } catch (e) {
      print("❗ EXCEPTION: $e");
      setState(() {
        isJobcardLoading = false;
      });
    }
  }

  // String formatDateTime(String? dateStr) {
  //   if (dateStr == null || dateStr.isEmpty) return "";
  //   try {
  //     DateTime dt = DateTime.parse(dateStr).toLocal();
  //     return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  //   } catch (e) {
  //     return dateStr;
  //   }
  // }

  // String getJobStatusText(String? status) {
  //   switch (status) {
  //     case "0":
  //       return "Bookingsheet Initialized";
  //     case "1":
  //       return "Bookingsheet Created";
  //     case "2":
  //       return "Basic Inspection In Progress";
  //     case "3":
  //       return "Jobcard Open";
  //     case "4":
  //       return "Inspection Started";
  //     case "5":
  //       return "Inspection In Progress";
  //     case "6":
  //       return "Inspection Completed";
  //     case "7":
  //       return "Technician Report In Progress";
  //     case "8":
  //       return "Technician Report Waiting For Approval";
  //     case "9":
  //       return "Quotation Requested";
  //     default:
  //       return "Unknown Status";
  //   }
  // }

  // Color getJobStatusColor(String? status) {
  //   switch (status) {
  //     case "0":
  //       return ColorConstants.blackColor;
  //     case "1":
  //       return ColorConstants.blackColor;
  //     case "2":
  //       return ColorConstants.textBlueColor;
  //     case "3":
  //       return ColorConstants.textBlueColor;
  //     case "4":
  //       return Colors.purple;
  //     case "5":
  //       return Colors.purple;
  //     case "6":
  //       return Colors.indigo;
  //     case "7":
  //       return Colors.indigo;
  //     case "8":
  //       return ColorConstants.greenColor;
  //     case "9":
  //       return ColorConstants.greenColor;
  //     default:
  //       return ColorConstants.holdorangeColor;
  //   }
  // }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInspection = inspectionList.isNotEmpty;
    final bool hasJobCard = jobcardList.isNotEmpty;
    return Scaffold(
      body: AppTheme(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 60),
              _headerSection(),
              if (hasInspection) const SizedBox(height: 12),
              if (hasInspection) appointmentSection(),
              const SizedBox(height: 12),
              inspectionModeSection(context),
              if (hasJobCard) const SizedBox(height: 12),
              if (hasJobCard) jobCardSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            "Welcome, ",
            style: ApptextstyleConstants.extraLightText(
              fontSize: 18,
              color: ColorConstants.whiteColor,
            ),
          ),
          FutureBuilder(
            future: getSavedUser(),
            builder: (context, snapshot) {
              final name = snapshot.hasData
                  ? snapshot.data!["name"] ?? "System User"
                  : "System User";
              return Text(
                name,
                style: ApptextstyleConstants.regularText(
                  fontSize: 20,
                  color: ColorConstants.whiteColor,
                ),
              );
            },
          ),
          const Spacer(),
          HugeIcon(
            icon: HugeIcons.strokeRoundedNotification01,
            color: ColorConstants.whiteColor.withOpacity(0.2),
            size: 25,
          ),
        ],
      ),
    );
  }

  Widget inspectionModeSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Inspection Mode",
            style: ApptextstyleConstants.mediumText(
              fontSize: 18,
              color: ColorConstants.whiteColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _inspectionModeCard(
                    title: "General",
                    icon: Icons.car_repair,
                    enabled: true,
                    onTap: () => context.go("/vehicledetails"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _inspectionModeCard(
                    title: "Quick",
                    icon: Icons.flash_on,
                    enabled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _inspectionModeCard(
                    title: "Jobcard",
                    icon: Icons.assignment,
                    enabled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectionModeCard({
    required String title,
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : () => _showComingSoon(context),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? [Colors.white, Colors.cyan.shade100]
                : [Colors.grey.shade200, Colors.grey.shade300],
          ),
          boxShadow: ColorConstants.dashboardboxShadow,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: enabled ? ColorConstants.blackColor : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: ApptextstyleConstants.regularText(
                      fontSize: 13,
                      color: enabled ? ColorConstants.blackColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!enabled)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Coming Soon",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget appointmentSection() {
    final reversedList = inspectionList.reversed.toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Pending Inspections",
            style: ApptextstyleConstants.mediumText(
              fontSize: 18,
              color: ColorConstants.whiteColor,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: PageView.builder(
              controller: _pageController,
              itemCount: inspectionList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  // _currentPage = inspectionList.length - 1 - index;
                });
              },
              itemBuilder: (context, index) {
                // final reverseIndex = inspectionList.length - 1 - index;
                // final item = inspectionList[reverseIndex];
                final item = reversedList[index];

                // final item = inspectionList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      final int jobId =
                          int.tryParse(item["jobId"]?.toString() ?? "0") ?? 0;
                      final int jobStatus =
                          int.tryParse(item["jobStatus"]?.toString() ?? "0") ??
                          0;
                      final vehicle = item["vehicle"] ?? {};
                      final int vId =
                          int.tryParse(vehicle["vId"]?.toString() ?? "0") ?? 0;
                      if (jobStatus == 1) {
                        context.go(
                          "/vehiclecontents",
                          extra: {"jobId": jobId, "vId": vId},
                        );
                      } else if (jobStatus == 2) {
                        context.go("/basicinspection", extra: jobId);
                      }
                    },
                    child: inspectionCard(item),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildDotsIndicator(reversedList.length),
        ],
      ),
    );
  }

  Widget jobCardSection() {
    if (jobcardList.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Job Cards",
            style: ApptextstyleConstants.regularText(
              fontSize: 18,
              color: ColorConstants.blackColor,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jobcardList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 1),
              itemBuilder: (context, index) {
                // return jobCardItem(context, jobcardList[index]);
                final reverseIndex = jobcardList.length - 1 - index;
                return jobCardItem(context, jobcardList[reverseIndex]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("Feature coming soon"),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Widget inspectionCard(Map<String, dynamic> data) {
    final controller = Provider.of<HomescreenController>(
      context,
      listen: false,
    );
    return Container(
      height: 110,
      width: 260,
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: ColorConstants.dashboardboxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ColorConstants.containergreycolor,
                shape: BoxShape.circle,
              ),
              child: Image.asset("assets/image/benz.png", fit: BoxFit.cover),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: "Job Card No: ",
                      style: ApptextstyleConstants.thinText(
                        fontSize: 10,
                        color: ColorConstants.blackColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: data["jobNo"],
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.textBlueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: "Date: ",
                      style: ApptextstyleConstants.thinText(
                        fontSize: 10,
                        color: ColorConstants.blackColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: controller.formatDateTime(data["jobCreatedOn"]),
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.textBlueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: "Vehicle: ",
                      style: ApptextstyleConstants.thinText(
                        fontSize: 10,
                        color: ColorConstants.blackColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: "${data["make"]} ${data["model"]}",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: "Odometer: ",
                      style: ApptextstyleConstants.thinText(
                        fontSize: 10,
                        color: ColorConstants.blackColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: "${data["odometer"]}",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      text: "Plate No: ",
                      style: ApptextstyleConstants.thinText(
                        fontSize: 10,
                        color: ColorConstants.blackColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: "${data["plateNo"]}",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(int length) {
    if (length <= 1) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final bool isActive = _currentPage == index;

        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 20 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? ColorConstants.textBlueColor
                  : ColorConstants.whiteColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget jobCardItem(BuildContext context, Map<String, dynamic> item) {
    final controller = Provider.of<HomescreenController>(
      context,
      listen: false,
    );

    final String jobStatusStr = item['jobStatus']?.toString().trim() ?? "";
    final int jobStatus = int.tryParse(jobStatusStr) ?? 0;
    final String vehicleName = "${item['make'] ?? ''} ${item['model'] ?? ''}";
    final String statusText = controller.getJobStatusText(jobStatusStr);
    return GestureDetector(
      onTap: () {
        // log("👉 CLICKED INDEX:");
        // log("👉 JOB DATA: $item");
        final dynamic rawJobId = item['jobId'];
        // final dynamic rawInspections = item['inspections'];
        final int jobId = rawJobId is int
            ? rawJobId
            : int.tryParse(rawJobId?.toString() ?? '0') ?? 0;
        // final List inspections = rawInspections is List ? rawInspections : [];
        // int inspectionMasterId = 0;
        // for (final inspection in inspections) {
        //  final rawId = inspection['master']?['vimIfMasterId'];
        //   log("✅✅✅Inspection Item: $inspection");
        //   log("✅✅Type: ${inspection.runtimeType}");
        //   final int parsedId = rawId is int
        //       ? rawId
        //       : int.tryParse(rawId?.toString() ?? '0') ?? 0;
        //   if (parsedId > 0) {
        //     inspectionMasterId = parsedId;
        //      log("✅ FOUND ID: $inspectionMasterId");
        //     break;
        //   }
        // }
        // log("👉 FINAL inspectionMasterId: $inspectionMasterId");
        if (jobStatus == 3) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 4) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 5) {
          log("Inside Status 5");
          context.go("/jobcarddetails", extra: jobId);

          // if (inspectionMasterId > 0) {
          //   context.go(
          //     "/inspectiontypedetailspage",
          //     extra: {"inspectionFormId": inspectionMasterId, "jobId": jobId},
          //   );
          // } else {
          //   // log("inspectionMasterId is 0 → Going to inspectiondetails");

          //   context.go("/inspectiondetails", extra: jobId);
          // }
        } else if (jobStatus == 6) {
          context.go("/jobcarddetails", extra: jobId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Container(
          width: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: ColorConstants.containergradientColor,
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['jobNo'] ?? "",
                  style: ApptextstyleConstants.regularText(
                    fontSize: 16,
                    color: ColorConstants.blackColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Plate No: ${item['plateNo'] ?? ''}",
                  style: ApptextstyleConstants.lightText(
                    fontSize: 15,
                    color: ColorConstants.blackColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Vin No: ${item['vinNo'] ?? ''}",
                  maxLines: 1,
                  style: ApptextstyleConstants.lightText(
                    fontSize: 12,
                    color: ColorConstants.blackColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  vehicleName,
                  style: ApptextstyleConstants.thinText(
                    fontSize: 12,
                    color: ColorConstants.blackColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  statusText,
                  style: ApptextstyleConstants.thinText(
                    fontSize: 12,
                    color: controller.getJobStatusColor(jobStatus.toString()),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Image.asset(
                    "assets/image/benz_logo.png",
                    width: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
