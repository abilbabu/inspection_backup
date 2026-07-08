import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/app_theme/app_theme.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;

  final PageController _pageController = PageController();
  TextEditingController searchController = TextEditingController();
  String searchText = "";
  late List inspectionList = [];
  late List jobcardList = [];
  bool isJobcardLoading = true;
  int _currentPage = 0;
  int userDepartment = 0;
  int? inspectionTypeId;
  Future<Map<String, dynamic>> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {"name": prefs.getString("userName") ?? ""};
  }

  Future<void> loadUserDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userDepartment =
          int.tryParse(prefs.getString("userDepartment") ?? "0") ?? 0;
    });
  }

  Future<void> refreshData() async {
    await Future.wait([getInspectionListByUserId(), getJobCardListByUserId()]);
  }

  @override
  void initState() {
    super.initState();
    loadUserDepartment();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });
      await Future.wait([
        getInspectionListByUserId(),
        getJobCardListByUserId(),
      ]);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.toLowerCase();
      });
    });
  }

  Future<List<dynamic>> _fetchInspectionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      final userId = prefs.getString('userId');
      final userDepartment = prefs.getString('userDepartment');
      if (userId == null || userToken == null || userDepartment == null) {
        debugPrint("❗ userId or token missing");
        return [];
      }
      final response = await http.post(
        Uri.parse(ApiServices.allInspectionList),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({
          "userId": int.parse(userId),
          "userDepartment": int.parse(userDepartment.toString()),
        }),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res["data"] ?? [];
      }
      return [];
    } catch (e) {
      print("❗ API Exception: $e");
      return [];
    }
  }

  Map<String, dynamic> _mapVehicleData(
    Map<String, dynamic> item, {
    bool includeInspections = false,
  }) {
    final vehicle = item["vehicle"] ?? {};
    final inspections = item["inspections"];
    if (inspections is List && inspections.isNotEmpty) {
      final firstInspection = inspections.first;
      if (firstInspection is Map && firstInspection["master"] != null) {
        inspectionTypeId = firstInspection["master"]["vimInspectionType"];
      }
    }
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
      "jobTechnicianId": item["jobTechnicianId"],
      "userDepartment": item["userDepartment"],
      if (includeInspections) "inspections": item["inspections"] ?? [],
    };
  }

  Future<void> getInspectionListByUserId() async {
    final rawList = await _fetchInspectionData();
    final filteredList = rawList
        .where((item) {
          final status =
              int.tryParse(item["jobStatus"]?.toString() ?? "") ?? -1;
          return status == 1 || status == 2;
        })
        .map((item) {
          return _mapVehicleData(item);
        })
        .toList();
    if (!mounted) return;
    setState(() {
      inspectionList = filteredList;
    });
  }

  Future<void> getJobCardListByUserId() async {
    if (!mounted) return;
    setState(() {
      isJobcardLoading = true;
    });
    try {
      final rawList = await _fetchInspectionData();
      final filteredList = rawList
          .where((item) {
            final status =
                int.tryParse(item["jobStatus"]?.toString() ?? "") ?? -1;
            return ![0, 1, 2, -1].contains(status);
          })
          .map((item) {
            return _mapVehicleData(item, includeInspections: true);
          })
          .toList();
      if (!mounted) return;
      setState(() {
        jobcardList = filteredList;
      });
    } finally {
      if (mounted) {
        setState(() {
          isJobcardLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: ""),
        body: SingleChildScrollView(child: inspectionShimmer()),
      );
    }

    final bool hasInspection = inspectionList.isNotEmpty;
    // final bool hasJobCard = jobcardList.isNotEmpty;

    final bool isOnlyJobCardDepartment =
        userDepartment == 2 || userDepartment == 4 || userDepartment == 5;

    final reversedList = jobcardList.reversed.toList();

    final reInspectionList = reversedList.where((item) {
      final status = int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;

      return (status == 10 || status == 11 || status == 18);
    }).toList();

    return Scaffold(
      body: AppTheme(
        child: !isOnlyJobCardDepartment
            ? RefreshIndicator(
                onRefresh: refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      _headerSection(),
                      if (hasInspection) ...[
                        const SizedBox(height: 12),
                        appointmentSection(),
                      ],
                      const SizedBox(height: 12),
                      inspectionModeSection(context),
                      SizedBox(height: 12),
                      jobCardSection(),
                      SizedBox(height: 12),
                      if ((userDepartment == 0 || userDepartment == 1) &&
                          reInspectionList.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Re-Inspection",
                                style: ApptextstyleConstants.regularText(
                                  fontSize: 18,
                                  color: ColorConstants.blackColor,
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reInspectionList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  return jobCardItemTechinician(
                                    context,
                                    reInspectionList[index],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 60),
                    _headerSection(),
                    SizedBox(height: 12),
                    jobCardSection(),
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
    final latestFiveList = reversedList.take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "My Pending Inspections",
                style: ApptextstyleConstants.mediumText(
                  fontSize: 18,
                  color: ColorConstants.whiteColor,
                ),
              ),
              Spacer(),
              InkWell(
                onTap: () {
                  context.go("/allpendinginspection", extra: inspectionList);
                },
                child: Text(
                  "View All",
                  style: ApptextstyleConstants.mediumText(
                    fontSize: 16,
                    color: ColorConstants.whiteColor,
                  ),
                ),
              ),
              SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: PageView.builder(
              controller: _pageController,
              itemCount: latestFiveList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final item = latestFiveList[index];
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
          _buildDotsIndicator(latestFiveList.length),
        ],
      ),
    );
  }

  Widget jobCardSection() {
    // if (jobcardList.isEmpty) return const SizedBox();
    final reversedList = jobcardList.reversed.toList();
    final latestFiveList = reversedList
        .where((item) {
          final status =
              int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;

          return [3, 4, 5, 9].contains(status);
        })
        .take(5)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userDepartment != 2 && userDepartment != 4 && userDepartment != 5)
            Row(
              children: [
                Text(
                  "Job Cards",
                  style: ApptextstyleConstants.regularText(
                    fontSize: 18,
                    color: ColorConstants.blackColor,
                  ),
                ),
                Spacer(),
                InkWell(
                  onTap: () {
                    context.go("/alljobcardview", extra: jobcardList);
                  },
                  child: Text(
                    "View All",
                    style: ApptextstyleConstants.mediumText(
                      fontSize: 16,
                      color: ColorConstants.blackColor,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          if (userDepartment != 2 &&
              userDepartment != 4 &&
              userDepartment != 5) ...[
            if (latestFiveList.isNotEmpty) ...[
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: latestFiveList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 1),
                  itemBuilder: (context, index) {
                    final item = latestFiveList[index];
                    return jobCardItem(context, item);
                  },
                ),
              ),
            ] else ...[
              emptyJobCardContainer(
                title: "No Job Cards",
                subtitle: "There are no job cards available.",
              ),
            ],
          ],

          // if (userDepartment == 2 || userDepartment == 5) ...[
          //   Builder(
          //     builder: (context) {
          //       final int jcTabLength = 3;
          //       return DefaultTabController(
          //         length: jcTabLength,
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Container(
          //               height: 45,
          //               padding: const EdgeInsets.all(4),
          //               decoration: BoxDecoration(
          //                 gradient: ColorConstants.tabgradientColor,
          //                 borderRadius: BorderRadius.circular(30),
          //               ),
          //               child: TabBar(
          //                 indicator: BoxDecoration(
          //                   color: Colors.white,
          //                   borderRadius: BorderRadius.circular(25),
          //                   border: Border.all(
          //                     color: const Color(0xFF0066A6),
          //                     width: 1.5,
          //                   ),
          //                 ),
          //                 labelColor: Colors.transparent,
          //                 unselectedLabelColor: ColorConstants.activecolor,
          //                 indicatorSize: TabBarIndicatorSize.tab,
          //                 dividerColor: Colors.transparent,
          //                 tabs: [
          //                   Tab(
          //                     child: ShaderMask(
          //                       shaderCallback: (bounds) {
          //                         return const LinearGradient(
          //                           colors: [
          //                             Color(0xFF0066A6),
          //                             Color(0xFF00BFA6),
          //                           ],
          //                         ).createShader(bounds);
          //                       },
          //                       child: const Text(
          //                         "Pending",
          //                         style: TextStyle(
          //                           color: Colors.white,
          //                           fontWeight: FontWeight.w600,
          //                           fontSize: 14,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                   Tab(
          //                     child: ShaderMask(
          //                       shaderCallback: (bounds) {
          //                         return const LinearGradient(
          //                           colors: [
          //                             Color(0xFF0066A6),
          //                             Color(0xFF00BFA6),
          //                           ],
          //                         ).createShader(bounds);
          //                       },
          //                       child: const Text(
          //                         "Assigned",
          //                         style: TextStyle(
          //                           color: Colors.white,
          //                           fontWeight: FontWeight.w600,
          //                           fontSize: 14,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                   Tab(
          //                     child: ShaderMask(
          //                       shaderCallback: (bounds) {
          //                         return const LinearGradient(
          //                           colors: [
          //                             Color(0xFF0066A6),
          //                             Color(0xFF00BFA6),
          //                           ],
          //                         ).createShader(bounds);
          //                       },
          //                       child: const Text(
          //                         "Reassigned",
          //                         style: TextStyle(
          //                           color: Colors.white,
          //                           fontWeight: FontWeight.w600,
          //                           fontSize: 14,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             SizedBox(height: 20),
          //             SizedBox(
          //               height: 40,
          //               child: TextField(
          //                 controller: searchController,
          //                 decoration: InputDecoration(
          //                   hintText: "Search Job Card No",
          //                   prefixIcon: const Icon(Icons.search),
          //                   filled: true,
          //                   fillColor: Colors.white,
          //                   contentPadding: const EdgeInsets.symmetric(
          //                     vertical: 0,
          //                   ),
          //                   border: OutlineInputBorder(
          //                     borderRadius: BorderRadius.circular(30),
          //                     borderSide: BorderSide.none,
          //                   ),
          //                 ),
          //               ),
          //             ),
          //             SizedBox(
          //               height: MediaQuery.sizeOf(context).height * 0.75,
          //               child: TabBarView(
          //                 children: [
          //                   /// ================= Pending =================
          //                   Builder(
          //                     builder: (context) {
          //                       final pendingList = reversedList.where((item) {
          //                         final status =
          //                             int.tryParse(
          //                               item["jobStatus"].toString(),
          //                             ) ??
          //                             0;

          //                         final searchMatch =
          //                             item["jobNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["plateNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["vinNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true;
          //                         return status == 3 && searchMatch;
          //                       }).toList();
          //                       if (pendingList.isEmpty) {
          //                         return RefreshIndicator(
          //                           onRefresh: refreshData,
          //                           child: ListView(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             children: [
          //                               SizedBox(
          //                                 height:
          //                                     MediaQuery.sizeOf(
          //                                       context,
          //                                     ).height *
          //                                     0.5,
          //                                 child: Center(
          //                                   child: emptyJobCardContainer(
          //                                     title: "No Pending Jobs",
          //                                     subtitle:
          //                                         "There are no pending job cards available.",
          //                                   ),
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         );
          //                       }
          //                       return RefreshIndicator(
          //                         onRefresh: refreshData,
          //                         child: Padding(
          //                           padding: const EdgeInsets.all(5),
          //                           child: ListView.separated(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             itemCount: pendingList.length,
          //                             separatorBuilder: (_, __) =>
          //                                 SizedBox(height: 0),
          //                             itemBuilder: (context, index) {
          //                               return jobCardItemlist(
          //                                 context,
          //                                 pendingList[index],
          //                               );
          //                             },
          //                           ),
          //                         ),
          //                       );
          //                     },
          //                   ),

          //                   /// ================= Assigned =================
          //                   Builder(
          //                     builder: (context) {
          //                       final assignedList = reversedList.where((item) {
          //                         final status =
          //                             int.tryParse(
          //                               item["jobStatus"].toString(),
          //                             ) ??
          //                             0;
          //                         final searchMatch =
          //                             item["jobNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["plateNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["vinNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true;
          //                         return (status == 5 || status == 4) &&
          //                             searchMatch;
          //                       }).toList();

          //                       if (assignedList.isEmpty) {
          //                         return RefreshIndicator(
          //                           onRefresh: refreshData,
          //                           child: ListView(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             children: [
          //                               SizedBox(
          //                                 height:
          //                                     MediaQuery.sizeOf(
          //                                       context,
          //                                     ).height *
          //                                     0.5,
          //                                 child: Center(
          //                                   child: emptyJobCardContainer(
          //                                     title: "No Assigned Jobs",
          //                                     subtitle:
          //                                         "There are no assigned job cards available.",
          //                                   ),
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         );
          //                       }
          //                       return RefreshIndicator(
          //                         onRefresh: refreshData,
          //                         child: Padding(
          //                           padding: const EdgeInsets.all(5),
          //                           child: ListView.separated(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             itemCount: assignedList.length,
          //                             separatorBuilder: (_, __) =>
          //                                 const SizedBox(height: 0),
          //                             itemBuilder: (context, index) {
          //                               return jobCardItemlist(
          //                                 context,
          //                                 assignedList[index],
          //                               );
          //                             },
          //                           ),
          //                         ),
          //                       );
          //                     },
          //                   ),

          //                   /// ================= Re-Assigned =================
          //                   Builder(
          //                     builder: (context) {
          //                       final reAssignedList = reversedList.where((
          //                         item,
          //                       ) {
          //                         final status =
          //                             int.tryParse(
          //                               item["jobStatus"].toString(),
          //                             ) ??
          //                             0;
          //                         final searchMatch =
          //                             item["jobNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["plateNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["vinNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true;
          //                         return (status == 10 ||
          //                                 status == 11 ||
          //                                 status == 18) &&
          //                             searchMatch;
          //                       }).toList();
          //                       if (reAssignedList.isEmpty) {
          //                         return RefreshIndicator(
          //                           onRefresh: refreshData,
          //                           child: ListView(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             children: [
          //                               SizedBox(
          //                                 height:
          //                                     MediaQuery.sizeOf(
          //                                       context,
          //                                     ).height *
          //                                     0.5,
          //                                 child: Center(
          //                                   child: emptyJobCardContainer(
          //                                     title: "No Reassigned Jobs",
          //                                     subtitle:
          //                                         "There are no reassigned job cards available.",
          //                                   ),
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         );
          //                       }
          //                       return RefreshIndicator(
          //                         onRefresh: refreshData,
          //                         child: Padding(
          //                           padding: const EdgeInsets.all(5),
          //                           child: ListView.separated(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             itemCount: reAssignedList.length,
          //                             separatorBuilder: (_, __) =>
          //                                 const SizedBox(height: 0),
          //                             itemBuilder: (context, index) {
          //                               return jobCardItemlist(
          //                                 context,
          //                                 reAssignedList[index],
          //                               );
          //                             },
          //                           ),
          //                         ),
          //                       );
          //                     },
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         ),
          //       );
          //     },
          //   ),
          // ],

          //  userDepartment == 4 use
          // if (userDepartment == 4) ...[
          //   Builder(
          //     builder: (context) {
          //       final int techTabLength = 3;
          //       return DefaultTabController(
          //         length: techTabLength,
          //         initialIndex: 0,
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Container(
          //               height: 45,
          //               padding: const EdgeInsets.all(4),
          //               decoration: BoxDecoration(
          //                 gradient: ColorConstants.tabgradientColor,
          //                 borderRadius: BorderRadius.circular(30),
          //               ),
          //               child: TabBar(
          //                 indicator: BoxDecoration(
          //                   color: Colors.white,
          //                   borderRadius: BorderRadius.circular(25),
          //                   border: Border.all(
          //                     color: const Color(0xFF0066A6),
          //                     width: 1.5,
          //                   ),
          //                 ),
          //                 labelColor: Colors.transparent,
          //                 unselectedLabelColor: ColorConstants.activecolor,
          //                 indicatorSize: TabBarIndicatorSize.tab,
          //                 dividerColor: Colors.transparent,
          //                 tabs: [
          //                   Tab(
          //                     child: ShaderMask(
          //                       shaderCallback: (bounds) {
          //                         return const LinearGradient(
          //                           colors: [
          //                             Color(0xFF0066A6),
          //                             Color(0xFF00BFA6),
          //                           ],
          //                         ).createShader(bounds);
          //                       },
          //                       child: const Text(
          //                         "Pending",
          //                         style: TextStyle(
          //                           color: Colors.white,
          //                           fontWeight: FontWeight.w600,
          //                           fontSize: 14,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                   Tab(
          //                     child: ShaderMask(
          //                       shaderCallback: (bounds) {
          //                         return const LinearGradient(
          //                           colors: [
          //                             Color(0xFF0066A6),
          //                             Color(0xFF00BFA6),
          //                           ],
          //                         ).createShader(bounds);
          //                       },
          //                       child: const Text(
          //                         "On Going",
          //                         style: TextStyle(
          //                           color: Colors.white,
          //                           fontWeight: FontWeight.w600,
          //                           fontSize: 14,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                   Tab(
          //                     child: ShaderMask(
          //                       shaderCallback: (bounds) {
          //                         return const LinearGradient(
          //                           colors: [
          //                             Color(0xFF0066A6),
          //                             Color(0xFF00BFA6),
          //                           ],
          //                         ).createShader(bounds);
          //                       },
          //                       child: const Text(
          //                         "Reassigned",
          //                         style: TextStyle(
          //                           color: Colors.white,
          //                           fontWeight: FontWeight.w600,
          //                           fontSize: 14,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             const SizedBox(height: 20),
          //             SizedBox(
          //               height: 40,
          //               child: TextField(
          //                 controller: searchController,
          //                 decoration: InputDecoration(
          //                   hintText: "Search Job No ",
          //                   prefixIcon: const Icon(Icons.search),
          //                   filled: true,
          //                   fillColor: Colors.white,
          //                   contentPadding: const EdgeInsets.symmetric(
          //                     vertical: 0,
          //                   ),
          //                   border: OutlineInputBorder(
          //                     borderRadius: BorderRadius.circular(30),
          //                     borderSide: BorderSide.none,
          //                   ),
          //                 ),
          //               ),
          //             ),
          //             SizedBox(
          //               height: MediaQuery.sizeOf(context).height * 0.75,
          //               child: TabBarView(
          //                 children: [
          //                   Builder(
          //                     builder: (context) {
          //                       final pendingList = reversedList.where((item) {
          //                         final status =
          //                             int.tryParse(
          //                               item["jobStatus"].toString(),
          //                             ) ??
          //                             0;
          //                         final searchMatch =
          //                             item["jobNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["plateNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["vinNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true;
          //                         return (status == 4) && searchMatch;
          //                       }).toList();
          //                       if (pendingList.isEmpty) {
          //                         return RefreshIndicator(
          //                           onRefresh: refreshData,
          //                           child: ListView(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             children: [
          //                               SizedBox(
          //                                 height:
          //                                     MediaQuery.sizeOf(
          //                                       context,
          //                                     ).height *
          //                                     0.5,
          //                                 child: Center(
          //                                   child: emptyJobCardContainer(
          //                                     title: "No Pending Jobs",
          //                                     subtitle:
          //                                         "There are no pending job cards available.",
          //                                   ),
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         );
          //                       }
          //                       return RefreshIndicator(
          //                         onRefresh: refreshData,
          //                         child: Padding(
          //                           padding: const EdgeInsets.all(5),
          //                           child: ListView.separated(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             itemCount: pendingList.length,
          //                             separatorBuilder: (_, __) =>
          //                                 const SizedBox(height: 0),
          //                             itemBuilder: (context, index) {
          //                               return jobCardItemTechinician(
          //                                 context,
          //                                 pendingList[index],
          //                               );
          //                             },
          //                           ),
          //                         ),
          //                       );
          //                     },
          //                   ),
          //                   Builder(
          //                     builder: (context) {
          //                       final ongoingList = reversedList.where((item) {
          //                         final status =
          //                             int.tryParse(
          //                               item["jobStatus"].toString(),
          //                             ) ??
          //                             0;
          //                         final searchMatch =
          //                             item["jobNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["plateNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["vinNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true;
          //                         return (status == 5) && searchMatch;
          //                       }).toList();
          //                       if (ongoingList.isEmpty) {
          //                         return RefreshIndicator(
          //                           onRefresh: refreshData,
          //                           child: ListView(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             children: [
          //                               SizedBox(
          //                                 height:
          //                                     MediaQuery.sizeOf(
          //                                       context,
          //                                     ).height *
          //                                     0.5,
          //                                 child: Center(
          //                                   child: emptyJobCardContainer(
          //                                     title: "No On Going Jobs",
          //                                     subtitle:
          //                                         "There are no ongoing job cards available.",
          //                                   ),
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         );
          //                       }
          //                       return RefreshIndicator(
          //                         onRefresh: refreshData,
          //                         child: Padding(
          //                           padding: const EdgeInsets.all(5),
          //                           child: ListView.separated(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             itemCount: ongoingList.length,
          //                             separatorBuilder: (_, __) =>
          //                                 const SizedBox(height: 0),
          //                             itemBuilder: (context, index) {
          //                               return jobCardItemlist(
          //                                 context,
          //                                 ongoingList[index],
          //                               );
          //                             },
          //                           ),
          //                         ),
          //                       );
          //                     },
          //                   ),
          //                   Builder(
          //                     builder: (context) {
          //                       final reAssignedList = reversedList.where((
          //                         item,
          //                       ) {
          //                         final status =
          //                             int.tryParse(
          //                               item["jobStatus"].toString(),
          //                             ) ??
          //                             0;
          //                         final searchMatch =
          //                             item["jobNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["plateNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true ||
          //                             item["vinNo"]
          //                                     ?.toString()
          //                                     .toLowerCase()
          //                                     .contains(searchText) ==
          //                                 true;
          //                         return (status == 10 ||
          //                                 status == 11 ||
          //                                 status == 18) &&
          //                             searchMatch;
          //                       }).toList();
          //                       if (reAssignedList.isEmpty) {
          //                         return RefreshIndicator(
          //                           onRefresh: refreshData,
          //                           child: ListView(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             children: [
          //                               SizedBox(
          //                                 height:
          //                                     MediaQuery.sizeOf(
          //                                       context,
          //                                     ).height *
          //                                     0.5,
          //                                 child: Center(
          //                                   child: emptyJobCardContainer(
          //                                     title: "No Reassigned Jobs",
          //                                     subtitle:
          //                                         "There are no reassigned job cards available.",
          //                                   ),
          //                                 ),
          //                               ),
          //                             ],
          //                           ),
          //                         );
          //                       }
          //                       return RefreshIndicator(
          //                         onRefresh: refreshData,
          //                         child: Padding(
          //                           padding: const EdgeInsets.all(5),
          //                           child: ListView.separated(
          //                             physics:
          //                                 const AlwaysScrollableScrollPhysics(),
          //                             itemCount: reAssignedList.length,
          //                             separatorBuilder: (_, __) =>
          //                                 const SizedBox(height: 0),
          //                             itemBuilder: (context, index) {
          //                               return jobCardItemTechinician(
          //                                 context,
          //                                 reAssignedList[index],
          //                               );
          //                             },
          //                           ),
          //                         ),
          //                       );
          //                     },
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         ),
          //       );
          //     },
          //   ),
          // ],
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
        final dynamic rawJobId = item['jobId'];
        final int jobId = rawJobId is int
            ? rawJobId
            : int.tryParse(rawJobId?.toString() ?? '0') ?? 0;
        if (jobStatus == 3) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 4) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 5) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 11) {
          context.go("/reassigneddetails", extra: jobId);
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

  Widget jobCardItemlist(BuildContext context, Map<String, dynamic> item) {
    final controller = Provider.of<HomescreenController>(
      context,
      listen: false,
    );
    final String jobStatusStr = item['jobStatus']?.toString().trim() ?? "";
    final int jobStatus = int.tryParse(jobStatusStr) ?? 0;
    final technicianId = item["jobTechnicianId"];
    final String statusText = controller.getJobStatusText(jobStatusStr);
    return GestureDetector(
      onTap: () {
        final dynamic rawJobId = item['jobId'];
        final int jobId = rawJobId is int
            ? rawJobId
            : int.tryParse(rawJobId?.toString() ?? '0') ?? 0;
        if (jobStatus == 10 || jobStatus == 11 || jobStatus == 18) {
          context.go("/reassigneddetails", extra: jobId);
        } else {
          context.go("/jobcarddetails", extra: jobId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: ColorConstants.whiteColor,
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: ColorConstants.containergreycolor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    "assets/image/benz.png",
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['jobNo'] ?? "",
                              style: ApptextstyleConstants.regularText(
                                fontSize: 16,
                                color: ColorConstants.blackColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: controller.getJobStatusColor(
                                jobStatus.toString(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (technicianId != null) const SizedBox(height: 8),
                      Text(
                        "Plate No : ${item['plateNo'] ?? ''}",
                        style: ApptextstyleConstants.lightText(
                          fontSize: 13,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Vin No: ${item['vinNo'] ?? ''}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ApptextstyleConstants.lightText(
                          fontSize: 12,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget jobCardItemTechinician(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final controller = Provider.of<HomescreenController>(
      context,
      listen: false,
    );
    final String jobStatusStr = item['jobStatus']?.toString().trim() ?? "";
    final int jobStatus = int.tryParse(jobStatusStr) ?? 0;
    final technicianId = item["jobTechnicianId"];
    final String statusText = controller.getJobStatusText(jobStatusStr);
    return GestureDetector(
      onTap: () {
        final int jobId = int.tryParse(item["jobId"]?.toString() ?? "0") ?? 0;
        if (jobStatus == 10 || jobStatus == 11 || jobStatus == 18) {
          context.go("/reassigneddetails", extra: jobId);
          return;
        }
        final List inspections = item["inspections"] ?? [];
        int inspectionTypeId = 2;
        int inspectionMasterId = 0;
        if (inspections.isNotEmpty) {
          final master = inspections.first["master"];
          inspectionTypeId =
              int.tryParse(master?["vimInspectionType"]?.toString() ?? "2") ??
              2;
          inspectionMasterId =
              int.tryParse(master?["vimIfMasterId"]?.toString() ?? "0") ?? 0;
        }
        context.go(
          "/inspectiontypedetailspage",
          extra: {
            "inspectionFormId": inspectionMasterId,
            "jobId": jobId,
            "inspectionTypeId": inspectionTypeId,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: ColorConstants.whiteColor,
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                /// IMAGE
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: ColorConstants.containergreycolor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    "assets/image/benz.png",
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['jobNo'] ?? "",
                              style: ApptextstyleConstants.regularText(
                                fontSize: 16,
                                color: ColorConstants.blackColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: controller.getJobStatusColor(
                                jobStatus.toString(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (technicianId != null) const SizedBox(height: 8),

                      /// PLATE
                      Text(
                        "Plate No : ${item['plateNo'] ?? ''}",
                        style: ApptextstyleConstants.lightText(
                          fontSize: 13,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Vin No: ${item['vinNo'] ?? ''}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ApptextstyleConstants.lightText(
                          fontSize: 12,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget emptyJobCardContainer({
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.blue.withOpacity(.3),
            blurStyle: BlurStyle.outer,
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget inspectionShimmer() {
    return Shimmer(
      duration: const Duration(seconds: 15),
      color: Colors.white,
      colorOpacity: 0.3,
      child: Column(
        children: List.generate(
          8,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade300,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 150,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 200,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
