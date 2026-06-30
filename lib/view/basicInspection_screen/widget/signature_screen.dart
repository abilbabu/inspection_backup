import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:inspection/controller/basicInsp_controller.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/controller/signatureSpeech_controller%20.dart' show SignatureSpeechController;
import 'package:inspection/controller/vehicleDetails_controller.dart';
import 'package:inspection/controller/vehicleEssential_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/view/basicInspection_screen/basicinspection_previw.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/utils/constant/color_constants.dart';

class SignatureScreen extends StatefulWidget {
  final int jobId;
  const SignatureScreen({super.key, required this.jobId});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late SignatureController _controller;
  late TextEditingController _additionalCommentController;

  @override
  void initState() {
    super.initState();
    _additionalCommentController = TextEditingController();
    _controller = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  Future<File?> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide a signature"),
          backgroundColor: ColorConstants.errorcolor,
        ),
      );
      return null;
    }
    final bytes = await _controller.toPngBytes();
    if (bytes == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  void dispose() {
    _additionalCommentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<BasicinspController>();
    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {
        if (await _showExitConfirmation()) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Basic Inspection",
          onBackPress: () async {
            if (await _showExitConfirmation()) {
              context.go('/home');
            }
          },
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BasicInspectionPreview(jobId: widget.jobId),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "Additional Comments",
                  style: ApptextstyleConstants.mediumText(
                    color: ColorConstants.blackColor,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorConstants.whiteColor,
                    border: Border.all(color: ColorConstants.greyColor),
                    boxShadow: ColorConstants.dashboardboxShadow,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Consumer<SignatureSpeechController>(
                    builder: (context, controller, child) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          TextField(
                            textCapitalization: TextCapitalization.sentences,
                            controller: _additionalCommentController,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            style: ApptextstyleConstants.lightText(
                              color: ColorConstants.blackColor,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  "Enter additional comments from customer",
                              hintStyle: ApptextstyleConstants.lightText(
                                color: ColorConstants.greyColor,
                                fontSize: 13,
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                50, // Space for mic button
                                12,
                              ),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: ColorConstants.whiteColor,
                            ),
                          ),

                          Positioned(
                            top: 6,
                            right: 6,
                            child: controller.isListening
                                ? _buildSmallWaveMic(controller)
                                : IconButton(
                                    icon: const Icon(
                                      Icons.mic_none,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      await controller.startListening(
                                        controller:
                                            _additionalCommentController,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.30,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: ColorConstants.dashboardboxShadow,
                          border: Border.all(
                            color: ColorConstants.syanColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Signature(
                          controller: _controller,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: IconButton(
                          onPressed: _controller.clear,
                          icon: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Consumer<BasicinspController>(
                    builder: (context, controller, _) {
                      return CustomButtonWidget(
                        text: controller.isUploading
                            ? "Please wait..."
                            : controller.isCompleted
                            ? "COMPLETED"
                            : "PROCEED",
                        textSize: 16,
                        textColor: Colors.white,
                        isDisabled:
                            controller.isUploading || controller.isCompleted,
                        showLoader: controller.isUploading,
                        onPressed:
                            controller.isUploading || controller.isCompleted
                            ? null
                            : () async {
                                final additionalComment =
                                    _additionalCommentController.text.trim();
                                final file = await _saveSignature();
                                if (file == null) return;
                                bool success = false;
                                await controller.runWithLoader(() async {
                                  controller.currentStage =
                                      InspectionStage.signature;
                                  controller.setSignatureFile(file);
                                  success = await controller.proceedStep(
                                    jobId: controller.jobId,
                                    status: 3,
                                    additionalComment: additionalComment,
                                  );
                                  if (success) {
                                    controller.isCompleted = true;
                                  }
                                });
                                if (!success) return;
                                _clearAllData(context);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Basic inspection completed successfully",
                                    ),
                                    backgroundColor: ColorConstants.greenColor,
                                  ),
                                );
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );
                                context.go(
                                  '/jobcarddetails',
                                  extra: controller.jobId,
                                );
                              },
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallWaveMic(SignatureSpeechController controller) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 4, end: 12),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  builder: (_, value, __) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 3,
                      height: controller.isListening ? value : 4,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: controller.stopListening,
            child: const Icon(Icons.close, size: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _clearAllData(BuildContext context) {
    final customerCtrl = context.read<CustomerDetailsController>();
    final jobCtrl = context.read<JobcarddetailsController>();
    final vehicleCtrl = context.read<VehicleDetailsController>();
    final essentialCtrl = context.read<VehicleessentialController>();
    customerCtrl.mobileNumController.clear();
    customerCtrl.vehiclePlateController.clear();
    customerCtrl.selectedVehicle = null;
    customerCtrl.filteredVehicles.clear();
    customerCtrl.customerStatusLabel = "";
    essentialCtrl.clearData();
    vehicleCtrl.clearAll(context);
    jobCtrl.reset();
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
