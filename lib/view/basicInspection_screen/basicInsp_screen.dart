// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/basicInsp_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/permission_service.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class BasicinspScreen extends StatefulWidget {
  final int jobId;
  const BasicinspScreen({super.key, required this.jobId});

  @override
  State<BasicinspScreen> createState() => _BasicinspScreenState();
}

class _BasicinspScreenState extends State<BasicinspScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isRecording = false;
  bool _isStopping = false;

  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 10.0;
  double _baseZoom = 1.0;
  final List<double> baseLevels = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0];
  int _zoomIndex = 0;
  FlashMode _flashMode = FlashMode.auto;

  Timer? _recordTimer;
  int _remainingSeconds = 30;

  final FocusNode _notesFocusNode = FocusNode();
  bool _showNotesDrawer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (mounted) {
      setState(() => _isCameraReady = false);
    }
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (_) {}
      _cameraController = null;
    }

    final hasPermission = await PermissionService.instance.requestCameraPermission(context);
    if (!hasPermission) return;
    final bool hasMic = await Permission.microphone.isGranted;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: hasMic,
      );
      await controller.initialize();
      double minZoom = await controller.getMinZoomLevel();
      double maxZoom = await controller.getMaxZoomLevel();
      if (Platform.isIOS) {
        maxZoom = maxZoom.clamp(1.0, 10.0);
      }
      _minZoom = minZoom < 1.0 ? 1.0 : minZoom;
      _maxZoom = maxZoom;
      _currentZoom = 1.0;
      _zoomIndex = baseLevels.contains(1.0) ? baseLevels.indexOf(1.0) : 0;
      try {
        await controller.setZoomLevel(_currentZoom);
      } catch (_) {}
      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {
        _flashMode = FlashMode.off;
      }
      if (!mounted) {
        controller.dispose();
        return;
      }
      _cameraController = controller;
      setState(() => _isCameraReady = true);
    } catch (e) {
      if (mounted) {
        setState(() => _isCameraReady = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (mounted && _isCameraReady) {
        setState(() => _isCameraReady = false);
      }
      if (cameraController != null) {
        cameraController.dispose();
        _cameraController = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      Permission.camera.status.then((status) {
        if (status.isGranted && mounted) {
          _initCamera();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notesFocusNode.dispose();
    _recordTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    setState(() {
      _flashMode = _flashMode == FlashMode.off
          ? FlashMode.auto
          : _flashMode == FlashMode.auto
          ? FlashMode.always
          : FlashMode.off;
    });
    try {
      await _cameraController!.setFlashMode(_flashMode);
    } catch (_) {}
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  void _applyZoom(double zoom) {
    zoom = zoom.clamp(_minZoom, _maxZoom);
    setState(() {
      _currentZoom = zoom;
    });
    _cameraController?.setZoomLevel(zoom);
  }

  void _zoomIn() {
    if (_zoomIndex >= baseLevels.length - 1) return;
    _zoomIndex++;
    _applyZoom(baseLevels[_zoomIndex]);
  }

  void _zoomOut() {
    if (_zoomIndex <= 0) return;
    _zoomIndex--;
    _applyZoom(baseLevels[_zoomIndex]);
  }

  Future<void> _takePhoto(BasicinspController controller) async {
    final cam = _cameraController;
    if (cam == null || !cam.value.isInitialized || _isCapturing || controller.isBusy) return;
    if (controller.isMaxImagesCaptured) {
      if (controller.hasVideoRequirement) {
        controller.selectVideoMode();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maximum images reached for this item"),
          duration: Duration(seconds: 1),
          backgroundColor: ColorConstants.errorcolor,
        ),
      );
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final XFile file = await cam.takePicture();
      File photoFile = File(file.path);
      int angle = 0;
      try {
        NativeDeviceOrientation orientation =
            await NativeDeviceOrientationCommunicator()
                .orientation(useSensor: true)
                .timeout(const Duration(milliseconds: 500));
        if (orientation == NativeDeviceOrientation.landscapeLeft) {
          angle = 270;
        } else if (orientation == NativeDeviceOrientation.landscapeRight) {
          angle = 90;
        } else if (orientation == NativeDeviceOrientation.portraitDown) {
          angle = 180;
        }
      } catch (e) {
        debugPrint("Orientation check skipped: $e");
      }
      final activeIndex = controller.selectedBoxIndex;
      await controller.updateCapturedImage(
        activeIndex,
        photoFile,
        angle: angle,
      );
      // Photo captured into box; camera stays open without auto-preview popup.
    } catch (e) {
      debugPrint("Error in _takePhoto: $e");
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _startRecording(BasicinspController controller) async {
    final cam = _cameraController;
    if (cam == null || !cam.value.isInitialized || cam.value.isRecordingVideo || _isRecording || controller.isBusy) {
      return;
    }
    final hasMic = await PermissionService.instance.requestMicrophonePermission(context);
    if (!hasMic) return;
    try {
      await cam.startVideoRecording();
      final maxDuration = controller.is360Stage
          ? controller.current360Duration
          : (controller.currentItem?['videoDuration'] ?? 30);
      setState(() {
        _isRecording = true;
        _remainingSeconds = maxDuration;
      });
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds <= 1) {
          _stopRecording(controller);
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
    } catch (e) {
    }
  }

  Future<void> _stopRecording(BasicinspController controller) async {
    final cam = _cameraController;
    if (cam == null || !cam.value.isRecordingVideo || _isStopping) return;
    try {
      setState(() => _isStopping = true);
      _recordTimer?.cancel();
      final XFile file = await cam.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isStopping = false;
      });
      await controller.updateCapturedVideo(File(file.path));
      // Video captured into box; camera stays open without auto-preview popup.
    } catch (e) {
      if (mounted) setState(() => _isStopping = false);
    }
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
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (_) async {
            final controller = Provider.of<BasicinspController>(context, listen: false);
            if (controller.isBusy || _isRecording || _isStopping) return;
            if (await _showExitConfirmation()) {
              context.go('/home');
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
            child: Consumer<BasicinspController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(4, (_) => _inspectionShimmer()),
                    ),
                  );
                }
                controller.checkAndShowResumeStage(context);
                if (!controller.isBackendFullyConfigured) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: ColorConstants.orangecolor,
                            size: 100,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Inspection Image Settings Incomplete",
                            textAlign: TextAlign.center,
                            style: ApptextstyleConstants.lightText(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Please define External image lists in backend.",
                            textAlign: TextAlign.center,
                            style: ApptextstyleConstants.thinText(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomButtonWidget(
                            text: 'Go To Home',
                            textSize: 14,
                            onPressed: () {
                              context.go('/home');
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final isImageStage =
                    controller.currentStage == InspectionStage.externalImages ||
                    controller.currentStage == InspectionStage.internalImages;
                if (isImageStage && controller.currentImages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final capturedFile = controller.imageAt(
                  controller.selectedBoxIndex,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Embedded Camera Preview or Captured Image Preview Background
                    if (!controller.isVideoModeSelected && capturedFile != null)
                      _buildCapturedImagePreview(capturedFile)
                    else
                      _buildCameraPreview(),

                    // 2. Top Navigation & Dynamic Header Overlay
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: _buildTopHeaderRow(controller),
                    ),

                    // 3. Recording Indicator Badge
                    if (_isRecording)
                      Positioned(
                        top: 70,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: ColorConstants.errorcolor,
                                size: 10,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "REC ${_remainingSeconds}s",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 4. Expandable Notes Bar / Drawer Overlay
                    Positioned(
                      bottom: 235,
                      left: 12,
                      right: 12,
                      child: _buildNotesOverlay(controller),
                    ),

                    // 5. Bottom Camera Control Panel (3 Rows)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBottomControlPanel(controller),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildCapturedImagePreview(File capturedFile) {
    return Container(
      // color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Image.file(
          capturedFile,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const CameraShimmerLoader();
    }
    final size = MediaQuery.of(context).size;
    var previewAspect = _cameraController!.value.aspectRatio;
    if (size.height > size.width) {
      previewAspect = 1 / previewAspect;
    }
    double scale = size.aspectRatio / previewAspect;
    if (scale < 1) scale = 1 / scale;

    return NativeDeviceOrientationReader(
      useSensor: true,
      builder: (context) {
        return GestureDetector(
          onScaleStart: (details) => _baseZoom = _currentZoom,
          onScaleUpdate: (details) {
            double zoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
            _applyZoom(zoom);
          },
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: (_cameraController != null && _cameraController!.value.isInitialized)
                  ? CameraPreview(_cameraController!)
                  : const CameraShimmerLoader(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeaderRow(BasicinspController controller) {
    Map<String, dynamic>? item = controller.currentItem;

    final String typeTitle =
        controller.currentStage == InspectionStage.additionalImages
        ? "Additional Image"
        : (controller.isQuick
              ? "Quick Image"
              : (controller.isExternalSelected
                    ? "External Image"
                    : "Internal Image"));

    final String label = controller.currentStage == InspectionStage.external360
        ? (controller.isQuick ? "360 Video" : "External 360 Video")
        : controller.currentStage == InspectionStage.internal360
        ? "Internal 360 Video"
        : controller.currentStage == InspectionStage.additionalImages
        ? "Additional Image ${controller.currentStep + 1}"
        : (item?['imageLabel'] ?? "");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: (controller.isBusy || _isRecording || _isStopping)
                ? null
                : () async {
                    if (await _showExitConfirmation()) {
                      context.go('/home');
                    }
                  },
          ),

          const SizedBox(width: 8),

          // Inspection Type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorConstants.syanColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorConstants.syanColor, width: 1),
            ),
            child: Text(
              typeTitle.toUpperCase(),
              style: ApptextstyleConstants.mediumText(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Label gets available space
          if (label.isNotEmpty)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: ApptextstyleConstants.italicText(
                    fontSize: 12,
                    color: ColorConstants.greenColor,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 8),

          // FLASH ALWAYS AT RIGHT
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(_flashIcon, color: Colors.white, size: 22),
            onPressed: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesOverlay(BasicinspController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showNotesDrawer)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _notesFocusNode,
                    controller: controller.notesController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) => controller.notes = value,
                    decoration: InputDecoration(
                      hintText: "Notes & comments...",
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                if (controller.showListeningUI)
                  _buildWaveMic(controller)
                else
                  IconButton(
                    icon: Icon(
                      Icons.mic_none,
                      color: ColorConstants.greenColor,
                    ),
                    onPressed: () => controller.startListening(context),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            setState(() {
              _showNotesDrawer = !_showNotesDrawer;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showNotesDrawer
                      ? Icons.keyboard_arrow_down
                      : Icons.edit_note,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _showNotesDrawer ? "Close Notes" : "Add Notes",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControlPanel(BasicinspController controller) {
    Map<String, dynamic>? item = controller.currentItem;
    int imageCount = 0;
    if (controller.currentStage == InspectionStage.additionalImages) {
      imageCount = 1;
    } else if (controller.is360Stage) {
      imageCount = 0;
    } else {
      imageCount = item?['imageCount'] ?? 0;
    }

    final bool hasVideoRequirement =
        controller.is360Stage || (item?['videoFlag'] ?? false);
    final int videoDuration = controller.is360Stage
        ? controller.current360Duration
        : (item?['videoDuration'] ?? 30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── ROW 1: [ Image Boxes ] [ Video Box ] ──────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Dynamic Image Boxes from API / Configuration
                for (int i = 0; i < imageCount; i++) ...[
                  _buildImageBox(context, controller, i),
                  const SizedBox(width: 8),
                ],

                // Video Box (Show ONLY if video requirement is configured)
                if (hasVideoRequirement) ...[
                  _buildVideoBox(context, controller, videoDuration),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── ROW 2: [ Zoom Controller ] ────────────────────────────────────
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: _zoomOut,
              ),
              Expanded(
                child: SfSlider(
                  min: _minZoom,
                  max: _maxZoom,
                  value: _currentZoom,
                  interval: 1,
                  showTicks: false,
                  showLabels: false,
                  activeColor: ColorConstants.syanColor,
                  inactiveColor: Colors.white30,
                  onChanged: (dynamic value) {
                    double zoom = value.clamp(_minZoom, _maxZoom);
                    _applyZoom(zoom);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: _zoomIn,
              ),
              const SizedBox(width: 6),
              Text(
                "${_currentZoom.toStringAsFixed(1)}x",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── ROW 3: [ Skip ] [ Camera Button ] [ Next ] ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Skip Button
              SizedBox(
                width: 90,
                child: controller.shouldShowSkip
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomButtonTwo(
                          text: "SKIP",
                          isDisabled: controller.isBusy || _isRecording || _isStopping,
                          onPressed:
                              (controller.isBusy ||
                                  _isRecording ||
                                  _isStopping)
                              ? null
                              : () {
                                  _notesFocusNode.unfocus();
                                  controller.skipStep(context);
                                },
                        ),
                      )
                    : const SizedBox(),
              ),

              // Shutter / Camera / Record Button
              GestureDetector(
                onTap: (_isStopping || _isCapturing || controller.isBusy)
                    ? null
                    : (controller.isVideoModeSelected || controller.is360Stage)
                    ? (_isRecording
                          ? () => _stopRecording(controller)
                          : () => _startRecording(controller))
                    : () => _takePhoto(controller),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ColorConstants.buttonGradient,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: (_isStopping || controller.isVideoLoading || controller.isUploading)
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Icon(
                            _isRecording
                                ? Icons.stop
                                : (controller.isVideoModeSelected ||
                                      controller.is360Stage)
                                ? Icons.videocam
                                : Icons.camera_alt,
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),
              ),

              // Next / Proceed Button
              SizedBox(
                width: 90,
                child: CustomButtonWidget(
                  text: "NEXT",
                  textSize: 14,
                  showLoader: controller.isVideoLoading || controller.isUploading,
                  isDisabled: controller.isBusy || _isRecording || _isStopping,
                  onPressed:
                      (controller.isBusy ||
                          _isRecording ||
                          _isStopping)
                      ? null
                      : () async {
                          _notesFocusNode.unfocus();
                          final isValid = controller.validateMandatoryImage();
                          if (!isValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: ColorConstants.errorcolor,
                                content: Text(
                                  controller.is360Stage
                                      ? "360 Video is mandatory"
                                      : "Please capture required image",
                                  style: ApptextstyleConstants.thinText(
                                    color: ColorConstants.whiteColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          final success = await controller.proceedStep(
                            jobId: widget.jobId,
                            status: 2,
                          );
                          if (!context.mounted) return;
                          if (success) {
                            controller.nextStep(context);
                            controller.notesController.clear();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: ColorConstants.errorcolor,
                                content: Text(
                                  controller.lastErrorMessage.isNotEmpty
                                      ? controller.lastErrorMessage
                                      : "Failed to process inspection item.",
                                  style: ApptextstyleConstants.thinText(
                                    color: ColorConstants.whiteColor,
                                    fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildImageBox(
    BuildContext context,
    BasicinspController controller,
    int index,
  ) {
    final file = controller.imageAt(index);
    final isSelected =
        !controller.isVideoModeSelected && controller.selectedBoxIndex == index;
    final isBusy = controller.isBusy || _isRecording || _isStopping;

    return GestureDetector(
      onTap: isBusy
          ? null
          : () {
              _notesFocusNode.unfocus();
              if (file != null) {
                // Open Preview directly if captured
                controller.handleImageTap(
                  context,
                  imageIndex: index,
                  mediaType: MediaType.image,
                );
              } else {
                // Focus this box for upcoming photo capture
                controller.selectBoxIndex(index);
              }
            },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.whiteColor
              ),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Image ${index + 1}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
          if (file != null) ...[
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: isBusy
                    ? null
                    : () {
                        _notesFocusNode.unfocus();
                        controller.removeCapturedImage(index);
                      },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 3),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoBox(
    BuildContext context,
    BasicinspController controller,
    int duration,
  ) {
    final videoFile = controller.capturedVideo;
    final isSelected = controller.isVideoModeSelected || controller.is360Stage;
    final isVideoLoading = controller.isVideoLoading;
    final isBusy = controller.isBusy || _isRecording || _isStopping;

    return GestureDetector(
      onTap: isBusy
          ? null
          : () {
              _notesFocusNode.unfocus();
              if (videoFile != null && !isVideoLoading) {
                // Open Video Preview directly if captured
                controller.handleImageTap(
                  context,
                  imageIndex: 0,
                  mediaType: MediaType.video,
                  maxDuration: duration,
                );
              } else if (!isVideoLoading) {
                // Select Video Mode
                controller.selectVideoMode();
              }
            },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:  ColorConstants.whiteColor
              ),
            ),
            child: isVideoLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Processing...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  )
                : videoFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPreviewWidget(file: videoFile),
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Video",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
          if (videoFile != null && !isVideoLoading) ...[

            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: isBusy
                    ? null
                    : () {
                        _notesFocusNode.unfocus();
                        controller.removeCapturedVideo();
                      },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 3),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaveMic(BasicinspController controller) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 6, end: 18),
                  duration: Duration(milliseconds: 400 + (index * 150)),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 3,
                      height: controller.isListening ? value : 6,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                  onEnd: () {
                    if (controller.isListening && mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: controller.stopListening,
            child: const Icon(Icons.close, color: Colors.red, size: 18),
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

  Widget _inspectionShimmer() {
    return Shimmer(
      color: Colors.white,
      colorOpacity: 0.3,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        height: 180,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}

class CameraShimmerLoader extends StatelessWidget {
  const CameraShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          interval: const Duration(milliseconds: 500),
          color: ColorConstants.lightblackColor,
          colorOpacity: 0.6,
          enabled: true,
          direction: const ShimmerDirection.fromLTRB(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: ColorConstants.borderGreyColor,
            ),
          ),
        ),
      ),
    );
  }
}
