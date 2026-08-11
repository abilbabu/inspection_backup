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
  final bool isComplaintEditable;
  const VehicleSummaryWidget({
    super.key,
    this.jobId,
    this.fetchBasicInspection = true,
    this.isComplaintEditable = false,
  });
  @override
  State<VehicleSummaryWidget> createState() => _vehicleSummaryWidgetState();
}

class _vehicleSummaryWidgetState extends State<VehicleSummaryWidget> {
  TextEditingController additionalCommentsController = TextEditingController();
  bool _isComplaintInitialized = false;

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
        final String? jobLaabsJobcardno =
            (jobcard['jobLaabsJobcardno'] ??
                    jobcard['laabsjobCardNo'] ??
                    jobcard['laabsJobCardNo'])
                ?.toString();
        final bool showLaabs =
            jobLaabsJobcardno != null &&
            jobLaabsJobcardno.trim().isNotEmpty &&
            jobLaabsJobcardno.trim().toLowerCase() != 'null';

        final String typeStr = (jobcard["inspectionType"] ?? jobcard["jobInspectionType"] ?? "").toString().trim().toUpperCase();
        final bool isQuick = typeStr == "QUICK" || typeStr.contains("QUICK") || jobcard["isQuick"] == true;

        return Container(
          decoration: BoxDecoration(
            color: ColorConstants.whiteColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    color: isQuick ? Colors.amber.shade700 : Colors.green.shade600,
                  ),
                  Expanded(
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
                                                color: ColorConstants.textBlueColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                    ],
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
                                                "${jobcard['jobCardNo'] ?? jobcard['jobNo'] ?? ''} ( ${formatDateTime(jobcard['jobCreatedOn'])} )",
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
                                    SizedBox(height: 3),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Consumer<BasicInspectionReportController>(
                            builder: (context, basicController, child) {
                              final String complaint = jobcard['customerComplaint']?.toString() ?? "";
                              if (widget.isComplaintEditable && !_isComplaintInitialized) {
                                additionalCommentsController.text = complaint;
                                _isComplaintInitialized = true;
                              }

                              if (widget.isComplaintEditable) {
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Customer Complaint:",
                                            style: ApptextstyleConstants.thinText(
                                              fontSize: 10,
                                              color: ColorConstants.blackColor,
                                            ).copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, size: 22, color: ColorConstants.greenColor),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              final scaffold = ScaffoldMessenger.of(context);
                                              final success = await context.read<BasicInspectionReportController>().saveCustomerComplaint(
                                                widget.jobId!,
                                                additionalCommentsController.text.trim(),
                                              );
                                              if (success) {
                                                context.read<JobcarddetailsController>().postJobCardDetails(widget.jobId!);
                                                scaffold.showSnackBar(
                                                  const SnackBar(
                                                    content: Text("Complaint updated successfully"),
                                                    backgroundColor: ColorConstants.greenColor,
                                                  ),
                                                );
                                              } else {
                                                scaffold.showSnackBar(
                                                  const SnackBar(
                                                    content: Text("Failed to update complaint"),
                                                    backgroundColor: ColorConstants.errorcolor,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: additionalCommentsController,
                                        maxLines: 3,
                                        textCapitalization: TextCapitalization.sentences,
                                        decoration: InputDecoration(
                                          hintText: "Enter customer complaint",
                                          hintStyle: ApptextstyleConstants.thinText(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                          contentPadding: const EdgeInsets.all(8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade400),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade400),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: ColorConstants.errorcolor),
                                          ),
                                        ),
                                        style: ApptextstyleConstants.thinText(
                                          fontSize: 10,
                                          color: ColorConstants.blackColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final complaintList = complaint
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
                  ),
                ],
              ),
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
        final String? jobLaabsJobcardno =
            (jobcard['jobLaabsJobcardno'] ??
                    jobcard['laabsjobCardNo'] ??
                    jobcard['laabsJobCardNo'])
                ?.toString();
        final bool showLaabs =
            jobLaabsJobcardno != null &&
            jobLaabsJobcardno.trim().isNotEmpty &&
            jobLaabsJobcardno.trim().toLowerCase() != 'null';

        final String typeStr = (jobcard["inspectionType"] ?? jobcard["jobInspectionType"] ?? "").toString().trim().toUpperCase();
        final bool isQuick = typeStr == "QUICK" || typeStr.contains("QUICK") || jobcard["isQuick"] == true;

        return Container(
          decoration: BoxDecoration(
            color: ColorConstants.whiteColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ColorConstants.dashboardboxShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    color: isQuick ? Colors.amber.shade700 : Colors.green.shade600,
                  ),
                  Expanded(
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
                                    text: "Job Card No: ",
                                    style: ApptextstyleConstants.thinText(
                                      fontSize: 10,
                                      color: ColorConstants.blackColor,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(
                                        text:
                                            "${jobcard['jobCardNo'] ?? jobcard['jobNo'] ?? ''} ( ${formatDateTime(jobcard['jobCreatedOn'])} )",
                                        style: ApptextstyleConstants.thinText(
                                          fontSize: 10,
                                          color: ColorConstants.textBlueColor,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                  SizedBox(height: 5),
                                ],
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
