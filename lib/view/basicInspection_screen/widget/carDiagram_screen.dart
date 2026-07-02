// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/basicInsp_controller.dart';
import 'package:inspection/controller/cardiagram_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:provider/provider.dart';

class CardiagramScreen extends StatefulWidget {
  final int? jobId;
  const CardiagramScreen({super.key, this.jobId});

  @override
  State<CardiagramScreen> createState() => _CardiagramScreenState();
}

class _CardiagramScreenState extends State<CardiagramScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardiagramController>().clearAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CardiagramController>();
    context.watch<BasicinspController>();
    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {
        final controller = context.read<CardiagramController>();
        if (controller.isProgrammaticPop) {
          controller.isProgrammaticPop = false;
          return;
        }
        Future.microtask(() async {
          if (await _showExitConfirmation()) {
            if (context.mounted) {
              context.go('/home');
            }
          }
        });
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
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    "Car Diagram ",
                    style: ApptextstyleConstants.mediumText(
                      color: ColorConstants.blackColor,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onPanStart: controller.isDrawingEnabled
                        ? controller.onPanStart
                        : null,
                    onPanUpdate: controller.isDrawingEnabled
                        ? controller.onPanUpdate
                        : null,
                    child: RepaintBoundary(
                      key: controller.imageKey,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ColorConstants.whiteColor,
                                width: 1.5,
                              ),
                            ),
                            child: Image.asset(
                              "assets/image/car diagram.jpg",
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DamagePainter(
                                controller.strokes,
                                controller.strokeColors,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo),
                    color: ColorConstants.toastgrey,
                    onPressed: controller.strokes.isNotEmpty
                        ? controller.undo
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    color: ColorConstants.toastgrey,
                    onPressed: controller.strokes.isNotEmpty
                        ? controller.redo
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      controller.isDrawingEnabled
                          ? Icons.draw
                          : Icons.draw_outlined,
                    ),
                    color: controller.isDrawingEnabled
                        ? controller.selectedColor
                        : ColorConstants.toastgrey,
                    onPressed: () {
                      controller.toggleDrawing();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: ColorConstants.holdorangeColor,
                    onPressed: controller.strokes.isNotEmpty
                        ? controller.clearAll
                        : null,
                  ),
                ],
              ),
              if (controller.isDrawingEnabled)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.damageTypes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3.5,
                  ),
                  itemBuilder: (context, index) {
                    final damage = controller.damageTypes[index];
                    final isSelected =
                        controller.selectedDamage.label == damage.label;
                    return GestureDetector(
                      onTap: () {
                        controller.selectDamage(damage);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: damage.color,
                            width: isSelected ? 2 : 1,
                          ),
                          color: isSelected
                              ? damage.color.withOpacity(0.15)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: damage.color,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                damage.label,
                                overflow: TextOverflow.ellipsis,
                                style: ApptextstyleConstants.lightText(
                                  fontSize: 12,
                                  color: ColorConstants.blackColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CustomButtonWidget(
                  text: controller.isSaving ? "Saving..." : "NEXT",
                  textSize: 16,
                  textColor: ColorConstants.whiteColor,
                  isDisabled: controller.isSaving,
                  showLoader: controller.isSaving,
                  onPressed: controller.isSaving
                      ? null
                      : () async {
                          final basicController = context
                              .read<BasicinspController>();
                          controller.onNextPressed(context, (file) async {
                            debugPrint("Uploading cardiagram image path: ${file.path}");
                            basicController.setDiagramFile(file);
                            final result = await basicController.proceedStep(
                              jobId: basicController.jobId,
                              status: 2,
                            );
                            debugPrint("Cardiagram upload result: $result");
                            return result;
                          });
                        },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
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

class DamageType {
  final String label;
  final Color color;
  const DamageType(this.label, this.color);
}

class DamagePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Color> colors;
  DamagePainter(this.strokes, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < strokes.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final stroke = strokes[i];
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int j = 1; j < stroke.length; j++) {
        path.lineTo(stroke[j].dx, stroke[j].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) => true;
}
