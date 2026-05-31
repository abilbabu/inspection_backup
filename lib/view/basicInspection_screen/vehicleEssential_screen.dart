// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/vehicleEssential_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:provider/provider.dart';

class VehicleEssentialScreen extends StatefulWidget {
  final int? jobId;
  final int vId;
  const VehicleEssentialScreen({
    super.key,
    required this.jobId,
    required this.vId,
  });

  @override
  State<VehicleEssentialScreen> createState() => _VehicleEssentialScreenState();
}

class _VehicleEssentialScreenState extends State<VehicleEssentialScreen> {
  bool isLoading = false;
  bool isSuccess = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final controller = context.read<VehicleessentialController>();
      controller.getvehicleEssentialList();
      controller.initSpeech();
    });
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Discard changes?"),
              content: const Text(
                "Unsaved changes will be cleared. Are you sure you want to go back?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("NO"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("YES"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        final shouldExit = await _showExitConfirmation();
        if (shouldExit) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Vehicle Essential",
          onBackPress: () async {
            final shouldExit = await _showExitConfirmation();
            if (shouldExit) {
              context.go('/home');
            }
          },
        ),
        body: Consumer<VehicleessentialController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    VehicleSummaryWidgetTwo(jobId: widget.jobId),
                    SizedBox(height: 15),
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Registration Card ",
                                  style: ApptextstyleConstants.lightText(
                                    color: ColorConstants.blackColor,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "*",
                                  style: TextStyle(
                                    color: ColorConstants.errorcolor,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _radioOptionSection(controller),
                            SizedBox(height: 12),
                            _checkEssentialsSection(controller),
                            SizedBox(height: 12),
                            _contentsNotesSection(controller, context),
                            SizedBox(height: 12),
                            Container(child: imageBox(0)),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButtonWidget(
                                text: isLoading
                                    ? "Please wait..."
                                    : isSuccess
                                    ? "COMPLETED"
                                    : "START BASIC INSPECTION",
                                textSize: 16,
                                isDisabled: isLoading || isSuccess,
                                showLoader: isLoading,
                                textColor: ColorConstants.whiteColor,
                                onPressed: () async {
                                  if (isLoading) return;
                                  final controller = context
                                      .read<VehicleessentialController>();
                                  if (controller.selectedDocumentTypeId ==
                                      null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor:
                                            ColorConstants.errorcolor,
                                        content: Text(
                                          "Select Document Type",
                                          style: TextStyle(
                                            color: ColorConstants.whiteColor,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => isLoading = true);
                                  await Future.delayed(Duration.zero);
                                  final success = await controller
                                      .submitVehicleEssential(
                                        jobId: widget.jobId!,
                                        vId: widget.vId,
                                      );
                                  if (!mounted) return;
                                  if (success) {
                                    controller.clearData();
                                    setState(() => isSuccess = true);
                                    context.go(
                                      '/basicinspection',
                                      extra: widget.jobId,
                                    );
                                  } else {
                                    setState(() => isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor:
                                            ColorConstants.errorcolor,
                                        content: Text(
                                          "Failed to save vehicle essentials",
                                          style: TextStyle(
                                            color: ColorConstants.whiteColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget imageBox(int index) {
    final controller = context.watch<VehicleessentialController>();
    final file = controller.imageAt(index);
    return GestureDetector(
      onTap: () {
        controller.handleImageTap(context, imageIndex: index);
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, fit: BoxFit.cover),
              )
            : const Center(child: Icon(Icons.camera_alt, size: 40)),
      ),
    );
  }

  Widget _contentsNotesSection(
    VehicleessentialController controller,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Contents & Additional Notes",
              style: ApptextstyleConstants.lightText(
                color: ColorConstants.blackColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: controller.notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) =>
                  context.read<VehicleessentialController>().notes = value,
              decoration: InputDecoration(
                hintText: "Contents & Additional Notes",
                hintStyle: ApptextstyleConstants.thinText(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.only(
                  left: 12,
                  right: 60,
                  top: 12,
                  bottom: 12,
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
            Positioned(
              right: 8,
              child: controller.showListeningUI
                  ? _buildWaveMic()
                  : IconButton(
                      icon: Icon(
                        Icons.mic_none,
                        color: ColorConstants.greenColor,
                      ),
                      onPressed: controller.startListening,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _checkEssentialsSection(VehicleessentialController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Check Vehicle Essentials",
          style: ApptextstyleConstants.lightText(
            color: ColorConstants.blackColor,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 4,
          ),
          itemCount: controller.checkBoxType.length,
          itemBuilder: (context, index) {
            final id = controller.checkBoxType.keys.elementAt(index);
            final label = controller.checkBoxType[id]!;
            return InkWell(
              onTap: () {
                controller.toggleCheckbox(id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: controller.selectedCheckBox[id] ?? false,
                      activeColor: ColorConstants.syanColor,
                      onChanged: (_) {
                        controller.toggleCheckbox(id);
                      },
                    ),
                    Expanded(
                      child: Text(
                        label,
                        style: ApptextstyleConstants.thinText(
                          color: ColorConstants.blackColor,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _radioOptionSection(VehicleessentialController controller) {
    return Row(
      children: controller.documentTypes.entries.map((entry) {
        return Row(
          children: [
            Transform.scale(
              scale: 0.8,
              child: Radio<int>(
                value: entry.key,
                groupValue: controller.selectedDocumentTypeId,
                activeColor: ColorConstants.syanColor,
                onChanged: (value) {
                  controller.setDocumentType(value!);
                },
              ),
            ),
            Text(
              entry.value,
              style: ApptextstyleConstants.thinText(
                color: ColorConstants.blackColor,
                fontSize: 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildWaveMic() {
    final controller = context.watch<VehicleessentialController>();
    return Container(
      height: 40,
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
                  onEnd: () {
                    if (controller.isListening) {
                      setState(() {});
                    }
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
}
