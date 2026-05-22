import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class CameraCaptureScreen extends StatefulWidget {
  final bool isVideo;
  final int? videoDuration;

  const CameraCaptureScreen({
    super.key,
    required this.isVideo,
    this.videoDuration,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

Timer? _debounce;

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  late CameraController _controller;
  bool _ready = false;
  bool _isCapturing = false;
  bool _isRecording = false;
  bool _isStopping = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 10.0;
  double _baseZoom = 1.0;
  final List<double> baseLevels = [1, 2, 3, 5, 7, 10];
  int _zoomIndex = 0;
  FlashMode _flashMode = FlashMode.auto;
  Timer? _recordTimer;
  late int _maxVideoSeconds;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _maxVideoSeconds = widget.videoDuration ?? 30;
    _remainingSeconds = _maxVideoSeconds;
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _controller = CameraController(
      rearCamera,
      ResolutionPreset.high,
      enableAudio: widget.isVideo,
    );
    await _controller.initialize();
    double minZoom = await _controller.getMinZoomLevel();
    double maxZoom = await _controller.getMaxZoomLevel();
    if (Platform.isIOS) {
      maxZoom = maxZoom.clamp(1.0, 10.0);
    }
    _minZoom = minZoom < 1 ? 1 : minZoom;
    _maxZoom = maxZoom;
    _currentZoom = 1.0;
    _zoomIndex = baseLevels.indexOf(1.0);
    await _controller.setZoomLevel(_currentZoom);
    await _controller.setFlashMode(_flashMode);
    if (!mounted) return;
    setState(() => _ready = true);
  }

  Future<void> _toggleFlash() async {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _flashMode = _flashMode == FlashMode.off
          ? FlashMode.auto
          : _flashMode == FlashMode.auto
          ? FlashMode.always
          : FlashMode.off;
    });
    await _controller.setFlashMode(_flashMode);
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

  Future<void> _takePhoto() async {
    if (_isCapturing || !_controller.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final XFile file = await _controller.takePicture();
      NativeDeviceOrientation orientation =
          await NativeDeviceOrientationCommunicator().orientation(
            useSensor: true,
          );
      int angle = 0;
      if (orientation == NativeDeviceOrientation.landscapeLeft) {
        angle = 270; // Changed from 90
      } else if (orientation == NativeDeviceOrientation.landscapeRight) {
        angle = 90; // Changed from -90
      } else if (orientation == NativeDeviceOrientation.portraitDown) {
        angle = 180;
      }
      if (!mounted) return;
      Navigator.pop(context, {"file": File(file.path), "angle": angle});
    } catch (e) {
      debugPrint("Photo error: $e");
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _startRecording() async {
    if (!_controller.value.isInitialized || _controller.value.isRecordingVideo)
      return;
    try {
      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
        _remainingSeconds = _maxVideoSeconds;
      });
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds <= 1) {
          _stopRecording();
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
    } catch (e) {
      debugPrint("Start recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!_controller.value.isRecordingVideo || _isStopping) return;
    try {
      setState(() {
        _isStopping = true;
      });
      _recordTimer?.cancel();
      final XFile file = await _controller.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isStopping = false;
        _remainingSeconds = _maxVideoSeconds;
      });
      Navigator.pop(context, File(file.path));
    } catch (e) {
      debugPrint("Stop recording error: $e");
      if (mounted) {
        setState(() => _isStopping = false);
      }
    }
  }

  void _handleZoom(ScaleUpdateDetails details) {
    double zoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    setState(() {
      _currentZoom = zoom;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 10), () {
      _controller.setZoomLevel(zoom);
    });
  }

  void _applyZoom(double zoom) {
    zoom = zoom.clamp(_minZoom, _maxZoom);
    setState(() {
      _currentZoom = zoom;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 10), () {
      _controller.setZoomLevel(zoom);
    });
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

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _recordTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (!_ready) return const CameraShimmerLoader();
    final size = MediaQuery.of(context).size;
    var previewAspect = _controller.value.aspectRatio;
    if (size.height > size.width) {
      previewAspect = 1 / previewAspect;
    }
    double scale = size.aspectRatio / previewAspect;
    if (scale < 1) scale = 1 / scale;
    return NativeDeviceOrientationReader(
      useSensor: true,
      builder: (context) {
        final orientation = NativeDeviceOrientationReader.orientation(context);

        // Map physical sensor orientation to RotatedBox turns
        int turns = 0;
        if (orientation == NativeDeviceOrientation.landscapeLeft) turns = 1;
        if (orientation == NativeDeviceOrientation.landscapeRight) turns = 3;
        if (orientation == NativeDeviceOrientation.portraitDown) turns = 2;
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleZoom,
                child: Transform.scale(
                  scale: scale,
                  child: Center(child: CameraPreview(_controller)),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(
                    _flashIcon,
                    color: ColorConstants.whiteColor,
                    size: 28,
                  ),
                  onPressed: _toggleFlash,
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: ColorConstants.whiteColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    RotatedBox(
                      quarterTurns: turns,
                      child: Text(
                        "${_currentZoom.toStringAsFixed(1)}x",
                        style: const TextStyle(
                          color: ColorConstants.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: ColorConstants.whiteColor,
                              size: 30,
                            ),
                            onPressed: _zoomOut,
                          ),
                          Expanded(
                            child: SfSlider(
                              min: _minZoom,
                              max: _maxZoom,
                              value: _currentZoom,
                              interval: 1,
                              showTicks: true,
                              showLabels: false,
                              onChanged: (dynamic value) async {
                                double zoom = value.clamp(_minZoom, _maxZoom);
                                await _controller.setZoomLevel(zoom);
                                setState(() {
                                  _currentZoom = zoom;
                                });
                                _debounce?.cancel();
                                _debounce = Timer(
                                  const Duration(milliseconds: 120),
                                  () {
                                    _controller.setZoomLevel(zoom);
                                  },
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: ColorConstants.whiteColor,
                              size: 30,
                            ),
                            onPressed: _zoomIn,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isRecording)
                Positioned(
                  top: 50,
                  left: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.blackColor.withOpacity(0.6),
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
                          "REC $_remainingSeconds s",
                          style: const TextStyle(
                            color: ColorConstants.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned.fill(
                child: isLandscape
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _buildCaptureButton(),
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: _buildCaptureButton(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isStopping
          ? null
          : widget.isVideo
          ? (_isRecording ? _stopRecording : _startRecording)
          : _takePhoto,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: ColorConstants.buttonGradient,
        ),
        child: Center(
          child: _isStopping
              ? const CircularProgressIndicator(
                  color: ColorConstants.whiteColor,
                  strokeWidth: 2,
                )
              : Icon(
                  _isRecording
                      ? Icons.stop
                      : widget.isVideo
                      ? Icons.camera
                      : Icons.camera,
                  color: ColorConstants.whiteColor,
                  size: 40,
                ),
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
