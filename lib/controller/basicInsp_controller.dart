import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/model/upload_queue_model.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:inspection/utils/network_sync_manager.dart';
import 'package:inspection/view/basicInspection_screen/widget/carDiagram_screen.dart';
import 'package:inspection/view/basicInspection_screen/widget/signature_screen.dart';
import 'package:inspection/view/global_widgets/cameraCaptureScreen.dart';
import 'package:inspection/view/inspection_screen/widgets/fullscreen_image_screen.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_fullscreenvideo.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

enum MediaType { image, video }

enum InspectionStage {
  externalImages,
  additionalImages,
  external360,
  internalImages,
  internal360,
  diagram,
  signature,
  completed,
}

class BasicinspController extends ChangeNotifier {
  final int jobId;
  BasicinspController({required this.jobId});
  TextEditingController notesController = TextEditingController();
  List<Map<String, dynamic>> basicimageList = [];
  List<dynamic> externalImageSettings = [];
  Map<String, dynamic>? imageData;
  List<dynamic> externalImageList = [];
  List<dynamic> internalImageList = [];
  List<dynamic> currentImages = [];
  int currentStep = 0;
  bool isExternalSelected = true;
  bool showValidation = false;
  final SpeechToText _speechToText = SpeechToText();
  bool speechEnabled = false;
  bool isListening = false;
  bool showListeningUI = false;
  String notes = '';
  Timer? silenceTimer;
  Map<String, dynamic>? currentSectionData;
  String lastErrorMessage = "";
  File? _capturedVideo;
  File? get capturedVideo => _capturedVideo;
  List<File?> _capturedImages = [];
  List<File> get capturedImages => _capturedImages.whereType<File>().toList();
  List<bool> capturedStatus = [];
  bool isImageLoading = false;
  bool isVideoLoading = false;
  bool isNotApplicable = false;
  bool isSuccess = false;
  InspectionStage currentStage = InspectionStage.externalImages;
  bool isQuick = false;
  String? carDiagramPath;
  String? signaturePath;
  bool isUploading = false;
  bool isCompleted = false;
  bool isLoading = true;
  bool get isBackendFullyConfigured => externalImageList.isNotEmpty;

  Set<int> completedImageIds = {};
  int? lastcompleteId;
  bool isResumeLoaded = false;
  bool hasOpenedResumeStage = false;

  int get firstExternalImageId {
    if (externalImageList.isNotEmpty) {
      final images = externalImageList.first['images'] ?? [];
      if (images.isNotEmpty) {
        return images.first['id'] ?? 0;
      }
    }
    return 0;
  }

  int get firstInternalImageId {
    if (internalImageList.isNotEmpty) {
      final images = internalImageList.first['images'] ?? [];
      if (images.isNotEmpty) {
        return images.first['id'] ?? 0;
      }
    }
    return 0;
  }

