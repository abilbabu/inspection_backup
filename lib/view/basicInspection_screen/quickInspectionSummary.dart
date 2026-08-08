import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/basicInsp_controller.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/controller/vehicleDetails_controller.dart';
import 'package:inspection/controller/vehicleEssential_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/basicInspection_screen/basicinspection_previw.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspection/apiServices/api_services.dart';

class QuickInspectionSummaryPage extends StatefulWidget {
  final int jobId;
  const QuickInspectionSummaryPage({super.key, required this.jobId});

  @override
  State<QuickInspectionSummaryPage> createState() => _QuickInspectionSummaryPageState();
}

class _QuickInspectionSummaryPageState extends State<QuickInspectionSummaryPage> {
  late SignatureController _signatureController;
  late TextEditingController _complaintController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _complaintController = TextEditingController();
    _signatureController = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _fetchComplaint();
  }

  Future<void> _fetchComplaint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? '';
      final url = Uri.parse(ApiServices.getCustomerVehicleByJobId);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"jobId": widget.jobId}),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final jobcard = decoded['data']?['jobcard'];
        if (jobcard != null && jobcard['customerComplaint'] != null) {
          setState(() {
            _complaintController.text = jobcard['customerComplaint'].toString();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching complaint: $e");
    }
  }

  Future<File?> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide a signature"),
          backgroundColor: ColorConstants.errorcolor,
        ),
      );
      return null;
    }
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  void _clearAllCache(BuildContext context) {
    LocalUploadStorageService.clearJobCache(widget.jobId);
    context.read<CustomerDetailsController>().mobileNumController.clear();
    context.read<CustomerDetailsController>().vehiclePlateController.clear();
    context.read<CustomerDetailsController>().selectedVehicle = null;
    context.read<CustomerDetailsController>().filteredVehicles.clear();
    context.read<CustomerDetailsController>().customerStatusLabel = "";
    context.read<CustomerDetailsController>().isAlreadyPresent = false;
    context.read<VehicleDetailsController>().clearAll(context);
    context.read<VehicleessentialController>().clearData();
    context.read<JobcarddetailsController>().reset();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _complaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = BasicinspController(jobId: widget.jobId);
        Future.microtask(() async {
          await controller.getBasicimageList();
        });
        return controller;
      },
      child: Consumer<BasicinspController>(
        builder: (context, basicCtrl, child) {
          return Scaffold(
            appBar: CustomAppBar(
              title: "Quick Summary & Signature",
              onBackPress: () {
                context.pop();
              },
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BasicInspectionPreview(jobId: widget.jobId),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customer Complaint",
                            style: ApptextstyleConstants.mediumText(
                              fontSize: 14,
                              color: ColorConstants.blackColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _complaintController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Customer Complaint",
                              hintStyle: ApptextstyleConstants.thinText(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade400),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: ColorConstants.activecolor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Customer Signature",
                            style: ApptextstyleConstants.mediumText(
                              fontSize: 14,
                              color: ColorConstants.blackColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Signature(
                              controller: _signatureController,
                              height: 160,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                _signatureController.clear();
                              },
                              icon: const Icon(Icons.clear, color: Colors.red, size: 16),
                              label: const Text(
                                "Clear Signature",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: CustomButtonWidget(
                              text: _isLoading ? "Please wait..." : "Complete Quick Inspection",
                              textSize: 16,
                              isDisabled: _isLoading || basicCtrl.isUploading,
                              showLoader: _isLoading,
                              onPressed: () async {
                                final file = await _saveSignature();
                                if (file == null) return;
                                setState(() {
                                    _isLoading = true;
                                });
                                bool success = false;
                                try {
                                  basicCtrl.currentStage = InspectionStage.signature;
                                  basicCtrl.setSignatureFile(file);
                                  success = await basicCtrl.proceedStep(
                                    jobId: widget.jobId,
                                    status: 3,
                                    additionalComment: _complaintController.text.trim(),
                                  );
                                  if (success) {
                                    _clearAllCache(context);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Quick inspection completed successfully"),
                                          backgroundColor: ColorConstants.greenColor,
                                        ),
                                      );
                                      await Future.delayed(const Duration(seconds: 1));
                                      context.go('/jobcarddetails', extra: widget.jobId);
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Failed to upload signature. Check offline sync."),
                                          backgroundColor: ColorConstants.errorcolor,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint("Error completing inspection: $e");
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
