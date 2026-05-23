import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:provider/provider.dart';

class Alljobcardview extends StatefulWidget {
  final List jobcardList;

  const Alljobcardview({super.key, required this.jobcardList});

  @override
  State<Alljobcardview> createState() => _AlljobcardviewState();
}

class _AlljobcardviewState extends State<Alljobcardview> {
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;
  List filteredList = [];
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    filteredList = widget.jobcardList.reversed.toList();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _triggerSearch(value);
    });
  }

  void _triggerSearch(String value) {
    final search = value.trim().toLowerCase();
    setState(() {
      filteredList = widget.jobcardList
          .where((item) {
            final jobNo = item["jobNo"]?.toString().toLowerCase() ?? "";
            final status = item["jobStatus"]?.toString() ?? "";
            bool statusMatch = true;
            if (selectedFilter == "Assigned") {
              statusMatch = status != "3";
            } else if (selectedFilter == "Unassigned") {
              statusMatch = status == "3";
            }
            return jobNo.contains(search) && statusMatch;
          })
          .toList()
          .reversed
          .toList();
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
          title: "All Job Cards",

          onBackPress: () {
            context.go('/home');
          },
        ),

        body: Padding(
          padding: const EdgeInsets.all(10),

          child: Column(
            children: [
              /// SEARCH + FILTER
              Container(
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
                                      setState(() {
                                        filteredList = widget.jobcardList.reversed
                                            .toList();
                                      });
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
                      /// FILTER
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade500)
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedFilter,
                            items: const [
                              DropdownMenuItem(value: "All", child: Text("All")),
                              DropdownMenuItem(
                                value: "Assigned",
                                child: Text("Assigned"),
                              ),
                              DropdownMenuItem(
                                value: "Pending",
                                child: Text("Pending"),
                              ),
                            ],
                            onChanged: (value) {
                              selectedFilter = value!;
                              _triggerSearch(searchController.text);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// LIST
              Expanded(
                child: ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: jobCardItem(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
        context.go("/jobcarddetails", extra: jobId);
      },

      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // gradient: ColorConstants.containergradientColor,
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

                /// DETAILS
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

                      const SizedBox(height: 6),
                      Text(
                        "Plate No : ${item['plateNo'] ?? ''}",
                        style: ApptextstyleConstants.lightText(
                          fontSize: 13,
                          color: ColorConstants.blackColor,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "VIN No : ${item['vinNo'] ?? ''}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ApptextstyleConstants.lightText(
                          fontSize: 12,
                          color: ColorConstants.blackColor,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        vehicleName,
                        style: ApptextstyleConstants.thinText(
                          fontSize: 12,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                      const SizedBox(height: 6),
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
}
