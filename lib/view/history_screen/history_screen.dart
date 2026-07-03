import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreenList extends StatefulWidget {
  const HistoryScreenList({super.key});

  @override
  State<HistoryScreenList> createState() => _HistoryScreenListState();
}

class _HistoryScreenListState extends State<HistoryScreenList> {
  TextEditingController searchController = TextEditingController();
  String searchText = "";
  int userDepartment = 0;
  List historyList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserDepartment();
    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.toLowerCase();
      });
      getHistoryList();
    });
  }

  Future<void> loadUserDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userDepartment =
          int.tryParse(prefs.getString("userDepartment") ?? "0") ?? 0;
    });
    await getHistoryList();
  }

  Future<void> getHistoryList() async {
    setState(() {
      isLoading = true;
    });
    final rawList = await fetchJobCardHistory();
    final filteredList = rawList.where((item) {
      final status = int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;
      final searchMatch =
          item["jobNo"]?.toString().toLowerCase().contains(searchText) ==
              true ||
          item["plateNo"]?.toString().toLowerCase().contains(searchText) ==
              true ||
          item["vinNo"]?.toString().toLowerCase().contains(searchText) == true;
      if (userDepartment == 2 || userDepartment == 4 || userDepartment == 5) {
        return (status == 6 || status == 12 || status == 9 || status == 14) && searchMatch;
      }
      return [6, 7, 8, 9, 12, 14, 15, 16, 17, 18, 19].contains(status) && searchMatch;
    }).toList();
    setState(() {
      historyList = filteredList.reversed.toList();
      isLoading = false;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "JobCard List History",
        onBackPress: () {
          context.go('/history');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              height: 60,

              decoration: BoxDecoration(
                boxShadow: ColorConstants.dashboardboxShadow,

                color: ColorConstants.whiteColor,

                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search Job Card No",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),

                              borderSide: BorderSide(
                                color: ColorConstants.activecolor,
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),

                              borderSide: BorderSide(
                                color: ColorConstants.activecolor,
                              ),
                            ),

                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),

                    InkWell(
                      onTap: () {
                        searchController.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SvgPicture.asset(
                          'assets/svg/repeat.svg',
                          width: 20,
                          height: 20,

                          colorFilter: ColorFilter.mode(
                            ColorConstants.blackColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : historyList.isEmpty
                  ? Center(child: noJobCardCard())
                  : RefreshIndicator(
                      onRefresh: getHistoryList,
                      child: ListView.separated(
                        itemCount: historyList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return jobCardItemlist(context, historyList[index]);
                        },
                      ),
                    ),
            ),
          ],
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
    final String statusText = controller.getJobStatusText(jobStatusStr);
    return GestureDetector(
      onTap: () {
        final dynamic rawJobId = item['jobId'];
        final int jobId = rawJobId is int
            ? rawJobId
            : int.tryParse(rawJobId?.toString() ?? '0') ?? 0;
        if ([6, 7, 8, 9, 12, 14, 15, 16, 17, 18, 19].contains(jobStatus)) {
          context.go("/jobcarddetails", extra: jobId);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
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
                child: Image.asset("assets/image/benz.png", fit: BoxFit.cover),
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
                    Text(
                      "Plate No : ${item['plateNo'] ?? ''}",
                      style: ApptextstyleConstants.lightText(
                        fontSize: 13,
                        color: ColorConstants.blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Vin No : ${item['vinNo'] ?? ''}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ApptextstyleConstants.lightText(
                        fontSize: 12,
                        color: ColorConstants.blackColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget noJobCardCard() {
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
        children: const [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No Completed Job Cards",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

Future<List<dynamic>> fetchJobCardHistory() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userToken = prefs.getString('userToken');
    final userId = prefs.getString('userId');
    final userDepartment = prefs.getString('userDepartment');
    if (userId == null || userToken == null || userDepartment == null) {
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
        "userDepartment": int.parse(userDepartment),
      }),
    );
    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      final List rawList = res["data"] ?? [];
      return rawList.map((item) {
        final vehicle = item["vehicle"] ?? {};
        return {
          "jobId": item["jobId"]?.toString() ?? "",
          "jobNo": item["jobNo"]?.toString() ?? "",
          "plateNo": vehicle["vRegNo"]?.toString() ?? "",
          "vinNo": vehicle["vVinNo"]?.toString() ?? "",
          "jobStatus": item["jobStatus"]?.toString() ?? "",
          "jobCreatedOn": item["jobCreatedOn"] ?? "",
          "vehicle": vehicle,
        };
      }).toList();
    }
    return [];
  } catch (e) {
    debugPrint("fetchJobCardHistory Error : $e");
    return [];
  }
}
