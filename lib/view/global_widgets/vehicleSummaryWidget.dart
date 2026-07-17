// ignore_for_file: use_build_context_synchronously, camel_case_types

import 'package:flutter/material.dart';
import 'package:inspection/controller/basicInspectionReport_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VehicleSummaryWidget extends StatefulWidget {
  final int? jobId;
  final bool fetchBasicInspection;
  const VehicleSummaryWidget({
    super.key,
    this.jobId,
    this.fetchBasicInspection = true,
  });
  @override
  State<VehicleSummaryWidget> createState() => _vehicleSummaryWidgetState();
}

class _vehicleSummaryWidgetState extends State<VehicleSummaryWidget> {
  TextEditingController additionalCommentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.jobId != null) {
        context.read<JobcarddetailsController>().postJobCardDetails(
          widget.jobId!,
        );
        if (widget.fetchBasicInspection) {
          context.read<BasicInspectionReportController>().getBasicInspection(
            widget.jobId!,
            forceRefresh: true,
          );
        }
      }
    });
  }

  String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobcarddetailsController>(
      builder: (context, controller, child) {
        final root = controller.jobCardData;
        final jobcard = root?['jobcard'] ?? {};
        final vehicle = jobcard['vehicle'] ?? {};
        return Container(
          decoration: BoxDecoration(
            color: ColorConstants.whiteColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: ColorConstants.containergreycolor,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        "assets/image/benz.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                        text: TextSpan(
                          text: "Laabs Job Card No: ",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text:
                                 "ghhghh",
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.textBlueColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3),
                          RichText(
                            text: TextSpan(
                              text: "Job Card No: ",
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.blackColor,
                              ).copyWith(fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text:
                                      "${jobcard['jobNo'] ?? ''} ( ${formatDateTime(jobcard['jobCreatedOn'])} )",
                                  style: ApptextstyleConstants.thinText(
                                    fontSize: 10,
                                    color: ColorConstants.textBlueColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 3),
                          RichText(
                            text: TextSpan(
                              text: "Plate No:  ",
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.blackColor,
                              ).copyWith(fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: vehicle['vRegNo']?.toString() ?? '',
                                  style: ApptextstyleConstants.thinText(
                                    fontSize: 10,
                                    color: ColorConstants.textBlueColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 3),
                          RichText(
                            text: TextSpan(
                              text: "Vin number:  ",
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.blackColor,
                              ).copyWith(fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: vehicle["vVinNo"]?.toString() ?? '',
                                  style: ApptextstyleConstants.thinText(
                                    fontSize: 10,
                                    color: ColorConstants.textBlueColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 3)
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Consumer<BasicInspectionReportController>(
                  builder: (context, basicController, child) {
                    final comments =
                        basicController.additionalCommentsController.text;
                    final complaintList = comments
                        .split('\n')
                        .where((e) => e.trim().isNotEmpty)
                        .toList();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorConstants.errorcolor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ColorConstants.errorcolor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customer Complaint:",
                            style: ApptextstyleConstants.thinText(
                              fontSize: 10,
                              color: ColorConstants.blackColor,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          if (complaintList.isEmpty)
                            Text(
                              "No Comments Recorded",
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.blackColor,
                              ),
                            )
                          else
                            ...complaintList.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  "• $item",
                                  style: ApptextstyleConstants.thinText(
                                    fontSize: 10,
                                    color: ColorConstants.blackColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VehicleSummaryWidgetTwo extends StatefulWidget {
  final int? jobId;

  const VehicleSummaryWidgetTwo({super.key, this.jobId});

  @override
  State<VehicleSummaryWidgetTwo> createState() =>
      _vehicleSummaryWidgetStateTwo();
}

class _vehicleSummaryWidgetStateTwo extends State<VehicleSummaryWidgetTwo> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.jobId != null) {
        Provider.of<JobcarddetailsController>(
          context,
          listen: false,
        ).postJobCardDetails(widget.jobId!);
      }
    });
  }

  String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobcarddetailsController>(
      builder: (context, controller, child) {
        final root = controller.jobCardData;
        final jobcard = root?['jobcard'] ?? {};
        final vehicle = jobcard['vehicle'] ?? {};
        return Container(
          decoration: BoxDecoration(
            color: ColorConstants.whiteColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: ColorConstants.containergreycolor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    "assets/image/benz.png",
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: "Laabs Job Card No: ",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text:
                                 "ghhghh",
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.textBlueColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          text: "Job Card No: ",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text:
                                  "${jobcard['jobNo'] ?? ''} ( ${formatDateTime(jobcard['jobCreatedOn'])} )",
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.textBlueColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          text: "Plate No:  ",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: vehicle['vRegNo']?.toString() ?? '',
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.textBlueColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          text: "Vin number:  ",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: vehicle["vVinNo"]?.toString() ?? '',
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.textBlueColor,
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
      },
    );
  }
}