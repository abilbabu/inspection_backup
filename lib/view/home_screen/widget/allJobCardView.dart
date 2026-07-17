import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  int userDepartment = 0;

  @override
  void initState() {
    super.initState();

    filteredList = widget.jobcardList.reversed.toList();
    _triggerSearch('');

    if (widget.jobcardList.isNotEmpty) {
      userDepartment =
          int.tryParse(
            widget.jobcardList.first["userDepartment"]?.toString() ?? "0",
          ) ??
          0;
    }
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
    final searchText = value.trim().toLowerCase();

    setState(() {
      filteredList = widget.jobcardList
          .where((item) {
            final status = item["jobStatus"]?.toString() ?? "";
            final technicianId = item["jobTechnicianId"];

            bool statusMatch = true;

            if (selectedFilter == "Pending") {
              statusMatch = technicianId == null && status == "3";
            } else if (selectedFilter == "On going") {
              statusMatch = status == "4" || status == "5";
            } else if (selectedFilter == "Complete") {
              statusMatch =
                  status == "6" ||
                  status == "7" ||
                  status == "8" ||
                  status == "9";
            }

            final jobNo = (item['jobNo'] ?? '').toString().toLowerCase();
            final plateNo = (item['plateNo'] ?? '').toString().toLowerCase();
            final vinNo = (item['vinNo'] ?? '').toString().toLowerCase();

            final searchMatch =
                searchText.isEmpty ||
                jobNo.contains(searchText) ||
                plateNo.contains(searchText) ||
                vinNo.contains(searchText);

            return statusMatch && searchMatch;
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
                      /// SEARCH
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

                      const SizedBox(width: 5),

                      InkWell(
                        onTap: () {
                          searchController.clear();
                          _triggerSearch('');
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
                      const SizedBox(width: 5),

                      /// FILTER
                      Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 10),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),

                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedFilter,

                            borderRadius: BorderRadius.circular(12),

                            icon: const Icon(Icons.keyboard_arrow_down),

                            style: TextStyle(color: Colors.black, fontSize: 14),

                            items: const [
                              DropdownMenuItem(
                                value: "All",
                                child: Text("All"),
                              ),
                              // DropdownMenuItem(
                              //   value: "Assigned",
                              //   child: Text("Assigned"),
                              // ),
                              DropdownMenuItem(
                                value: "Pending",
                                child: Text("Pending"),
                              ),
                              DropdownMenuItem(
                                value: "On going",
                                child: Text("On going"),
                              ),
                              DropdownMenuItem(
                                value: "Complete",
                                child: Text("Complete"),
                              ),
                            ],

                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                selectedFilter = value;
                              });

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
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "No Data Found",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
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

    final technicianId = item["jobTechnicianId"];

    final String statusText = controller.getJobStatusText(jobStatusStr);

    final String? jobLaabsJobcardno =
        (item['jobLaabsJobcardno'] ??
                item['laabsjobCardNo'] ??
                item['laabsJobCardNo'])
            ?.toString();
    final bool showLaabs =
        jobLaabsJobcardno != null &&
        jobLaabsJobcardno.trim().isNotEmpty &&
        jobLaabsJobcardno.trim().toLowerCase() != 'null';

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
                      /// TOP ROW
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

                          /// STATUS
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
                      const SizedBox(height: 5),
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
                        const SizedBox(height: 4),
                      ],

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

                      /// VIN
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
