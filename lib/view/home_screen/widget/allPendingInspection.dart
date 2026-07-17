import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:provider/provider.dart';

import 'package:inspection/view/global_widgets/customAppBar.dart';

class Allpendinginspection extends StatefulWidget {
  final List inspectionList;

  const Allpendinginspection({super.key, required this.inspectionList});

  @override
  State<Allpendinginspection> createState() => _AllpendinginspectionState();
}

class _AllpendinginspectionState extends State<Allpendinginspection> {
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  List filteredList = [];

  @override
  void initState() {
    super.initState();

    filteredList = widget.inspectionList.reversed.toList();
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
        filteredList = widget.inspectionList.reversed.toList();
      } else {
        filteredList = widget.inspectionList
            .where((item) {
              final jobNo = item["jobNo"]?.toString().toLowerCase() ?? "";

              return jobNo.contains(search);
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
                                          filteredList = widget
                                              .inspectionList
                                              .reversed
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
                    
                        /// REFRESH BUTTON
                        InkWell(
                          onTap: () {
                            searchController.clear();
                    
                            setState(() {
                              filteredList = widget.inspectionList.reversed
                                  .toList();
                            });
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
                    
                            child: const Icon(Icons.refresh),
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
                child: ListView.builder(
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

                          if (jobStatus == 1) {
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

    final String? jobLaabsJobcardno = (data['jobLaabsJobcardno'] ?? data['laabsjobCardNo'] ?? data['laabsJobCardNo'])?.toString();
    final bool showLaabs = jobLaabsJobcardno != null &&
        jobLaabsJobcardno.trim().isNotEmpty &&
        jobLaabsJobcardno.trim().toLowerCase() != 'null';

    return Container(
      height: showLaabs ? 110 : 90,
      width: double.infinity,

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

            const SizedBox(width: 10),

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
                          text: "${data["jobNo"]}",

                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.greenColor,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    );
  }
}
