import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/status_badge_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Allpendinginspection extends StatefulWidget {
  final List inspectionList;

  const Allpendinginspection({super.key, required this.inspectionList});

  @override
  State<Allpendinginspection> createState() => _AllpendinginspectionState();
}

class _AllpendinginspectionState extends State<Allpendinginspection> {
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  List currentInspectionList = [];
  List filteredList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    currentInspectionList = List.from(widget.inspectionList);
    filteredList = currentInspectionList.reversed.toList();
    fetchPendingInspections();
  }

  Map<String, dynamic> _mapVehicleData(Map<String, dynamic> item) {
    final vehicle = item["vehicle"] ?? item["jobcard"]?["vehicle"] ?? {};
    final rawJobId = item["jobId"] ?? item["id"] ?? item["jobcard"]?["jobId"];
    final rawJobNo = item["jobNo"] ??
        item["jobCardNo"] ??
        item["jobcardNo"] ??
        item["jobcard"]?["jobNo"] ??
        item["jobcard"]?["jobCardNo"];
    final rawLaabsNo = item["jobLaabsJobcardno"] ??
        item["laabsjobCardNo"] ??
        item["laabsJobCardNo"] ??
        item["jobcard"]?["laabsjobCardNo"] ??
        item["jobcard"]?["laabsJobCardNo"];
    final rawStatus = item["jobStatus"] ??
        item["status"] ??
        item["jobCardStatus"] ??
        item["jobcard"]?["jobStatus"] ??
        item["jobcard"]?["status"];
    final HomescreenController helper = HomescreenController();
    final String normalizedStatus = helper.normalizeStatus(rawStatus?.toString());
    final rawCreatedOn = item["jobCreatedOn"] ??
        item["jobcard"]?["jobCreatedOn"] ??
        item["createdOn"] ??
        item["createdAt"];
    final rawTechId =
        item["jobTechnicianId"] ?? item["jobcard"]?["jobTechnicianId"];

    return {
      ...item,
      "jobId": rawJobId?.toString() ?? "",
      "jobNo": rawJobNo?.toString() ?? "",
      "jobLaabsJobcardno": rawLaabsNo?.toString() ?? "",
      "make": vehicle["vMake"] ?? vehicle["make"] ?? "",
      "model": vehicle["vModel"] ?? vehicle["model"] ?? "",
      "year": (vehicle["vModelYear"] ?? vehicle["year"])?.toString() ?? "",
      "odometer": (vehicle["vOdometer"] ?? vehicle["odometer"])?.toString() ?? "",
      "plateNo": (vehicle["vRegNo"] ?? vehicle["plateNo"] ?? item["plateNo"])?.toString() ?? "",
      "vinNo": (vehicle["vVinNo"] ?? vehicle["vinNo"] ?? item["vinNo"])?.toString() ?? "",
      "jobStatus": normalizedStatus.isNotEmpty ? normalizedStatus : (rawStatus?.toString() ?? ""),
      "vehicleTypeId": vehicle["vTypeId"] ?? vehicle["vehicleTypeId"] ?? -1,
      "jobCreatedOn": rawCreatedOn?.toString() ?? "",
      "jobTechnicianId": rawTechId,
      "userDepartment": item["userDepartment"] ?? item["jobcard"]?["userDepartment"],
      "inspectionType": (item["inspectionType"] ??
              item["jobInspectionType"] ??
              item["jobcard"]?["jobInspectionType"])
          ?.toString() ??
          "",
      "isQuick": ColorConstants.isQuickInspection(item),
    };
  }

  Future<void> fetchPendingInspections() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      final userId = prefs.getString('userId');
      final userDepartment = prefs.getString('userDepartment');
      if (userId == null || userToken == null || userDepartment == null) {
        if (mounted) setState(() => isLoading = false);
        return;
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
        final data = res["data"];
        List rawList = [];
        if (data is Map && data.containsKey("content")) {
          rawList = data["content"] ?? [];
        } else if (data is List) {
          rawList = data;
        }

        final HomescreenController helper = HomescreenController();
        final List mappedList = rawList
            .where((item) {
              if (item is! Map) return false;
              final rawStatus = item["jobStatus"] ??
                  item["status"] ??
                  item["jobCardStatus"] ??
                  item["jobcard"]?["jobStatus"] ??
                  item["jobcard"]?["status"];
              final String normalized = helper.normalizeStatus(rawStatus?.toString());
              return normalized == "0" || normalized == "1" || normalized == "2";
            })
            .map((item) {
              return _mapVehicleData(item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item));
            })
            .toList();

        if (mounted) {
          setState(() {
            currentInspectionList = mappedList;
          });
          _triggerSearch(searchController.text);
        }
      }
    } catch (e) {
      debugPrint("Error fetching pending inspections: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 150), () {
      _triggerSearch(value);
    });
  }

  void _triggerSearch(String value) {
    final search = value.trim().toLowerCase();

    setState(() {
      if (search.isEmpty) {
        filteredList = currentInspectionList.reversed.toList();
      } else {
        filteredList = currentInspectionList
            .where((item) {
              final jobNo = (item["jobNo"] ?? "").toString().toLowerCase();
              final plateNo = (item["plateNo"] ?? "").toString().toLowerCase();
              final vinNo = (item["vinNo"] ?? "").toString().toLowerCase();
              final laabsNo = (item["jobLaabsJobcardno"] ?? "").toString().toLowerCase();
              final make = (item["make"] ?? "").toString().toLowerCase();
              final model = (item["model"] ?? "").toString().toLowerCase();

              return jobNo.contains(search) ||
                  plateNo.contains(search) ||
                  vinNo.contains(search) ||
                  laabsNo.contains(search) ||
                  make.contains(search) ||
                  model.contains(search);
            })
            .toList()
            .reversed
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvoked: (didPop) {
        context.go('/home');
      },

      child: Scaffold(
        appBar: CustomAppBar(
          title: "Basic Inspection Pending List",

          onBackPress: () {
            context.go('/home');
          },
        ),

        body: Padding(
          padding: const EdgeInsets.all(8),

          child: Column(
            children: [
              /// SEARCH FIELD
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    boxShadow: ColorConstants.dashboardboxShadow,
                    color: ColorConstants.whiteColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,

                            onChanged: (value) {
                              setState(() {});
                              _onSearchChanged(value);
                            },

                            onSubmitted: _triggerSearch,

                            decoration: InputDecoration(
                              hintText: "Search Job Card No, Plate, Vehicle",

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

                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),

                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  if (searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.close),

                                      onPressed: () {
                                        searchController.clear();
                                        _triggerSearch('');
                                      },
                                    ),

                                  IconButton(
                                    icon: const Icon(Icons.search),

                                    onPressed: () {
                                      _triggerSearch(searchController.text);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// REFRESH BUTTON
                        InkWell(
                          onTap: () {
                            searchController.clear();
                            fetchPendingInspections();
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

                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// LIST VIEW
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchPendingInspections,
                  child: isLoading && currentInspectionList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filteredList.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.25,
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "No pending inspections found",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(10),

                              itemCount: filteredList.length,

                              itemBuilder: (context, index) {
                                final item = filteredList[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),

                                  child: GestureDetector(
                                    onTap: () {
                                      final int jobId =
                                          int.tryParse(item["jobId"]?.toString() ?? "0") ??
                                          0;

                                      final int jobStatus =
                                          int.tryParse(
                                            item["jobStatus"]?.toString() ?? "0",
                                          ) ??
                                          0;

                                      final vehicle = item["vehicle"] ?? {};

                                      final int vId =
                                          int.tryParse(vehicle["vId"]?.toString() ?? "0") ??
                                          0;

                                      if (jobStatus == 0) {
                                        context.go(
                                          "/vehicledetails",
                                          extra: {"jobId": jobId},
                                        );
                                      } else if (jobStatus == 1) {
                                        context.go(
                                          "/vehiclecontents",

                                          extra: {"jobId": jobId, "vId": vId},
                                        );
                                      } else if (jobStatus == 2) {
                                        context.go("/basicinspection", extra: jobId);
                                      }
                                    },

                                    child: inspectionCard(context, item),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inspectionCard(BuildContext context, Map<String, dynamic> data) {
    final controller = Provider.of<HomescreenController>(
      context,
      listen: false,
    );

    final String jobStatusStr = data['jobStatus']?.toString().trim() ?? "";
    final String statusText = controller.getJobStatusText(jobStatusStr);
    final Color statusColor = controller.getJobStatusColor(jobStatusStr);

    final String? jobLaabsJobcardno =
        (data['jobLaabsJobcardno'] ?? data['laabsjobCardNo'] ?? data['laabsJobCardNo'])
            ?.toString();
    final bool showLaabs = jobLaabsJobcardno != null &&
        jobLaabsJobcardno.trim().isNotEmpty &&
        jobLaabsJobcardno.trim().toLowerCase() != 'null';

    final bool isQuick = ColorConstants.isQuickInspection(data);

    return Container(
      height: showLaabs ? 110 : 90,
      width: double.infinity,

      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,

        borderRadius: BorderRadius.circular(10),

        boxShadow: ColorConstants.dashboardboxShadow,
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 5,
              color: ColorConstants.getInspectionTypeIndicatorColor(isQuick),
            ),
            Expanded(
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

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: "Job Card No: ",

                                    style: ApptextstyleConstants.thinText(
                                      fontSize: 10,
                                      color: ColorConstants.blackColor,
                                    ).copyWith(fontWeight: FontWeight.bold),

                                    children: [
                                      TextSpan(
                                        text: "${data["jobNo"]}",

                                        style: ApptextstyleConstants.thinText(
                                          fontSize: 10,
                                          color: ColorConstants.greenColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              StatusBadgeWidget(
                                statusText: statusText,
                                statusColor: statusColor,
                                showDot: false,
                                fontSize: 8,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          if (showLaabs) ...[
                            RichText(
                              text: TextSpan(
                                text: "Laabs Job Card No: ",
                                style: ApptextstyleConstants.thinText(
                                  fontSize: 10,
                                  color: ColorConstants.blackColor,
                                ).copyWith(fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                    text: jobLaabsJobcardno,
                                    style: ApptextstyleConstants.thinText(
                                      fontSize: 10,
                                      color: ColorConstants.greenColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],

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
            ),
          ],
        ),
      ),
    );
  }
}
