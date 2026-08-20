import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/dummyDB/Dummydb.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';

class FullScreenImage extends StatefulWidget {
  final String imageUrl;
  final String label;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.label,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final isCurrentlyZoomed = _transformationController.value != Matrix4.identity();
    if (isCurrentlyZoomed != _isZoomed) {
      if (mounted) {
        setState(() {
          _isZoomed = isCurrentlyZoomed;
        });
      }
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _resetZoom();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      const double scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      final zoomedMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
      _transformationController.value = zoomedMatrix;
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final bool isCarDiagram = widget.label == "Inspection Diagram";
    final firstGroup = DummyDB.damageList.take(3).toList();
    final secondGroup = DummyDB.damageList.skip(3).toList();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: "Vehicle Image",
          onBackPress: () => context.pop(),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _toTitleCase(widget.label),
                    style: ApptextstyleConstants.mediumText(
                      fontSize: 16,
                      color: ColorConstants.blackColor,
                    ),
                  ),
                  if (_isZoomed)
                    TextButton.icon(
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.refresh, color: Colors.black, size: 16),
                      label: Text(
                        "Reset Zoom",
                        style: ApptextstyleConstants.lightText(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              /// 🖼 Full Screen Image Area with InteractiveViewer
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: GestureDetector(
                        onDoubleTapDown: _handleDoubleTapDown,
                        onDoubleTap: _handleDoubleTap,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          boundaryMargin: const EdgeInsets.all(20),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.center,
                            child: Image.network(
                              widget.imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isCarDiagram)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ColorConstants.activecolor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Legend",
                                style: ApptextstyleConstants.mediumText(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: List.generate(firstGroup.length, (
                                  index,
                                ) {
                                  final item = firstGroup[index];
                                  return Text(
                                    "${item["emoji"]} ${item["label"]}",
                                    style: ApptextstyleConstants.lightText(
                                      color: item["color"],
                                      fontSize: 12,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: List.generate(secondGroup.length, (
                                  index,
                                ) {
                                  final item = secondGroup[index];
                                  return Text(
                                    "${item["emoji"]} ${item["label"]}",
                                    style: ApptextstyleConstants.lightText(
                                      color: item["color"],
                                      fontSize: 12,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: CustomButtonWidget(
                  text: "Close",
                  textSize: 16,
                  textColor: ColorConstants.whiteColor,
                  onPressed: () => context.pop(),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
