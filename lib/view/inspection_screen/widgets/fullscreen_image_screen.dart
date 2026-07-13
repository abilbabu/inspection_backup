import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inspection/controller/inspectionScreenImage_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:provider/provider.dart';

class FullScreenImageScreen extends StatelessWidget {
  final File imageFile;
  final int angle;

  const FullScreenImageScreen({
    super.key,
    required this.imageFile,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InspectionscreenimageController()..init(imageFile, angle),
      child: const _FullScreenImageView(),
    );
  }
}

class _FullScreenImageView extends StatefulWidget {
  const _FullScreenImageView();

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  bool isLandscapeImage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InspectionscreenimageController>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Image",
          onBackPress: () => Navigator.pop(context),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: controller.imageLoaded
                          ? AspectRatio(
                              aspectRatio: controller.aspectRatio,
                              child: Container(
                                key: controller.imageKey,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.file(
                                        controller.displayedImage,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    if (controller.isEditMode)
                                      Positioned.fill(
                                        child: GestureDetector(
                                          onPanStart: (details) =>
                                              controller.startStroke(details.localPosition),
                                          onPanUpdate: (details) =>
                                              controller.updateStroke(details.localPosition),
                                          onPanEnd: (_) => controller.endStroke(),
                                          child: CustomPaint(
                                            painter: LinePainter(controller.strokes),
                                            size: Size.infinite,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, "recapture"),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/repeat.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/svg/repeat.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    "Click the icon to capture again*",
                    style: ApptextstyleConstants.lightText(
                      fontSize: 12,
                      color: ColorConstants.errorcolor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: controller.strokes.isNotEmpty
                        ? controller.undo
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: controller.redoStack.isNotEmpty
                        ? controller.redo
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      controller.isEditMode ? Icons.delete : Icons.edit,
                    ),
                    color: controller.isEditMode
                        ? ColorConstants.holdorangeColor
                        : ColorConstants.syanColor,
                    onPressed: controller.toggleEditMode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_90_degrees_ccw),
                    onPressed: controller.rotateImage,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButtonWidget(
                text: controller.isLoading
                    ? "Please wait..."
                    : controller.isSuccess
                    ? "COMPLETED"
                    : "SAVE",
                textSize: 18,
                isDisabled: controller.isLoading || controller.isSuccess,
                showLoader: controller.isLoading,
                onPressed: () async {
                  final file = await controller.saveImageWithStrokes();
                  if (!context.mounted || file == null) return;
                  Navigator.pop(context, file);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  LinePainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
