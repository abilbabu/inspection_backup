import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/authentication_%20controller.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/controller/inspectionReportshare_controller.dart';
import 'package:inspection/controller/inspectionSummaryPage_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/controller/vehicleDetails_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:provider/provider.dart';
import 'package:share_link/share_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobCardDetails extends StatefulWidget {
  final int jobId;

  const JobCardDetails({super.key, required this.jobId});

  @override
  State<JobCardDetails> createState() => _JobCardDetailsState();
}

class _JobCardDetailsState extends State<JobCardDetails> {
  void _goBack() {
    final authCtrl = context.read<AuthenticationController>();
    final int userDepartment = authCtrl.userDepartment;
    final bool isJobCardDepartment =
        userDepartment == 2 || userDepartment == 4 || userDepartment == 5;
    final List<String> routes = isJobCardDepartment
        ? ['/home', '/history', '/settings']
        : ['/home', '/quotation', '/history', '/settings'];
    final int index = authCtrl.currentIndex;
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    } else {
      context.go('/home');
    }
  }

  @override
  void initState() {
    //  debugPrint('Job ID: ${widget.jobId}');
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<InspectionsummarypageController>().getInspectionSummary(
        widget.jobId,
      );
      Future.microtask(() {
        context.read<JobcarddetailsController>().getInspectionListByUserId();
      });
      final jobCtrl = context.read<JobcarddetailsController>();
      final custCtrl = context.read<CustomerDetailsController>();
      final vehicleCtrl = context.read<VehicleDetailsController>();
      jobCtrl.reset();
      await jobCtrl.postJobCardDetails(widget.jobId);
      await custCtrl.getFuelTypeList();
      await custCtrl.getTransmissionList();
      await vehicleCtrl.getCustomerTypeList();
      await custCtrl.getServiceTypeList();
      jobCtrl.mapFuelAndTransmissionNames(custCtrl);
    });
  }

  String getJobStatusText(dynamic status) {
    final String value = status?.toString() ?? "";
    switch (value) {
      case "0":
        return "Bookingsheet Initialized";
      case "1":
        return "Bookingsheet Created";
      case "2":
        return "Basic Inspection In Progress";
      case "3":
        return "Jobcard Open";
      case "4":
        return "Inspection Started";
      case "5":
        return "Inspection In Progress";
      case "6":
        return "Inspection Completed";
      case "7":
        return "Technician Report In Progress";
      case "8":
        return "Technician Report Waiting For Approval";
      case "9":
        return "Quotation Requested";
      case "10":
        return "Re-Inspection Approved";
      case "11":
        return "Re-Inspection In Progress";
      case "12":
        return "Re-Inspection Completed";
      default:
        return "Unknown Status";
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InspectionsummarypageController>();
    return Stack(
      children: [
        PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            _goBack();
          },
          child: Scaffold(
            appBar: CustomAppBar(
              title: "Job Card Details",
              onBackPress: () {
                _goBack();
              },
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Consumer<JobcarddetailsController>(
                builder: (context, jobController, child) {
                  if (jobController.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (jobController.jobCardData == null) {
                    return Center(
                      child: Text(
                        "No Job Card Data Found",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final data = jobController.jobCardData!;
                  final userDepartment = jobController.userDepartment!;
                  final jobcard = data["jobcard"];
                  final customer = jobcard?["customer"];
                  final vehicle = jobcard?["vehicle"];
                  final int jobStatus =
                      int.tryParse(jobcard?["jobStatus"]?.toString() ?? "") ??
                      -1;
                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          VehicleSummaryWidget(jobId: widget.jobId),
                          SizedBox(height: 15),
                          if (jobStatus != 5 &&
                              userDepartment != 3 &&
                              jobStatus != 6 &&
                              jobController.isTechnicianAssigned == false)
                            Align(
                              alignment: Alignment.centerRight,
                              child: CustomButtonWidget(
                                text: "START INSPECTION",
                                textSize: 16,
                                onPressed: () async {
                                  try {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    String? userToken = prefs.getString(
                                      'userToken',
                                    );
                                    String? userId = prefs.getString('userId');
                                    int assignedBy =
                                        int.tryParse(userId ?? "0") ?? 0;
                                    final url = Uri.parse(
                                      ApiServices.startInspection,
                                    );
                                    final output = {
                                      "jobId": widget.jobId,
                                      "status": 4,
                                      "vimIfMasterId": "",
                                      "assignedBy": assignedBy,
                                    };
                                    final response = await http.post(
                                      url,
                                      headers: {
                                        "Content-Type": "application/json",
                                        "Authorization": "Bearer $userToken",
                                      },
                                      body: jsonEncode(output),
                                    );
                                    Map<String, dynamic> decoded = jsonDecode(
                                      response.body,
                                    );
                                    decoded.forEach((key, value) {
                                      print("   $key : $value");
                                    });
                                    if (response.statusCode == 200) {
                                      context.push(
                                        "/inspectiondetails",
                                        extra: widget.jobId,
                                      );
                                      return;
                                    }
                                  } catch (e) {
                                    print(e);
                                  }
                                },
                              ),
                            ),
                          if (jobController.isTechnicianAssigned &&
                              userDepartment != 3) ...[
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ColorConstants.greenColor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ColorConstants.greenColor,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Assigned Technician : ${jobController.assignedTechnicianName?.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ')}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.greenColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (userDepartment == 3) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ColorConstants.orangecolor.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ColorConstants.orangecolor,
                                ),
                              ),
                              child: Center(
                                child: const Text(
                                  "Job Controller Already Revert",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.orangecolor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 12),
                          if (userDepartment != 2 &&
                              userDepartment != 4 &&
                              userDepartment != 5) ...[
                            _shareOptions(context),
                            _customerDetilas(
                              customer,
                              jobController,
                              vehicle,
                              jobcard,
                            ),
                            SizedBox(height: 5),
                            _basicInspectionReport(context),
                          ],
                          SizedBox(height: 5),
                          if (jobStatus == 5 &&
                              !((userDepartment == 2 ||
                                      userDepartment == 5 ||
                                      userDepartment == 3) &&
                                  jobController.isTechnicianAssigned))
                            Builder(
                              builder: (context) {
                                final item = jobController.jobcardList
                                    .firstWhere(
                                      (e) =>
                                          e['jobId'].toString() ==
                                          widget.jobId.toString(),
                                      orElse: () => {},
                                    );

                                if (item.isEmpty) return SizedBox();
                                return _inspectionFrom(
                                  context,
                                  controller,
                                  item,
                                );
                              },
                            ),
                          if ((userDepartment == 0 || userDepartment == 1) &&
                              jobController.isTechnicianAssigned &&
                              ![5, 6, 7, 8, 9, 10].contains(jobStatus))
                            Builder(
                              builder: (context) {
                                final item = jobController.jobcardList
                                    .firstWhere(
                                      (e) =>
                                          e['jobId'].toString() ==
                                          widget.jobId.toString(),
                                      orElse: () => {},
                                    );
                                if (item.isEmpty) return const SizedBox();
                                return _inspTechnician(
                                  context,
                                  controller,
                                  item,
                                );
                              },
                            ),
                          if ([6, 7, 8, 9].contains(jobStatus))
                            _inspectionsummarypage(context, controller),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Consumer<JobcarddetailsController>(
          builder: (context, controller, child) {
            if (!controller.isDownloading) return SizedBox();
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: ColorConstants.syanColor),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _inspTechnician(
    BuildContext context,
    InspectionsummarypageController controller,
    Map<String, dynamic> item,
  ) {
    return InkWell(
      onTap: () {
        context.push("/inspectiondetails", extra: widget.jobId);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ColorConstants.dashboardboxShadow,
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/image/Car_logo.png",
                    height: 50,
                    width: 50,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Inspection Details go",
                      textAlign: TextAlign.center,
                      style: ApptextstyleConstants.thinText(
                        fontSize: 16,
                        color: ColorConstants.textcolor2,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inspectionFrom(
    BuildContext context,
    InspectionsummarypageController controller,
    Map<String, dynamic> item,
  ) {
    return InkWell(
      onTap: () {
        final rawJobId = item['jobId'];
        final rawInspections = item['inspections'];
        final inspectionTypeid = controller.vimInspectionTypeId;
        final int jobId = int.tryParse(rawJobId?.toString() ?? '0') ?? 0;
        final List inspections = rawInspections is List ? rawInspections : [];
        int inspectionMasterId = 0;
        for (final inspection in inspections) {
          if (inspection is! Map) continue;
          final rawId = inspection['master']?['vimIfMasterId'];
          final int parsedId = int.tryParse(rawId?.toString() ?? '0') ?? 0;
          if (parsedId > 0) {
            inspectionMasterId = parsedId;
            break;
          }
        }
        context.go(
          "/inspectiontypedetailspage",
          extra: {
            "inspectionFormId": inspectionMasterId,
            "jobId": jobId,
            "inspectionTypeId": inspectionTypeid,
          },
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ColorConstants.dashboardboxShadow,
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/image/Car_logo.png",
                    height: 50,
                    width: 50,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "${controller.vimInspectionTypeId == 2 ? 'Custom Inspection' : controller.inspectionFormName} - In Progress",
                      textAlign: TextAlign.center,
                      style: ApptextstyleConstants.thinText(
                        fontSize: 16,
                        color: ColorConstants.textcolor2,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inspectionsummarypage(
    BuildContext context,
    InspectionsummarypageController controller,
  ) {
    return InkWell(
      onTap: () {
        context.go(
          "/inspectionsummarypage",
          extra: {"jobId": widget.jobId, "flag": 1},
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ColorConstants.dashboardboxShadow,
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/image/Car_logo.png",
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          controller.vimInspectionTypeId == 2
                              ? "Custom Inspection"
                              : controller.inspectionFormName,
                          textAlign: TextAlign.center,
                          style: ApptextstyleConstants.thinText(
                            fontSize: 16,
                            color: ColorConstants.textcolor2,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _basicInspectionReport(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push("/basicInspectionReport", extra: widget.jobId);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ColorConstants.dashboardboxShadow,
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/image/Car_logo.png",
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "View Basic Inspections",
                          textAlign: TextAlign.center,
                          style: ApptextstyleConstants.italicText(
                            fontSize: 16,
                            color: ColorConstants.textcolor2,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerDetilas(
    customer,
    JobcarddetailsController jobController,
    vehicle,
    jobcard,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ColorConstants.dashboardboxShadow,
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  "assets/image/summary.png",
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        "Customer:",
                        "${customer["custName"] ?? ""} "
                            "(${customer["custCountryCode"] ?? ""}"
                            "${customer["custMobile"] ?? ""})",
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              "Pre lang:",
                              customer["custLanguage"] ?? "",
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: _buildInfoRow(
                              "Cust Type:",
                              jobController.customerTypeName,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              "VIN:",
                              vehicle["vVinNo"] ?? "",
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: _buildInfoRow(
                              "Engine:",
                              vehicle["vEng"] ?? "",
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              "Transmission:",
                              jobController.transmissionTypeName,
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: _buildInfoRow(
                              "Fuel Type:",
                              jobController.fuelTypeName,
                            ),
                          ),
                        ],
                      ),
                      _buildInfoRow(
                        "Service Type:",
                        jobController.serviceTypeName,
                      ),
                      _buildInfoRow(
                        "Status:",
                        getJobStatusText(jobcard["jobStatus"]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Row _shareOptions(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100),
        Spacer(),
        InkWell(
          onTap: () {
            final jobId = widget.jobId;
            showShareOptions(context, jobId);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066A6), Color(0xFF04DDC0)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ColorConstants.dashboardboxShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 8,
                ),
                child: SvgPicture.asset(
                  'assets/svg/shareLinks.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        InkWell(
          onTap: () async {
            final jobController = context.read<JobcarddetailsController>();
            final customer = jobController.jobCardData?['jobcard']?['customer'];
            final phone = jobController.formatPhone(
              customer?['custCountryCode'] ?? '',
              customer?['custMobile'] ?? '',
            );
            if (phone.isEmpty) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Phone number missing")));
              return;
            }
            jobController.setDownloading(true);
            final filePath = await jobController.downloadInspectionPdf(
              widget.jobId,
              phone,
            );
            jobController.setDownloading(false);
            if (filePath == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Failed to download PDF",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: ColorConstants.holdorangeColor,
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "PDF saved to Downloads",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: ColorConstants.greenColor,
              ),
            );
            await jobController.openWhatsApp(
              phone,
              "Hello ${customer?['custName'] ?? ''},\nYour inspection report is ready.\nPlease find the PDF attached.",
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066A6), Color(0xFF04DDC0)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ColorConstants.dashboardboxShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: SvgPicture.asset(
                  'assets/svg/whatsapp.svg',
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
      ],
    );
  }
}

void showShareOptions(BuildContext parentContext, int jobId) {
  showDialog(
    context: parentContext,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Center(child: Text("Select Option")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _optionTile(
              parentContext,
              dialogContext,
              "✅ All included",
              "ALL",
              jobId,
            ),
            _optionTile(
              parentContext,
              dialogContext,
              "🔇 Without audio",
              "NO_AUDIO",
              jobId,
            ),
            _optionTile(
              parentContext,
              dialogContext,
              "🎥 Without video",
              "NO_VIDEO",
              jobId,
            ),
            _optionTile(
              parentContext,
              dialogContext,
              "🚫 Without audio & video",
              "NO_AUDIO_VIDEO",
              jobId,
            ),
          ],
        ),
      );
    },
  );
}

Widget _optionTile(
  BuildContext parentContext,
  BuildContext dialogContext,
  String title,
  String mode,
  int jobId,
) {
  return InkWell(
    onTap: () async {
      Navigator.pop(dialogContext);
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        final controller = parentContext
            .read<InspectionreportshareController>();
        final int attachmentMode = controller.mapModeToNumber(mode);
        final response = await controller.shareInspectionSummary(
          jobId,
          attachmentMode: attachmentMode,
          expiryHours: 2,
        );
        if (!parentContext.mounted) return;
        if (response.success == true) {
          final link = response.data?["shareUrl"] ?? "";
          final expiry = controller.formatExpiry(response.data?["expiresAt"]);
          _showInspectionDialog(parentContext, jobId, link, expiry, mode);
        } else {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text("Unable to generate link")),
          );
        }
      } catch (e) {
        print("🔥 ERROR: $e");
      }
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Center(child: Text(title, style: const TextStyle(fontSize: 16))),
    ),
  );
}

void _showInspectionDialog(
  BuildContext context,
  int jobId,
  String link,
  String expiry,
  String mode,
) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Inspection link is ready",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Share this inspection report with the customer.",
                style: TextStyle(color: ColorConstants.activecolor),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: ColorConstants.activecolor),
                  color: ColorConstants.boxColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  link,
                  style: TextStyle(color: ColorConstants.warningcolor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    size: 13,
                    color: ColorConstants.greenColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Expires: $expiry",
                    style: ApptextstyleConstants.lightText(
                      color: ColorConstants.greenColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Link copied",
                              style: ApptextstyleConstants.mediumText(
                                color: ColorConstants.whiteColor,
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: ColorConstants.greenColor,
                          ),
                        );
                        Future.delayed(const Duration(milliseconds: 50), () {
                          Navigator.pop(context);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: ColorConstants.activecolor),
                          color: ColorConstants.boxColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.copy,
                                  color: ColorConstants.blackColor,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "COPY LINK",
                                  style: ApptextstyleConstants.lightText(
                                    color: ColorConstants.blackColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final Uri uri = Uri.parse(link);
                        await ShareLink.shareUri(uri);
                        Future.delayed(const Duration(milliseconds: 50), () {
                          Navigator.pop(context);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: ColorConstants.activecolor),
                          color: ColorConstants.boxColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.share,
                                  color: ColorConstants.blackColor,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "SHARE LINK",
                                  style: ApptextstyleConstants.lightText(
                                    color: ColorConstants.blackColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: ColorConstants.greyColor),
                    color: ColorConstants.boxColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "CLOSE",
                      style: ApptextstyleConstants.lightText(
                        color: ColorConstants.blackColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        text: "$label ",
        style: ApptextstyleConstants.thinText(
          fontSize: 10,
          color: ColorConstants.blackColor,
        ).copyWith(fontWeight: FontWeight.bold),
        children: [
          TextSpan(
            text: value,
            style:
                valueStyle ??
                ApptextstyleConstants.lightText(
                  fontSize: 10,
                  color: ColorConstants.textBlueColor,
                ),
          ),
        ],
      ),
    ),
  );
}