  void checkAndShowResumeStage(BuildContext context) {
    if (isResumeLoaded && !hasOpenedResumeStage) {
      if (currentStage == InspectionStage.diagram) {
        hasOpenedResumeStage = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            openCarDiagram(context);
          }
        });
      } else if (currentStage == InspectionStage.signature) {
        hasOpenedResumeStage = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            openSignature(context);
          }
        });
      } else if (currentStage == InspectionStage.completed && isQuick) {
        hasOpenedResumeStage = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/quickInspectionSummary', extra: jobId);
          }
        });
      }
    }
  }

  Future<void> initSpeech() async {
    speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!speechEnabled) return;
    await _speechToText.stop();
    await _speechToText.cancel();
    isListening = true;
    showListeningUI = true;
    notifyListeners();
    await _speechToText.listen(
      onResult: onSpeechResult,
      listenMode: ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(minutes: 2),
    );
  }

  Future<void> runWithLoader(Future<void> Function() action) async {
    if (isUploading) return;
    isUploading = true;
    notifyListeners();
    try {
      await action();
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  void startSilenceTimer() {
    silenceTimer?.cancel();
    silenceTimer = Timer(const Duration(seconds: 2), () {
      if (isListening) {
        stopListening();
      }
    });
  }

  Future<void> stopListening() async {
    silenceTimer?.cancel();
    await _speechToText.stop();
    isListening = false;
    showListeningUI = false;
    notifyListeners();
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    if (!isListening) return;
    startSilenceTimer();
    if (result.finalResult) {
      final newText = result.recognizedWords.trim();
      if (newText.isEmpty) return;
      if (notesController.text.isEmpty) {
        notesController.text = newText;
      } else {
        notesController.text = "${notesController.text.trim()} $newText";
      }
      notes = notesController.text;
      notifyListeners();
    }
  }

  String get currentStageLabel {
    if (currentStage == InspectionStage.external360) {
      return "Final External 360 Video";
    }
    if (currentStage == InspectionStage.internal360) {
      return "Final Internal 360 Video";
    }
    return currentItem?['imageLabel'] ?? "";
  }

  bool get hasAnyMedia {
    if (isCurrentStageCompleted) return true;
    final hasImage = _capturedImages.any((file) => file != null);
    final hasVideo = capturedVideo != null;
    return hasImage || hasVideo;
  }

  bool validateMandatoryImage() {
    if (isCurrentStageCompleted) {
      showValidation = false;
      return true;
    }
    if (is360Stage) {
      if (_capturedVideo == null) {
        showValidation = true;
        notifyListeners();
        return false;
      }
      showValidation = false;
      return true;
    }
    if (currentStage == InspectionStage.additionalImages) {
      bool hasImage = _capturedImages.any((img) => img != null);
      if (!hasImage) {
        showValidation = true;
        notifyListeners();
        return false;
      }
      showValidation = false;
      return true;
    }
    final item = currentItem;
    if (item == null) return false;
    bool isMandatory = item['imageMandatory'] ?? false;
    if (!isMandatory) {
      showValidation = false;
      return true;
    }
    bool hasImage = _capturedImages.any((img) => img != null);
    if (!hasImage) {
      showValidation = true;
      notifyListeners();
      return false;
    }
    showValidation = false;
    return true;
  }

  Future<void> handleImageTap(
    BuildContext context, {
    required int imageIndex,
    required MediaType mediaType,
    int? maxDuration,
  }) async {
    if (isNotApplicable || isSuccess) return;
    if (mediaType == MediaType.image && isImageLoading) return;
    if (mediaType == MediaType.video && isVideoLoading) return;
    mediaType == MediaType.image
        ? isImageLoading = true
        : isVideoLoading = true;
    notifyListeners();
    try {
      int currentAngle = 0;
      File? currentFile = mediaType == MediaType.image
          ? _capturedImages[imageIndex]
          : _capturedVideo;
      if (currentFile == null) {
        final dynamic result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CameraCaptureScreen(
              isVideo: mediaType == MediaType.video,
              videoDuration: maxDuration,
            ),
          ),
        );
        if (result == null) return;
        if (result is Map) {
          currentFile = result['file'];
          currentAngle = result['angle'] ?? 0;
        } else if (result is File) {
          currentFile = result;
        }
      }
      while (true) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => mediaType == MediaType.image
                ? FullScreenImageScreen(
                    imageFile: currentFile!,
                    angle: currentAngle, // Passing the angle here
                  )
                : InspectionFullScreenVideo(
                    videoUrl: currentFile!.path,
                    label: "Video",
                  ),
          ),
        );
        if (result == null) return;
        if (result == "recapture") {
          final dynamic captureResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CameraCaptureScreen(
                isVideo: mediaType == MediaType.video,
                videoDuration: maxDuration,
              ),
            ),
          );
          if (captureResult == null) return;
          if (captureResult is Map) {
            currentFile = captureResult['file'];
            currentAngle = captureResult['angle'] ?? 0;
          } else if (captureResult is File) {
            currentFile = captureResult;
          }
          continue;
        }
        if (result is File) {
          if (mediaType == MediaType.image) {
            final compressed = await compressImage(result);
            await _deleteOldImage(_capturedImages[imageIndex]);
            _capturedImages[imageIndex] = compressed;
          } else {
            final compressedVideo = await compressVideo(result);
            await _deleteOldVideo(_capturedVideo);
            _capturedVideo = compressedVideo;
          }
          notifyListeners();
          return;
        }
      }
    } finally {
      mediaType == MediaType.image
          ? isImageLoading = false
          : isVideoLoading = false;
      notifyListeners();
    }
  }

  Future<void> _deleteOldImage(File? file) async {
    try {
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _deleteOldVideo(File? file) async {
    try {
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final XFile? compressedXFile =
        await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 60,
          format: CompressFormat.jpeg,
          minWidth: 1080,
          minHeight: 1080,
        );
    if (compressedXFile == null) return file;
    final compressedFile = File(compressedXFile.path);
    return compressedFile;
  }

  Future<File> compressVideo(File videoFile) async {
    try {
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: false,
      );
      if (info == null || info.file == null) {
        return videoFile;
      }
      return info.file!;
    } catch (e) {
      debugPrint("Video compression error: $e");
      return videoFile;
    }
  }

  void _safeSortImages(List images) {
    try {
      images.sort((a, b) {
        int aSort = 0;
        int bSort = 0;
        if (a != null && a['sortOrder'] != null) {
          aSort = int.tryParse(a['sortOrder'].toString()) ?? 0;
        }
        if (b != null && b['sortOrder'] != null) {
          bSort = int.tryParse(b['sortOrder'].toString()) ?? 0;
        }
        return aSort.compareTo(bSort);
      });
    } catch (e) {
      debugPrint("Sort Error: $e");
    }
  }

  Future<void> getBasicimageList() async {
    isLoading = true;
    notifyListeners();
    await getBasicInspection(jobId);
    final String urlStr = isQuick 
        ? ApiServices.quickImageSettingsMobile 
        : ApiServices.basicimageSettingList;
    final url = Uri.parse(urlStr);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        imageData = res['data'];
        externalImageList = imageData?['externalList'] ?? [];
        internalImageList = imageData?['internalList'] ?? [];
        if (externalImageList.isNotEmpty) {
          List images = List.from(externalImageList.first['images']);
          _safeSortImages(images);
          externalImageList.first['images'] = images;
        }
        if (internalImageList.isNotEmpty) {
          List images = List.from(internalImageList.first['images']);
          _safeSortImages(images);
          internalImageList.first['images'] = images;
        }
        _calculateResumeStep();
        isLoading = false;
        notifyListeners();
      } else {
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  // void _calculateResumeStep() {
  //   if (externalImageList.isNotEmpty) {
  //     final section = externalImageList.first;
  //     final images = List.from(section['images']);
  //     for (int i = 0; i < images.length; i++) {
  //       final id = images[i]['id'];
  //       final mandatory = images[i]['imageMandatory'] ?? false;
  //       if (mandatory && !completedImageIds.contains(id)) {
  //         currentStage = InspectionStage.externalImages;
  //         currentSectionData = section;
  //         currentImages = images;
  //         currentStep = i;
  //         isExternalSelected = true;
  //         _initializeCaptureList();
  //         return;
  //       }
  //       if (!mandatory && !completedImageIds.contains(id)) {
  //         completedImageIds.add(id);
  //       }
  //     }
  //     if (!completedImageIds.contains(-10)) {
  //       currentStage = InspectionStage.external360;
  //       currentSectionData = section;
  //       currentImages = [];
  //       _capturedVideo = null;
  //       return;
  //     }
  //   }
  //   if (internalImageList.isNotEmpty) {
  //     final section = internalImageList.first;
  //     final images = List.from(section['images']);
  //     for (int i = 0; i < images.length; i++) {
  //       final id = images[i]['id'];
  //       final mandatory = images[i]['imageMandatory'] ?? false;
  //       if (mandatory && !completedImageIds.contains(id)) {
  //         currentStage = InspectionStage.internalImages;
  //         currentSectionData = section;
  //         currentImages = images;
  //         currentStep = i;
  //         isExternalSelected = false;
  //         _initializeCaptureList();
  //         return;
  //       }
  //       if (!mandatory && !completedImageIds.contains(id)) {
  //         completedImageIds.add(id);
  //       }
  //     }
  //     if (!completedImageIds.contains(-20)) {
  //       currentStage = InspectionStage.internal360;
  //       currentSectionData = section;
  //       currentImages = [];
  //       _capturedVideo = null;
  //       return;
  //     }
  //   }
  //   if (!completedImageIds.contains(-30)) {
  //     currentStage = InspectionStage.diagram;
  //     return;
  //   }
  //   if (!completedImageIds.contains(-40)) {
  //     currentStage = InspectionStage.signature;
  //     return;
  //   }
  //   currentStage = InspectionStage.completed;
  // }

  List<Map<String, dynamic>> buildFlowSteps() {
    List<Map<String, dynamic>> steps = [];
    if (!isQuick && internalImageList.isNotEmpty) {
      final section = internalImageList.first;
      final images = List.from(section['images'] ?? []);
      _safeSortImages(images);
      for (int i = 0; i < images.length; i++) {
        steps.add({
          'stage': InspectionStage.internalImages,
          'index': i,
          'id': images[i]['id'],
          'isMandatory': images[i]['imageMandatory'] ?? false,
        });
      }
      steps.add({
        'stage': InspectionStage.internal360,
        'index': null,
        'id': -20,
        'isMandatory': false,
      });
    }
    if (externalImageList.isNotEmpty) {
      final section = externalImageList.first;
      final images = List.from(section['images'] ?? []);
      _safeSortImages(images);
      for (int i = 0; i < images.length; i++) {
        steps.add({
          'stage': InspectionStage.externalImages,
          'index': i,
          'id': images[i]['id'],
          'isMandatory': isQuick ? false : (images[i]['imageMandatory'] ?? false),
        });
      }
      if (isQuick) {
        final int additionalCount = section['additionalImages'] ?? 0;
        for (int i = 0; i < additionalCount; i++) {
          steps.add({
            'stage': InspectionStage.additionalImages,
            'index': i,
            'id': -100 - i,
            'isMandatory': false,
          });
        }
      }
      steps.add({
        'stage': InspectionStage.external360,
        'index': null,
        'id': -10,
        'isMandatory': isQuick ? false : true,
      });
    }
    steps.add({
      'stage': InspectionStage.diagram,
      'index': null,
      'id': -30,
      'isMandatory': true,
    });
    if (!isQuick) {
      steps.add({
        'stage': InspectionStage.signature,
        'index': null,
        'id': -40,
        'isMandatory': true,
      });
    }
    return steps;
  }

  void _calculateResumeStep() {
    final steps = buildFlowSteps();
    if (steps.isEmpty) {
      isResumeLoaded = true;
      notifyListeners();
      return;
    }
    int resumeIndex = steps.length;
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final id = step['id'];
      bool isCompleted = completedImageIds.contains(id);
      if (lastcompleteId != null) {
        if (id == lastcompleteId ||
            (id == -20 && lastcompleteId == 2) ||
            (id == -10 && lastcompleteId == 1)) {
          isCompleted = true;
        }
      }
      if (!isCompleted) {
        resumeIndex = i;
        break;
      }
    }
    if (resumeIndex < steps.length) {
      final resumeStep = steps[resumeIndex];
      currentStage = resumeStep['stage'];
      if (currentStage != InspectionStage.diagram &&
          currentStage != InspectionStage.signature) {
        hasOpenedResumeStage = true;
      }
      if (currentStage == InspectionStage.internalImages) {
        currentSectionData = internalImageList.first;
        currentImages = List.from(currentSectionData!['images'] ?? []);
        _safeSortImages(currentImages);
        currentStep = resumeStep['index'];
        isExternalSelected = false;
        _initializeCaptureList();
      } else if (currentStage == InspectionStage.internal360) {
        currentSectionData = internalImageList.first;
        currentImages = [];
        _capturedVideo = null;
      } else if (currentStage == InspectionStage.externalImages) {
        currentSectionData = externalImageList.first;
        currentImages = List.from(currentSectionData!['images'] ?? []);
        _safeSortImages(currentImages);
        currentStep = resumeStep['index'];
        isExternalSelected = true;
        _initializeCaptureList();
      } else if (currentStage == InspectionStage.additionalImages) {
        currentSectionData = externalImageList.first;
        currentImages = [];
        currentStep = resumeStep['index'];
        isExternalSelected = true;
        _initializeCaptureList();
      } else if (currentStage == InspectionStage.external360) {
        currentSectionData = externalImageList.first;
        currentImages = [];
        _capturedVideo = null;
      } else if (currentStage == InspectionStage.diagram) {
        currentSectionData = null;
        currentImages = [];
      } else if (currentStage == InspectionStage.signature) {
        currentSectionData = null;
        currentImages = [];
      }
    } else {
      currentStage = InspectionStage.completed;
      currentSectionData = null;
      currentImages = [];
      hasOpenedResumeStage = true;
    }
    isResumeLoaded = true;
    notifyListeners();
  }

  Map<String, dynamic>? get currentItem {
    if (currentImages.isEmpty) return null;
    if (currentStep >= currentImages.length) return null;
    return currentImages[currentStep];
  }

  File? imageAt(int index) {
    if (index < 0 || index >= _capturedImages.length) return null;
    return _capturedImages[index];
  }

  int get current360Duration {
    return currentSectionData?['inspection360Duration'] ?? 30;
  }

  bool get isCurrentMandatory {
    if (isQuick) return false;
    final item = currentItem;
    if (item == null) return false;
    return item['imageMandatory'] ?? false;
  }

  bool get is360Stage =>
      currentStage == InspectionStage.external360 ||
      currentStage == InspectionStage.internal360;
  bool get isCurrentStageCompleted {
    if (currentStage == InspectionStage.additionalImages) {
      return completedImageIds.contains(-100 - currentStep);
    }
    if (currentStage == InspectionStage.external360) {
      return completedImageIds.contains(-10);
    }
    if (currentStage == InspectionStage.internal360) {
      return completedImageIds.contains(-20);
    }
    if (currentStage == InspectionStage.diagram) {
      return completedImageIds.contains(-30);
    }
    if (currentStage == InspectionStage.signature) {
      return completedImageIds.contains(-40);
    }
    final item = currentItem;
    if (item != null) {
      return completedImageIds.contains(item['id']);
    }
    return false;
  }

  bool get shouldShowSkip {
    if (currentStage == InspectionStage.diagram ||
        currentStage == InspectionStage.signature) {
      return false;
    }
    if (currentStage == InspectionStage.external360) {
      return isQuick;
    }
    if (currentStage == InspectionStage.internal360) {
      return true;
    }
    return !isCurrentMandatory;
  }

  int get currentAttachType {
    if (isQuick) {
      if (currentStage == InspectionStage.additionalImages) {
        return 15;
      }
      if (currentStage == InspectionStage.externalImages || currentStage == InspectionStage.internalImages) {
        return 14;
      }
    }
    switch (currentStage) {
      case InspectionStage.externalImages:
      case InspectionStage.internalImages:
      case InspectionStage.additionalImages:
        return 0;
      case InspectionStage.external360:
      case InspectionStage.internal360:
        return 10;
      case InspectionStage.diagram:
        return 11;
      case InspectionStage.signature:
        return 12;
      case InspectionStage.completed:
        return 0;
    }
  }

  void _initializeCaptureList({bool reset = true}) {
    int imageCount = 0;
    if (currentStage == InspectionStage.additionalImages) {
      imageCount = 1;
    } else {
      final item = currentItem;
      imageCount = item?['imageCount'] ?? 0;
    }
    if (reset || _capturedImages.length != imageCount) {
      _capturedImages = List<File?>.filled(imageCount, null);
      capturedStatus = List.generate(imageCount, (_) => false);
    }
    _capturedVideo = null;
    showValidation = false;
    notifyListeners();
  }

  void nextStep(BuildContext context) {
    showValidation = false;
    if (currentStage == InspectionStage.additionalImages) {
      completedImageIds.add(-100 - currentStep);
      final int additionalCount = externalImageList.isNotEmpty 
          ? (externalImageList.first['additionalImages'] ?? 0)
          : 0;
      if (currentStep + 1 < additionalCount) {
        currentStep = currentStep + 1;
        _initializeCaptureList();
        notifyListeners();
        return;
      }
      if (externalImageList.isNotEmpty &&
          externalImageList.first['inspection360Duration'] != null) {
        currentStage = InspectionStage.external360;
        currentSectionData = externalImageList.first;
        currentImages = [];
        _capturedVideo = null;
        _initializeCaptureList();
        notifyListeners();
        return;
      }
      currentStage = InspectionStage.diagram;
      notifyListeners();
      openCarDiagram(context);
      return;
    }
    if (currentStage == InspectionStage.externalImages ||
        currentStage == InspectionStage.internalImages) {
      if (currentItem != null) {
        completedImageIds.add(currentItem!['id']);
      }
      int nextIndex = -1;
      for (int i = currentStep + 1; i < currentImages.length; i++) {
        final id = currentImages[i]['id'];
        if (!completedImageIds.contains(id)) {
          nextIndex = i;
          break;
        }
      }
      if (nextIndex != -1) {
        currentStep = nextIndex;
        _initializeCaptureList();
        notifyListeners();
        return;
      }
      if (currentStage == InspectionStage.externalImages) {
        if (isQuick) {
          final int additionalCount = externalImageList.isNotEmpty 
              ? (externalImageList.first['additionalImages'] ?? 0)
              : 0;
          if (additionalCount > 0) {
            currentStage = InspectionStage.additionalImages;
            currentImages = [];
            currentStep = 0;
            _initializeCaptureList();
            notifyListeners();
            return;
          }
        }
        if (externalImageList.isNotEmpty &&
            externalImageList.first['inspection360Duration'] != null) {
          currentStage = InspectionStage.external360;
          currentSectionData = externalImageList.first;
          currentImages = [];
          _capturedVideo = null;
          _initializeCaptureList();
          notifyListeners();
          return;
        }
      }
      if (currentStage == InspectionStage.internalImages) {
        if (internalImageList.isNotEmpty &&
            internalImageList.first['inspection360Duration'] != null) {
          currentStage = InspectionStage.internal360;
          currentSectionData = internalImageList.first;
          currentImages = [];
          _capturedVideo = null;
          _initializeCaptureList();
          notifyListeners();
          return;
        }
      }
      _moveToNextStage(context);
      return;
    }
    _moveToNextStage(context);
  }

  void _moveToNextStage(BuildContext context) {
    if (currentStage == InspectionStage.internalImages) {
      currentStage = InspectionStage.internal360;
      _capturedVideo = null;
      notifyListeners();
      return;
    }
    if (currentStage == InspectionStage.internal360) {
      if (externalImageList.isNotEmpty) {
        currentStage = InspectionStage.externalImages;
        isExternalSelected = true;
        currentSectionData = externalImageList.first;
        currentImages = List.from(currentSectionData!['images'] ?? []);
        _safeSortImages(currentImages);
        currentStep = 0;
        _initializeCaptureList();
        notifyListeners();
        return;
      }
      currentStage = InspectionStage.diagram;
      notifyListeners();
      openCarDiagram(context);
      return;
    }
    if (currentStage == InspectionStage.externalImages) {
      if (isQuick) {
        final int additionalCount = externalImageList.isNotEmpty 
            ? (externalImageList.first['additionalImages'] ?? 0)
            : 0;
        if (additionalCount > 0) {
          currentStage = InspectionStage.additionalImages;
          currentImages = [];
          currentStep = 0;
          _initializeCaptureList();
          notifyListeners();
          return;
        }
      }
      currentStage = InspectionStage.external360;
      _capturedVideo = null;
      notifyListeners();
      return;
    }
    if (currentStage == InspectionStage.additionalImages) {
      if (externalImageList.isNotEmpty &&
          externalImageList.first['inspection360Duration'] != null) {
        currentStage = InspectionStage.external360;
        currentSectionData = externalImageList.first;
        currentImages = [];
        _capturedVideo = null;
        _initializeCaptureList();
        notifyListeners();
        return;
      }
      currentStage = InspectionStage.diagram;
      notifyListeners();
      openCarDiagram(context);
      return;
    }
    if (currentStage == InspectionStage.external360) {
      currentStage = InspectionStage.diagram;
      notifyListeners();
      openCarDiagram(context);
      return;
    }
    if (currentStage == InspectionStage.diagram) {
      if (isQuick) {
        currentStage = InspectionStage.completed;
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            context.go('/quickInspectionSummary', extra: jobId);
          }
        });
        return;
      }
      currentStage = InspectionStage.signature;
      notifyListeners();
      openSignature(context);
      return;
    }
    if (currentStage == InspectionStage.signature) {
      currentStage = InspectionStage.completed;
      notifyListeners();
      return;
    }
  }

  void _moveToNextIncompleteImage(BuildContext context) {
    if (currentStage == InspectionStage.additionalImages) {
      final int additionalCount = externalImageList.isNotEmpty 
          ? (externalImageList.first['additionalImages'] ?? 0)
          : 0;
      if (currentStep + 1 < additionalCount) {
        currentStep = currentStep + 1;
        _initializeCaptureList();
        notifyListeners();
        return;
      }
      _moveToNextStage(context);
      return;
    }
    if (currentImages.isEmpty) {
      _moveToNextStage(context);
      return;
    }
    for (int i = currentStep + 1; i < currentImages.length; i++) {
      final imageId = currentImages[i]['id'];
      if (!completedImageIds.contains(imageId)) {
        currentStep = i;
        _initializeCaptureList();
        notifyListeners();
        return;
      }
    }
    _moveToNextStage(context);
  }

  Future<void> skipStep(BuildContext context) async {
    if (currentItem != null) {
      final int skippedId = currentItem!['id'];
      completedImageIds.add(skippedId);
      await LocalUploadStorageService.saveSkippedImageId(jobId, skippedId);
    } else if (currentStage == InspectionStage.additionalImages) {
      completedImageIds.add(-100 - currentStep);
      await LocalUploadStorageService.saveSkippedImageId(jobId, -100 - currentStep);
    } else if (currentStage == InspectionStage.internal360) {
      completedImageIds.add(-20);
      await LocalUploadStorageService.saveSkippedImageId(jobId, -20);
    } else if (currentStage == InspectionStage.external360) {
      completedImageIds.add(-10);
      await LocalUploadStorageService.saveSkippedImageId(jobId, -10);
    }
    // When skipping on additionalImages, jump directly to external360
    // (or diagram if no 360 configured), bypassing remaining additional images.
    if (currentStage == InspectionStage.additionalImages) {
      _moveToNextStage(context);
    } else {
      _moveToNextIncompleteImage(context);
    }
  }

  void openCarDiagram(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: this,
          child: CardiagramScreen(jobId: jobId),
        ),
      ),
    );
    if (result != null) {
      carDiagramPath = result;
      notifyListeners();
      if (isQuick) {
        currentStage = InspectionStage.completed;
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            context.go('/quickInspectionSummary', extra: jobId);
          }
        });
      } else {
        openSignature(context);
      }
    }
  }

  void openSignature(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: this,
          child: SignatureScreen(jobId: jobId),
        ),
      ),
    );
    if (result != null) {
      signaturePath = result;
      notifyListeners();
    }
  }

  void setSignatureFile(File file) {
    _capturedImages = [file];
    _capturedVideo = null;
    notifyListeners();
  }

  void setDiagramFile(File file) {
    _capturedImages = [file];
    _capturedVideo = null;
    notifyListeners();
  }

  Future<bool> proceedStep({
    required int jobId,
    required int status,
    String additionalComment = "",
  }) async {
    final item = currentItem;
    final bool hasNewMedia = is360Stage 
        ? (_capturedVideo != null) 
        : (_capturedImages.any((img) => img != null) || _capturedVideo != null);
    if (isCurrentStageCompleted && !hasNewMedia) {
      return true;
    }
    if (item == null &&
        currentStage != InspectionStage.diagram &&
        currentStage != InspectionStage.signature &&
        currentStage != InspectionStage.additionalImages &&
        !is360Stage) {
      return false;
    }
    bool isMandatory = currentStage == InspectionStage.additionalImages ? false : (item?['imageMandatory'] ?? false);
    int imageCount = currentStage == InspectionStage.additionalImages ? 1 : (item?['imageCount'] ?? 0);
    showValidation = isMandatory;
    final String inspectionNote = notesController.text.trim();
    if (isMandatory && imageCount > 0) {
      if (_capturedImages.isEmpty ||
          !_capturedImages.any((img) => img != null)) {
        return false;
      }
    }
    if (currentStage == InspectionStage.signature) {
      if (_capturedImages.isEmpty || _capturedImages.first == null) {
        return false;
      }
    }
    final hasNet = await NetworkSyncManager().checkInternetConnection();

    isUploading = true;
    lastErrorMessage = "";
    notifyListeners();
    String imageId = "";
    List<Map<String, dynamic>> mediaItems = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      if (token == null || token.isEmpty) {
        return false;
      }
      Dio dio = Dio()
        ..options.headers = {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        };
      int imageIdVal = 0;
      if (item != null) {
        imageIdVal = item['id'];
      } else if (currentStage == InspectionStage.internal360) {
        imageIdVal = firstInternalImageId;
      } else if (currentStage == InspectionStage.external360) {
        imageIdVal = firstExternalImageId;
      }
      imageId = imageIdVal != 0 ? imageIdVal.toString() : "";
      if (is360Stage) {
        if (_capturedVideo != null && await _capturedVideo!.exists()) {
          mediaItems.add({
            "file": _capturedVideo,
            "type": "2",
            "is360": true,
          });
        }
      } else {
        int imgIndex = 0;
        for (var img in _capturedImages) {
          if (img != null && await img.exists()) {
            mediaItems.add({
              "file": img,
              "type": "0",
              "imgIndex": imgIndex,
              "is360": false,
            });
            imgIndex++;
          }
        }
        if (_capturedVideo != null && await _capturedVideo!.exists()) {
          mediaItems.add({
            "file": _capturedVideo,
            "type": "2",
            "is360": false,
          });
        }
      }

      if (!hasNet) {
        print("🌐 [BasicInspController] Device is offline. Saving inspection step locally...");
        List<MediaItemQueue> queueMediaItems = [];
        for (var m in mediaItems) {
          final File fileObj = m["file"];
          final String typeVal = m["type"] ?? "0";
          final bool is360Val = m["is360"] ?? false;
          final int imgIndex = m["imgIndex"] ?? 0;
          queueMediaItems.add(MediaItemQueue(
            filePath: fileObj.path,
            type: typeVal,
            is360: is360Val,
            imgIndex: imgIndex,
          ));
        }

        final fields = <String, String>{
          "jobId": jobId.toString(),
          "job_id": jobId.toString(),
          "inspectionImageId": imageId.toString(),
          "inspection_image_id": imageId.toString(),
          "status": status.toString(),
          "inspectionNote": inspectionNote,
          "additionalComment": additionalComment,
          "attachType": currentAttachType.toString(),
        };

        await LocalUploadStorageService.enqueueOfflineTask(
          jobId: jobId,
          endpointUrl: ApiServices.basicInspection,
          mediaItems: queueMediaItems,
          fields: fields,
        );

        await NetworkSyncManager().refreshPendingCount();

        if (!is360Stage && item != null) {
          completedImageIds.add(item['id']);
        }
        if (currentStage == InspectionStage.additionalImages) {
          completedImageIds.add(-100 - currentStep);
        }
        if (currentStage == InspectionStage.external360) {
          completedImageIds.add(-10);
        }
        if (currentStage == InspectionStage.internal360) {
          completedImageIds.add(-20);
        }
        if (currentStage == InspectionStage.diagram) {
          completedImageIds.add(-30);
        }
        if (currentStage == InspectionStage.signature) {
          completedImageIds.add(-40);
        }

        print("💾 [BasicInspController] Saved inspection step locally for job $jobId.");
        return true;
      }

      if (mediaItems.isEmpty) {
        FormData formData = FormData();
        formData.fields.addAll([
          MapEntry("jobId", jobId.toString()),
          MapEntry("job_id", jobId.toString()),
          MapEntry("inspectionImageId", imageId),
          MapEntry("inspection_image_id", imageId),
          MapEntry("status", status.toString()),
          MapEntry("inspectionNote", inspectionNote),
          MapEntry("additionalComment", additionalComment),
          MapEntry("attachType", currentAttachType.toString()),
        ]);

        final response = await dio.post(
          ApiServices.basicInspection,
          data: formData,
        );

        if (response.statusCode == 200) {
          final resData = response.data;
          if (resData is Map) {
            final bodyStatusCode = resData['statusCode'];
            final bodyStatus = resData['status'];
            if (bodyStatusCode == 400 || bodyStatusCode == "400" || bodyStatus == "FAILED") {
              return false;
            }
          }
          if (!is360Stage && item != null) {
            completedImageIds.add(item['id']);
          }
          if (currentStage == InspectionStage.additionalImages) {
            completedImageIds.add(-100 - currentStep);
          }
          if (currentStage == InspectionStage.external360) {
            completedImageIds.add(-10);
          }
          if (currentStage == InspectionStage.internal360) {
            completedImageIds.add(-20);
          }
          if (currentStage == InspectionStage.diagram) {
            completedImageIds.add(-30);
          }
          if (currentStage == InspectionStage.signature) {
            completedImageIds.add(-40);
          }

          // Clear any offline queue task & local media cache after successful online save
          await LocalUploadStorageService.removeTaskByImageId(jobId, imageId);
          await NetworkSyncManager().refreshPendingCount();
          return true;
        }
        notifyListeners();
        return false;
      } else {
        FormData formData = FormData();
        formData.fields.addAll([
          MapEntry("jobId", jobId.toString()),
          MapEntry("job_id", jobId.toString()),
          MapEntry("inspectionImageId", imageId),
          MapEntry("inspection_image_id", imageId),
          MapEntry("status", status.toString()),
          MapEntry("inspectionNote", inspectionNote),
          MapEntry("additionalComment", additionalComment),
          MapEntry("attachType", currentAttachType.toString()),
        ]);

        for (int i = 0; i < mediaItems.length; i++) {
          final media = mediaItems[i];
          final File fileObj = media["file"];
          final String typeVal = media["type"];
          final bool is360Val = media["is360"];

          MultipartFile multipartFile;
          if (is360Val) {
            multipartFile = await MultipartFile.fromFile(
              fileObj.path,
              filename: "inspection_360_video_${DateTime.now().millisecondsSinceEpoch}.mp4",
              contentType: http_parser.MediaType("video", "mp4"),
            );
          } else if (typeVal == "0") {
            final int imgIndex = media["imgIndex"];
            String suffix = "image";
            if (currentStage == InspectionStage.diagram) {
              suffix = "diagram";
            } else if (currentStage == InspectionStage.signature) {
              suffix = "signature";
            }
            multipartFile = await MultipartFile.fromFile(
              fileObj.path,
              filename: "inspection_${suffix}_${imgIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg",
              contentType: http_parser.MediaType("image", "jpeg"),
            );
          } else {
            multipartFile = await MultipartFile.fromFile(
              fileObj.path,
              filename: "inspection_video_${DateTime.now().millisecondsSinceEpoch}.mp4",
              contentType: http_parser.MediaType("video", "mp4"),
            );
          }

          formData.files.add(MapEntry("mediaFiles[$i].file", multipartFile));
          formData.fields.add(MapEntry("mediaFiles[$i].type", typeVal));
        }
        final response = await dio.post(
          ApiServices.basicInspection,
          data: formData,
        );
        if (response.statusCode != 200) {
          notifyListeners();
          return false;
        }
        final resData = response.data;
        if (resData is Map) {
          final bodyStatusCode = resData['statusCode'];
          final bodyStatus = resData['status'];
          if (bodyStatusCode == 400 || bodyStatusCode == "400" || bodyStatus == "FAILED") {
            notifyListeners();
            return false;
          }
        }

        if (!is360Stage && item != null) {
          completedImageIds.add(item['id']);
        }
        if (currentStage == InspectionStage.additionalImages) {
          completedImageIds.add(-100 - currentStep);
        }
        if (currentStage == InspectionStage.external360) {
          completedImageIds.add(-10);
        }
        if (currentStage == InspectionStage.internal360) {
          completedImageIds.add(-20);
        }
        if (currentStage == InspectionStage.diagram) {
          completedImageIds.add(-30);
        }
        if (currentStage == InspectionStage.signature) {
          completedImageIds.add(-40);
        }

        // Clear any offline queue task & local media cache after successful online save
        for (var m in mediaItems) {
          final File? fileObj = m["file"];
          if (fileObj != null) {
            await LocalUploadStorageService.cleanupFile(fileObj.path);
          }
        }
        await LocalUploadStorageService.removeTaskByImageId(jobId, imageId);
        await NetworkSyncManager().refreshPendingCount();
        return true;
      }
    } catch (e) {
      print("📡 [BasicInspController] Network/Offline exception during upload: $e. Enqueuing task to local storage...");
      try {
        List<MediaItemQueue> queueMediaItems = [];
        for (var m in mediaItems) {
          final File fileObj = m["file"];
          final String typeVal = m["type"] ?? "0";
          final bool is360Val = m["is360"] ?? false;
          final int imgIndex = m["imgIndex"] ?? 0;
          queueMediaItems.add(MediaItemQueue(
            filePath: fileObj.path,
            type: typeVal,
            is360: is360Val,
            imgIndex: imgIndex,
          ));
        }

        final fields = <String, String>{
          "jobId": jobId.toString(),
          "job_id": jobId.toString(),
          "inspectionImageId": imageId.toString(),
          "inspection_image_id": imageId.toString(),
          "status": status.toString(),
          "inspectionNote": inspectionNote,
          "additionalComment": additionalComment,
          "attachType": currentAttachType.toString(),
        };

        await LocalUploadStorageService.enqueueOfflineTask(
          jobId: jobId,
          endpointUrl: ApiServices.basicInspection,
          mediaItems: queueMediaItems,
          fields: fields,
        );

        await NetworkSyncManager().refreshPendingCount();

        if (!is360Stage && item != null) {
          completedImageIds.add(item['id']);
        }
        if (currentStage == InspectionStage.additionalImages) {
          completedImageIds.add(-100 - currentStep);
        }
        if (currentStage == InspectionStage.external360) {
          completedImageIds.add(-10);
        }
        if (currentStage == InspectionStage.internal360) {
          completedImageIds.add(-20);
        }
        if (currentStage == InspectionStage.diagram) {
          completedImageIds.add(-30);
        }
        if (currentStage == InspectionStage.signature) {
          completedImageIds.add(-40);
        }

        print("💾 [BasicInspController] Saved inspection step locally for job $jobId.");
        return true;
      } catch (err) {
        print("❌ [BasicInspController] Error saving task offline: $err");
        lastErrorMessage = "Failed to save media locally. Please try again.";
        return false;
      }
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> getBasicInspection(int jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse(ApiServices.getBasicInspection),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"jobId": jobId}),
      );
      final result = jsonDecode(response.body);
      final data = result["data"];
      if (data == null) return;
      final typeStr = (data["jobInspectionType"] ?? data["inspectionType"] ?? "").toString().toUpperCase();
      if (typeStr == "QUICK" || typeStr.contains("QUICK") || data["isQuick"] == true) {
        isQuick = true;
      } else {
        isQuick = false;
      }
      if (data["lastcompleteId"] != null) {
        lastcompleteId = int.tryParse(data["lastcompleteId"].toString());
      } else if (data["lastCompletedId"] != null) {
        lastcompleteId = int.tryParse(data["lastCompletedId"].toString());
      } else {
        lastcompleteId = null;
      }
      final grouped = data["basicinspectionattachments"];
      if (grouped == null) return;
      completedImageIds.clear();
      List allAttachments = [];

      List externalImages = grouped["externalImages"] ?? [];
      for (var img in externalImages) {
        int? masterId = img["imageMasterId"] ?? img["id"] ?? img["inspectionImageId"];
        List attachments = img["attachments"] ?? [];
        if (attachments.isNotEmpty && masterId != null) {
          completedImageIds.add(masterId);
        }
        for (var att in attachments) {
          if (att["iaType"] == 2 && (att["iaImageType"] == 10 || att["iaInspectionType"] == 0 || att["is360"] == true)) {
            completedImageIds.add(-10);
          }
        }
        allAttachments.addAll(attachments);
      }

      List internalImages = grouped["internalImages"] ?? [];
      for (var img in internalImages) {
        int? masterId = img["imageMasterId"] ?? img["id"] ?? img["inspectionImageId"];
        List attachments = img["attachments"] ?? [];
        if (attachments.isNotEmpty && masterId != null) {
          completedImageIds.add(masterId);
        }
        for (var att in attachments) {
          if (att["iaType"] == 2 && (att["iaImageType"] == 10 || att["iaInspectionType"] == 1 || att["is360"] == true)) {
            completedImageIds.add(-20);
          }
        }
        allAttachments.addAll(attachments);
      }

      List quickImages = grouped["quickInspectionImages"] ?? [];
      for (var img in quickImages) {
        int? masterId = img["imageMasterId"] ?? img["id"] ?? img["inspectionImageId"];
        List attachments = img["attachments"] ?? [];
        if (attachments.isNotEmpty && masterId != null) {
          completedImageIds.add(masterId);
        }
        for (var att in attachments) {
          int? attImageId = att["iaInspectionImageId"] ?? att["inspectionImageId"] ?? att["imageMasterId"];
          if (attImageId != null && attImageId != 0) {
            completedImageIds.add(attImageId);
          }
          if (att["iaType"] == 2 && (att["iaImageType"] == 10 || att["is360"] == true)) {
            completedImageIds.add(-10);
          }
        }
        allAttachments.addAll(attachments);
      }

      List additionalImages = grouped["additionalImages"] ?? [];
      int validAddIndex = 0;
      for (var img in additionalImages) {
        List attachments = img["attachments"] ?? [];
        bool hasAttachment = attachments.isNotEmpty || img["iaUrl"] != null || img["url"] != null;
        if (hasAttachment) {
          completedImageIds.add(-100 - validAddIndex);
          validAddIndex++;
        }
        if (attachments.isNotEmpty) {
          allAttachments.addAll(attachments);
        }
      }

      bool has360 = grouped["external360"] != null || grouped["360"] != null || grouped["video360"] != null;
      if (!has360) {
        for (var att in allAttachments) {
          if (att["iaType"] == 2 && (att["iaImageType"] == 10 || att["is360"] == true)) {
            has360 = true;
            break;
          }
        }
      }
      if (has360) {
        completedImageIds.add(-10);
      }

      if (grouped["cardiagram"] != null) {
        completedImageIds.add(-30);
      }
      if (grouped["signature"] != null) {
        completedImageIds.add(-40);
      }

      // Include pending offline local queue items so offline progress is maintained across app returns
      try {
        final pendingQueue = await LocalUploadStorageService.getPendingTasks();
        int offlineAdditionalCount = 0;
        for (var task in pendingQueue) {
          if (task.jobId == jobId) {
            final imgIdStr = task.fields["inspectionImageId"] ?? task.fields["inspection_image_id"];
            if (imgIdStr != null && imgIdStr.isNotEmpty) {
              final parsedId = int.tryParse(imgIdStr);
              if (parsedId != null && parsedId != 0) {
                completedImageIds.add(parsedId);
              }
            }
            final attachType = task.fields["attachType"];
            if (attachType == "15") {
              completedImageIds.add(-100 - (validAddIndex + offlineAdditionalCount));
              offlineAdditionalCount++;
            }
            for (var item in task.mediaItems) {
              if (item.is360) {
                if (attachType == "0" || attachType == "14" || attachType == "10") {
                  completedImageIds.add(-10);
                } else {
                  completedImageIds.add(-20);
                }
              }
            }
          }
        }
      } catch (err) {
        debugPrint("Error merging offline queue ids: $err");
      }

      // Include skipped image IDs so skipped items are remembered offline
      try {
        final skippedIds = await LocalUploadStorageService.getSkippedImageIds(jobId);
        completedImageIds.addAll(skippedIds);
      } catch (err) {
        debugPrint("Error merging skipped image ids: $err");
      }

      isResumeLoaded = true;
    } catch (e) {
      debugPrint("Resume error: $e");
    }
  }
}

class VideoPreviewWidget extends StatefulWidget {
  final File file;
  const VideoPreviewWidget({super.key, required this.file});
  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        _controller.pause();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(color: Colors.black12);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
