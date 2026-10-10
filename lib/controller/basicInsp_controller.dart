import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/model/upload_queue_model.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:inspection/utils/network_sync_manager.dart';
import 'package:inspection/utils/permission_service.dart';
import 'package:inspection/controller/inspectionfullscreenvideo_Controller.dart';
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
  bool get isBusy => isVideoLoading || isUploading || isImageLoading;

  Set<int> completedImageIds = {};
  int? lastcompleteId;
  bool isResumeLoaded = false;
  bool hasOpenedResumeStage = false;
  // Persisted Quick Inspection stage loaded from SharedPreferences before _calculateResumeStep.
  // Only set for Quick Inspection (isQuick == true).
  String? _persistedQuickStage;

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

  Future<void> initSpeech([BuildContext? context]) async {
    if (context != null) {
      final hasMic = await PermissionService.instance.requestMicrophonePermission(context);
      if (!hasMic) return;
    }
    speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  Future<void> startListening([BuildContext? context]) async {
    if (context != null) {
      final hasMic = await PermissionService.instance.requestMicrophonePermission(context);
      if (!hasMic) return;
    }
    if (!speechEnabled) {
      speechEnabled = await _speechToText.initialize();
    }
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

  /// Returns null if current step validation passes for NEXT button.
  /// Otherwise returns the warning message string to be displayed to the user.
  String? validateNextStepMessage() {
    if (isCurrentStageCompleted) {
      showValidation = false;
      return null;
    }
    if (is360Stage) {
      if (_capturedVideo == null) {
        showValidation = true;
        notifyListeners();
        return "Please capture 360 video before continuing.";
      }
      showValidation = false;
      return null;
    }
    if (currentStage == InspectionStage.diagram) {
      if (_capturedImages.isEmpty || !_capturedImages.any((img) => img != null)) {
        showValidation = true;
        notifyListeners();
        return "Please complete diagram before continuing.";
      }
      showValidation = false;
      return null;
    }
    if (currentStage == InspectionStage.signature) {
      if (_capturedImages.isEmpty || _capturedImages.first == null) {
        showValidation = true;
        notifyListeners();
        return "Please provide signature before continuing.";
      }
      showValidation = false;
      return null;
    }

    // Image capture stages (internalImages, externalImages, additionalImages)
    bool hasImage = _capturedImages.any((img) => img != null);
    if (hasImage) {
      showValidation = false;
      return null;
    }

    // No image captured
    showValidation = true;
    notifyListeners();

    if (isCurrentMandatory) {
      return "Please capture the required image before continuing.";
    } else {
      return "Please capture an image or use Skip to continue.";
    }
  }

  bool validateMandatoryImage() {
    return validateNextStepMessage() == null;
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
          ? (imageIndex >= 0 && imageIndex < _capturedImages.length ? _capturedImages[imageIndex] : null)
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
                    angle: currentAngle,
                  )
                : ChangeNotifierProvider(
                    create: (_) => InspectionFullscreenVideoController(),
                    child: InspectionFullScreenVideo(
                      videoUrl: currentFile!.path,
                      label: "Video",
                    ),
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
            currentAngle = 0;
          }
          continue;
        }
        if (result is File) {
          if (mediaType == MediaType.image) {
            final compressed = await compressImage(result, angle: currentAngle);
            if (imageIndex >= 0 && imageIndex < _capturedImages.length) {
              await _deleteOldImage(_capturedImages[imageIndex], exceptFile: compressed);
              _capturedImages[imageIndex] = compressed;
            } else {
              _capturedImages.add(compressed);
            }
          } else {
            final compressedVideo = await compressVideo(result);
            await _deleteOldVideo(_capturedVideo, exceptFile: compressedVideo);
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

  Future<void> _deleteOldImage(File? file, {File? exceptFile}) async {
    try {
      if (file != null && await file.exists()) {
        if (exceptFile != null && file.path == exceptFile.path) {
          return;
        }
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _deleteOldVideo(File? file, {File? exceptFile}) async {
    try {
      if (file != null && await file.exists()) {
        if (exceptFile != null && file.path == exceptFile.path) {
          return;
        }
        await file.delete();
      }
    } catch (_) {}
  }

  Future<File> compressImage(File file, {int angle = 0}) async {
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
          rotate: angle,
          autoCorrectionAngle: true,
          keepExif: false,
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
    }
  }

    String get currentStageKey {
    final item = currentItem;
    final itemIdStr = item != null ? item['id']?.toString() : currentStep.toString();
    switch (currentStage) {
      case InspectionStage.internalImages:
        return 'internal_images_$itemIdStr';
      case InspectionStage.internal360:
        return 'internal_360';
      case InspectionStage.externalImages:
        return 'external_images_$itemIdStr';
      case InspectionStage.additionalImages:
        return 'additional_images_$currentStep';
      case InspectionStage.external360:
        return 'external_360';
      case InspectionStage.diagram:
        return 'diagram';
      case InspectionStage.signature:
        return 'signature';
      case InspectionStage.completed:
        return 'completed';
    }
  }

  Future<void> _persistCurrentDraftMedia() async {
    await LocalUploadStorageService.saveDraftMedia(
      jobId: jobId,
      stageKey: currentStageKey,
      images: _capturedImages,
      video: _capturedVideo,
    );
  }

  Future<void> loadDraftMediaForCurrentStep() async {
    final draft = await LocalUploadStorageService.getDraftMedia(
      jobId: jobId,
      stageKey: currentStageKey,
    );
    if (draft != null) {
      final List<File?> draftImages = List<File?>.from(draft['images'] ?? []);
      final File? draftVideo = draft['video'];

      if (draftImages.isNotEmpty) {
        for (int i = 0; i < _capturedImages.length && i < draftImages.length; i++) {
          if (draftImages[i] != null && await draftImages[i]!.exists()) {
            _capturedImages[i] = draftImages[i];
          }
        }
      }
      if (draftVideo != null && await draftVideo.exists()) {
        _capturedVideo = draftVideo;
      }

      bool foundEmpty = false;
      for (int i = 0; i < _capturedImages.length; i++) {
        if (_capturedImages[i] == null) {
          selectedBoxIndex = i;
          foundEmpty = true;
          break;
        }
      }
      if (!foundEmpty && hasVideoRequirement) {
        isVideoModeSelected = true;
      }
      notifyListeners();
    }
  }

  Future<void> getBasicimageList() async {
    isLoading = true;
    notifyListeners();
    await getBasicInspection(jobId);
    // Load persisted Quick Inspection stage so _calculateResumeStep can override
    // the API-computed stage when the persisted stage is further ahead in the flow.
    if (isQuick) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _persistedQuickStage = prefs.getString('quick_stage_$jobId');
      } catch (_) {
        _persistedQuickStage = null;
      }
    }
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
        await getBasicInspection(jobId);
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
          'isMandatory': images[i]['imageMandatory'] ?? false,
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
      if (lastcompleteId != null && id == lastcompleteId) {
        isCompleted = true;
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
    // Apply persisted stage override AFTER computing from completedImageIds.
    // This handles cases where the server API imageMasterId fields don't match
    // the quickImageSettingsMobile image IDs, causing incorrect stage calculation.
    if (isQuick && _persistedQuickStage != null) {
      _applyPersistedStageOverride();
    }
    isResumeLoaded = true;
    notifyListeners();
  }

  Map<String, dynamic>? get currentItem {
    if (currentStage != InspectionStage.internalImages &&
        currentStage != InspectionStage.externalImages) {
      return null;
    }
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
    final item = currentItem;
    if (item != null && item['imageMandatory'] != null) {
      return item['imageMandatory'] == true;
    }
    return false;
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

  int selectedBoxIndex = 0;
  bool isVideoModeSelected = false;

  void selectBoxIndex(int index) {
    selectedBoxIndex = index;
    isVideoModeSelected = false;
    notifyListeners();
  }

  void selectVideoMode() {
    isVideoModeSelected = true;
    notifyListeners();
  }

  bool get hasVideoRequirement {
    if (is360Stage) return true;
    final item = currentItem;
    return item?['videoFlag'] ?? false;
  }

  bool get isMaxImagesCaptured {
    if (_capturedImages.isEmpty) return false;
    return _capturedImages.every((img) => img != null);
  }

  Future<void> updateCapturedImage(int index, File file, {int angle = 0}) async {
    final compressed = await compressImage(file, angle: angle);
    if (_capturedImages.isEmpty) {
      _capturedImages.add(compressed);
    } else if (index >= 0 && index < _capturedImages.length) {
      await _deleteOldImage(_capturedImages[index]);
      _capturedImages[index] = compressed;
    } else if (_capturedImages.length < 3) {
      _capturedImages.add(compressed);
    } else {
      _capturedImages[0] = compressed;
    }
    // Auto-advance to next uncaptured image box if available
    bool foundEmpty = false;
    for (int i = 0; i < _capturedImages.length; i++) {
      if (_capturedImages[i] == null) {
        selectedBoxIndex = i;
        foundEmpty = true;
        break;
      }
    }
    // If all required images are captured, automatically transition to Video mode
    if (!foundEmpty && hasVideoRequirement) {
      isVideoModeSelected = true;
    }
    notifyListeners();
    _persistCurrentDraftMedia();
  }

  Future<void> removeCapturedImage(int index) async {
    if (index >= 0 && index < _capturedImages.length) {
      await _deleteOldImage(_capturedImages[index]);
      _capturedImages[index] = null;
      selectedBoxIndex = index;
      isVideoModeSelected = false;
      notifyListeners();
      _persistCurrentDraftMedia();
    }
  }

  Future<void> removeCapturedVideo() async {
    await _deleteOldVideo(_capturedVideo);
    _capturedVideo = null;
    isVideoModeSelected = true;
    notifyListeners();
    _persistCurrentDraftMedia();
  }

  Future<void> updateCapturedVideo(File videoFile) async {
    try {
      await _deleteOldVideo(_capturedVideo);
      _capturedVideo = videoFile;
    } catch (e) {
    } finally {
      isVideoLoading = false;
      notifyListeners();
      _persistCurrentDraftMedia();
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
    if (imageCount > 3) {
      imageCount = 3;
    }
    if (reset || _capturedImages.length != imageCount) {
      _capturedImages = List<File?>.generate(imageCount, (_) => null, growable: true);
      capturedStatus = List.generate(imageCount, (_) => false, growable: true);
    }
    _capturedVideo = null;
    selectedBoxIndex = 0;
    isVideoModeSelected = is360Stage;
    showValidation = false;
    notifyListeners();
    loadDraftMediaForCurrentStep();
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
        if (isQuick) _persistQuickStage('360Video');
        notifyListeners();
        return;
      }
      currentStage = InspectionStage.diagram;
      // All additional images saved; Car Diagram is now the pending stage.
      if (isQuick) _persistQuickStage('carDiagram');
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
            _persistQuickStage('additionalImages');
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
          if (isQuick) _persistQuickStage('360Video');
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

  void _moveToNextStage(BuildContext context) async {
    if (currentStage == InspectionStage.internalImages) {
      currentStage = InspectionStage.internal360;
      currentImages = [];
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
          _persistQuickStage('additionalImages');
          notifyListeners();
          return;
        }
      }
      currentStage = InspectionStage.external360;
      currentImages = [];
      _capturedVideo = null;
      if (isQuick) _persistQuickStage('360Video');
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
        if (isQuick) _persistQuickStage('360Video');
        notifyListeners();
        return;
      }
      currentStage = InspectionStage.diagram;
      if (isQuick) _persistQuickStage('carDiagram');
      notifyListeners();
      openCarDiagram(context);
      return;
    }
    if (currentStage == InspectionStage.external360) {
      currentStage = InspectionStage.diagram;
      // 360° Video successfully saved; Car Diagram is now the pending stage.
      if (isQuick) _persistQuickStage('carDiagram');
      notifyListeners();
      openCarDiagram(context);
      return;
    }
    if (currentStage == InspectionStage.diagram) {
      if (isQuick) {
        currentStage = InspectionStage.completed;
        // Car Diagram saved via this path; Quick Inspection Summary is now pending.
        await _persistQuickStage('summary');
        if (context.mounted) {
          context.go('/quickInspectionSummary', extra: jobId);
        }
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
    if (currentStage == InspectionStage.internal360) {
      completedImageIds.add(-20);
      await LocalUploadStorageService.saveSkippedImageId(jobId, -20);
    } else if (currentStage == InspectionStage.external360) {
      completedImageIds.add(-10);
      await LocalUploadStorageService.saveSkippedImageId(jobId, -10);
    } else if (currentStage == InspectionStage.additionalImages) {
      completedImageIds.add(-100 - currentStep);
      await LocalUploadStorageService.saveSkippedImageId(jobId, -100 - currentStep);
    } else if (currentItem != null) {
      final int skippedId = currentItem!['id'];
      completedImageIds.add(skippedId);
      await LocalUploadStorageService.saveSkippedImageId(jobId, skippedId);
    }
    await LocalUploadStorageService.clearDraftMedia(jobId: jobId, stageKey: currentStageKey);
    // When skipping on additionalImages, jump directly to external360
    // (or diagram if no 360 configured), bypassing remaining additional images.
    if (context.mounted) {
      if (currentStage == InspectionStage.additionalImages) {
        _moveToNextStage(context);
      } else {
        _moveToNextIncompleteImage(context);
      }
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
      if (isQuick) {
        currentStage = InspectionStage.completed;
        // Car Diagram successfully saved; Quick Inspection Summary is now pending.
        // Persist BEFORE navigating so reopen always lands on Summary.
        await _persistQuickStage('summary');
        if (context.mounted) {
          context.go('/quickInspectionSummary', extra: jobId);
        }
      } else {
        if (context.mounted) {
          notifyListeners();
          openSignature(context);
        }
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
    if (isUploading || isVideoLoading) return false;
    final item = currentItem;
    final bool hasNewMedia = is360Stage 
        ? (_capturedVideo != null) 
        : (_capturedImages.any((img) => img != null) || _capturedVideo != null);
    if (isCurrentStageCompleted && !hasNewMedia && status != 3) {
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

    isUploading = true;
    lastErrorMessage = "";
    notifyListeners();
    String imageId = "";
    List<Map<String, dynamic>> mediaItems = [];
    try {
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
        "stage": currentStageKey,
      };

      await LocalUploadStorageService.enqueueOfflineTask(
        jobId: jobId,
        endpointUrl: ApiServices.basicInspection,
        mediaItems: queueMediaItems,
        fields: fields,
      );

      if (!is360Stage && item != null) {
        completedImageIds.add(item['id']);
      }
      if (currentStage == InspectionStage.additionalImages) {
        completedImageIds.add(-100 - currentStep);
      }
      if (currentStage == InspectionStage.external360) {
        completedImageIds.add(-10);
        if (isQuick) _persistQuickStage('carDiagram');
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

      await LocalUploadStorageService.clearDraftMedia(jobId: jobId, stageKey: currentStageKey);
      await NetworkSyncManager().refreshPendingCount();
      if (status == 3) {
        await NetworkSyncManager().syncIfConnected();
      } else {
        unawaited(NetworkSyncManager().syncIfConnected());
      }

      print("💾 [BasicInspController] Saved inspection step to queue for job $jobId.");
      return true;
    } catch (err) {
      print("❌ [BasicInspController] Error saving task to queue: $err");
      lastErrorMessage = "Failed to save media locally. Please try again.";
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Inspection stage persistence helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Persists the current Quick Inspection pending stage to SharedPreferences.
  /// Called ONLY after a successful save/proceed operation — never on screen open.
  /// Key: 'quick_stage_{jobId}'   Values: 'carDiagram' | 'summary' | 'completed'
  Future<void> _persistQuickStage(String stage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quick_stage_$jobId', stage);
    } catch (e) {
    }
  }

  int _getQuickStageRank(dynamic stage) {
    if (stage is InspectionStage) {
      switch (stage) {
        case InspectionStage.externalImages:
          return 0;
        case InspectionStage.additionalImages:
          return 1;
        case InspectionStage.external360:
          return 2;
        case InspectionStage.diagram:
          return 3;
        case InspectionStage.completed:
          return 4;
        default:
          return 0;
      }
    } else if (stage is String) {
      switch (stage) {
        case 'quickImages':
          return 0;
        case 'additionalImages':
          return 1;
        case '360Video':
          return 2;
        case 'carDiagram':
          return 3;
        case 'summary':
        case 'completed':
          return 4;
        default:
          return 0;
      }
    }
    return 0;
  }

  /// Overrides the API-computed resume stage with the persisted Quick Inspection
  /// stage when the persisted stage is further ahead in the flow based on stage rank.
  void _applyPersistedStageOverride() {
    final persisted = _persistedQuickStage;
    if (persisted == null) return;

    final persistedRank = _getQuickStageRank(persisted);
    final apiRank = _getQuickStageRank(currentStage);

    bool shouldOverride = persistedRank > apiRank;
    if (!shouldOverride && persisted == '360Video' && !completedImageIds.contains(-10)) {
      shouldOverride = true;
    }
    if (shouldOverride) {
      if (persisted == 'summary' || persisted == 'completed') {
        currentStage = InspectionStage.completed;
        currentSectionData = null;
        currentImages = [];
        hasOpenedResumeStage = false;
      } else if (persisted == 'carDiagram') {
        currentStage = InspectionStage.diagram;
        currentSectionData = null;
        currentImages = [];
        hasOpenedResumeStage = false;
      } else if (persisted == '360Video') {
        currentStage = InspectionStage.external360;
        if (externalImageList.isNotEmpty) {
          currentSectionData = externalImageList.first;
        }
        currentImages = [];
        _capturedVideo = null;
        _initializeCaptureList();
      } else if (persisted == 'additionalImages') {
        currentStage = InspectionStage.additionalImages;
        if (externalImageList.isNotEmpty) {
          currentSectionData = externalImageList.first;
        }
        currentImages = [];
        _initializeCaptureList();
      }
    }
  }

  /// Public method called by QuickInspectionSummaryPage after a successful
  /// signature upload. Persists the fully-completed state so that a reopen
  /// still shows the Summary (not an earlier stage).
  Future<void> markQuickInspectionCompleted() async {
    await _persistQuickStage('completed');
  }

  /// Clears the persisted Quick Inspection stage for [jobId].
  /// Call this when the inspection is fully submitted and navigation leaves
  /// the inspection flow (e.g., going to job card details).
  static Future<void> clearQuickStage(int jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quick_stage_$jobId');
    } catch (e) {
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

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
      for (int k = 0; k < externalImages.length; k++) {
        var img = externalImages[k];
        int? masterId = img["imageMasterId"] ?? img["id"] ?? img["inspectionImageId"];
        List attachments = img["attachments"] ?? [];
        if (attachments.isNotEmpty) {
          if (masterId != null && masterId != 0) {
            completedImageIds.add(masterId);
          }
          if (externalImageList.isNotEmpty) {
            List settingImages = externalImageList.first['images'] ?? [];
            if (k < settingImages.length && settingImages[k]['id'] != null) {
              completedImageIds.add(settingImages[k]['id']);
            }
          }
        }
        for (var att in attachments) {
          int? attImageId = att["iaInspectionImageId"] ?? att["inspectionImageId"] ?? att["imageMasterId"];
          if (attImageId != null && attImageId != 0) {
            completedImageIds.add(attImageId);
          }
          if (att["iaType"] == 2 && (att["iaImageType"] == 10 || att["iaInspectionType"] == 0 || att["is360"] == true)) {
            completedImageIds.add(-10);
          }
        }
        allAttachments.addAll(attachments);
      }

      List internalImages = grouped["internalImages"] ?? [];
      for (int k = 0; k < internalImages.length; k++) {
        var img = internalImages[k];
        int? masterId = img["imageMasterId"] ?? img["id"] ?? img["inspectionImageId"];
        List attachments = img["attachments"] ?? [];
        if (attachments.isNotEmpty) {
          if (masterId != null && masterId != 0) {
            completedImageIds.add(masterId);
          }
          if (internalImageList.isNotEmpty) {
            List settingImages = internalImageList.first['images'] ?? [];
            if (k < settingImages.length && settingImages[k]['id'] != null) {
              completedImageIds.add(settingImages[k]['id']);
            }
          }
        }
        for (var att in attachments) {
          int? attImageId = att["iaInspectionImageId"] ?? att["inspectionImageId"] ?? att["imageMasterId"];
          if (attImageId != null && attImageId != 0) {
            completedImageIds.add(attImageId);
          }
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

      bool hasValidContent(dynamic section) {
        if (section == null) return false;
        if (section is List) {
          if (section.isEmpty) return false;
          for (var item in section) {
            if (item is Map) {
              if ((item["url"] != null && item["url"].toString().isNotEmpty) ||
                  (item["path"] != null && item["path"].toString().isNotEmpty) ||
                  (item["attachments"] is List && (item["attachments"] as List).isNotEmpty)) {
                return true;
              }
            } else if (item is String && item.isNotEmpty) {
              return true;
            }
          }
          return false;
        }
        if (section is Map) {
          return (section["url"] != null && section["url"].toString().isNotEmpty) ||
                 (section["path"] != null && section["path"].toString().isNotEmpty) ||
                 (section["imageUrl"] != null && section["imageUrl"].toString().isNotEmpty) ||
                 (section["signatureUrl"] != null && section["signatureUrl"].toString().isNotEmpty) ||
                 (section["attachments"] is List && (section["attachments"] as List).isNotEmpty);
        }
        if (section is String) {
          return section.isNotEmpty;
        }
        return false;
      }

      bool hasExternal360 = hasValidContent(grouped["external360"]) ||
                            hasValidContent(grouped["360"]) ||
                            hasValidContent(grouped["video360"]);
      if (!hasExternal360) {
        for (var att in allAttachments) {
          final isAtt360 = att["iaType"] == 2 && (att["iaImageType"] == 10 || att["is360"] == true || att["attachType"] == 10 || att["attachType"] == "10");
          if (isAtt360 && (att["iaInspectionType"] == 0 || isQuick)) {
            final hasUrl = (att["iaUrl"] != null && att["iaUrl"].toString().isNotEmpty) ||
                           (att["url"] != null && att["url"].toString().isNotEmpty);
            if (hasUrl) {
              hasExternal360 = true;
              break;
            }
          }
        }
      }
      if (hasExternal360) {
        completedImageIds.add(-10);
      }

      bool hasInternal360 = hasValidContent(grouped["internal360"]);
      if (!hasInternal360) {
        for (var att in allAttachments) {
          if (att["iaType"] == 2 && (att["iaImageType"] == 10 || att["is360"] == true) && att["iaInspectionType"] == 1) {
            final hasUrl = (att["iaUrl"] != null && att["iaUrl"].toString().isNotEmpty) ||
                           (att["url"] != null && att["url"].toString().isNotEmpty);
            if (hasUrl) {
              hasInternal360 = true;
              break;
            }
          }
        }
      }
      if (hasInternal360) {
        completedImageIds.add(-20);
      }

      if (hasValidContent(grouped["cardiagram"])) {
        completedImageIds.add(-30);
      }
      if (hasValidContent(grouped["signature"])) {
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
      }

      // Include skipped image IDs so skipped items are remembered offline
      try {
        final skippedIds = await LocalUploadStorageService.getSkippedImageIds(jobId);
        completedImageIds.addAll(skippedIds);
      } catch (err) {
      }

      isResumeLoaded = true;
    } catch (e) {
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
