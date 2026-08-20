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
import 'package:hugeicons/hugeicons.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/signatureSpeech_controller .dart';

class QuickInspectionSummaryPage extends StatefulWidget {
  final int jobId;
  const QuickInspectionSummaryPage({super.key, required this.jobId});

  @override
  State<QuickInspectionSummaryPage> createState() =>
      _QuickInspectionSummaryPageState();
}

class _QuickInspectionSummaryPageState
    extends State<QuickInspectionSummaryPage> {
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
    // Clear the persisted Quick Inspection stage — the inspection is now fully submitted.
    BasicinspController.clearQuickStage(widget.jobId);
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
          return PopScope(
            canPop: false,
            onPopInvoked: (_) async {
              if (await _showExitConfirmation()) {
                context.go('/home');
              }
            },
            child: Scaffold(
              appBar: CustomAppBar(
                title: "Quick Summary & Signature",
                onBackPress: () async {
                  if (await _showExitConfirmation()) {
                    context.go('/home');
                  }
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
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: ColorConstants.whiteColor,
                                boxShadow: ColorConstants.dashboardboxShadow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
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
                                    Consumer<SignatureSpeechController>(
                                      builder: (context, speechCtrl, _) {
                                        final isThisListening =
                                            speechCtrl.isListening &&
                                            speechCtrl.activeController ==
                                                _complaintController;
                                        return Stack(
                                          alignment: Alignment.centerRight,
                                          children: [
                                            TextField(
                                              controller: _complaintController,
                                              maxLines: 3,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              decoration: InputDecoration(
                                                hintText: "Customer Complaint",
                                                hintStyle:
                                                    ApptextstyleConstants.thinText(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                      left: 12,
                                                      right: 60,
                                                      top: 12,
                                                      bottom: 12,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: ColorConstants
                                                            .activecolor,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: isThisListening
                                                  ? _buildWaveMic(speechCtrl)
                                                  : IconButton(
                                                      icon: Icon(
                                                        Icons.mic_none,
                                                        color: ColorConstants
                                                            .greenColor,
                                                      ),
                                                      onPressed: () => speechCtrl
                                                          .startListening(
                                                            controller:
                                                                _complaintController,
                                                          ),
                                                    ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Text(
                                    "Service Advisor Signature ",
                                    style: ApptextstyleConstants.mediumText(
                                      color: ColorConstants.blackColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "*",
                                    style: ApptextstyleConstants.boldText(
                                      color: ColorConstants.errorcolor,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.30,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        boxShadow:
                                            ColorConstants.dashboardboxShadow,
                                        border: Border.all(
                                          color: ColorConstants.syanColor,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Signature(
                                        controller: _signatureController,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: IconButton(
                                        onPressed: _signatureController.clear,
                                        icon: ShaderMask(
                                          shaderCallback: (bounds) =>
                                              const LinearGradient(
                                                colors: [
                                                  Color(0xFF0066A6),
                                                  Color(0xFF00BFA6),
                                                ],
                                              ).createShader(bounds),
                                          blendMode: BlendMode.srcIn,
                                          child: const HugeIcon(
                                            icon: HugeIcons.strokeRoundedEraser,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: CustomButtonWidget(
                                text: _isLoading
                                    ? "Please wait..."
                                    : "Complete Quick Inspection",
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
                                    basicCtrl.currentStage =
                                        InspectionStage.signature;
                                    basicCtrl.setSignatureFile(file);
                                    success = await basicCtrl.proceedStep(
                                      jobId: widget.jobId,
                                      status: 3,
                                      additionalComment: _complaintController
                                          .text
                                          .trim(),
                                    );
                                    if (success) {
                                      // Persist 'completed' so reopening still shows Summary.
                                      await basicCtrl
                                          .markQuickInspectionCompleted();
                                      _clearAllCache(context);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Quick inspection completed successfully",
                                            ),
                                            backgroundColor:
                                                ColorConstants.greenColor,
                                          ),
                                        );
                                        await Future.delayed(
                                          const Duration(seconds: 1),
                                        );
                                        context.go(
                                          '/jobcarddetails',
                                          extra: widget.jobId,
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Failed to upload signature. Check offline sync.",
                                            ),
                                            backgroundColor:
                                                ColorConstants.errorcolor,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaveMic(SignatureSpeechController controller) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            width: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 6, end: 20),
                  duration: Duration(milliseconds: 400 + (index * 150)),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 4,
                      height: controller.isListening ? value : 6,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: controller.stopListening,
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Discard changes?"),
            content: const Text(
              "Unsaved changes will be cleared. Are you sure you want to go back?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("NO"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("YES"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
