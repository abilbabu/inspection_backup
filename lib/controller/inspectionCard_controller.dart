// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/inspectionFormController.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/model/inspectionTaskModel.dart';
import 'package:inspection/utils/constant/mediaCacheService%20.dart';
import 'package:inspection/view/global_widgets/cameraCaptureScreen.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_fullscreenvideo.dart';
import 'package:inspection/view/inspection_screen/widgets/fullscreen_image_screen.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_compress/video_compress.dart';

enum ValidationType { image, audio, condition, none }

enum MediaType { image, video }

enum SpeechField { note, description }

class InspectioncardController extends ChangeNotifier {
  String? _recordedFilePath;
  String? selectedOption;
  SpeechField? activeSpeechField;

  bool showSaveButton = true;
  bool isImageLoading = false;
  bool isLoading = false;
  bool isSuccess = false;
  bool isImageDownloading = false;
  bool isAudioDownloading = false;
  bool isVideoLoading = false;
  bool isRecording = false;
  bool isPlaying = false;
  bool isPaused = false;
  final record = AudioRecorder();
  final audioPlayer = AudioPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  static const int maxImages = 3;
  final List<File?> _capturedImages = List<File?>.filled(
    maxImages,
    null,
    growable: false,
  );
  List<File?> get capturedImages => _capturedImages;
  File? imageAt(int index) => _capturedImages[index];
  File? _capturedVideo;
  File? get capturedVideo => _capturedVideo;
  String? get recordedFilePath => _recordedFilePath;
  String? validationError;
  ValidationType validationType = ValidationType.none;
  final SpeechToText _speechToText = SpeechToText();
  bool speechEnabled = false;
  bool isListening = false;
  String _previousFinalText = "";
  Timer? silenceTimer;
  bool hasUnsavedChanges = false;

  final Map<int, int> _imageAngles = {};

  int getAngleAt(int index) {
    return _imageAngles[index] ?? 0;
  }

  void setAngleAt(int index, int angle) {
    _imageAngles[index] = angle;
    notifyListeners();
  }

  void markChanged() {
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void markSaved() {
    hasUnsavedChanges = false;
    notifyListeners();
  }

  Future<void> initSpeech() async {
    speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  Future<void> startListening(SpeechField field) async {
    if (!speechEnabled) return;
    if (isListening) {
      await stopListening();
    }
    _previousFinalText = "";
    await _speechToText.stop();
    await _speechToText.cancel();
    activeSpeechField = field;
    isListening = true;
    notifyListeners();
    await _speechToText.listen(
      onResult: onSpeechResult,
      listenMode: ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(minutes: 2),
      cancelOnError: true,
    );
  }

  void startSilenceTimer() {
    silenceTimer?.cancel();
    silenceTimer = Timer(const Duration(seconds: 2), () async {
      if (isListening) {
        await stopListening();
      }
    });
  }

  Future<void> stopListening() async {
    silenceTimer?.cancel();
    await _speechToText.stop();
    isListening = false;
    activeSpeechField = null;
    notifyListeners();
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    if (!isListening) return;
    startSilenceTimer();
    final currentText = result.recognizedWords.trim();
    if (result.finalResult) {
      if (currentText.startsWith(_previousFinalText)) {
        final newPart = currentText.substring(_previousFinalText.length).trim();
        if (newPart.isNotEmpty) {
          if (activeSpeechField == SpeechField.note) {
            noteController.text = ("${noteController.text} $newPart").trim();
          } else if (activeSpeechField == SpeechField.description) {
            descriptionController.text =
                ("${descriptionController.text} $newPart").trim();
          }
        }
      }
      _previousFinalText = currentText;
      notifyListeners();
    }
  }

  void setValidationError(String message, ValidationType type) {
    validationError = message;
    validationType = type;
    notifyListeners();
  }

  bool get isGood => selectedOption == "Good";
  bool get isRepair => selectedOption == "Repair";
  bool get isPoor => selectedOption == "Poor";
  bool get isReplace => selectedOption == "Replace";
  bool get isNotApplicable => selectedOption == "N/A";

  void setSelectedOption(String value) {
    selectedOption = value;
    showSaveButton = true;
    if (value == "N/A") {
      for (int i = 0; i < _capturedImages.length; i++) {
        _deleteOldImage(_capturedImages[i]);
        _capturedImages[i] = null;
      }
      _recordedFilePath = null;
      noteController.clear();
      validationType = ValidationType.none;
      validationError = null;
      stopAndResetAudio();
    }
    notifyListeners();
  }

  InspectioncardController() {
    _audioPlayer.onPlayerComplete.listen((event) {
      isPlaying = false;
      isPaused = false;
      notifyListeners();
    });
  }

  Future<void> togglePlayPause(String filePath) async {
    if (isPlaying) {
      await _audioPlayer.pause();
      isPlaying = false;
      isPaused = true;
    } else {
      if (isPaused) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(DeviceFileSource(filePath));
      }
      isPlaying = true;
      isPaused = false;
    }
    notifyListeners();
  }

  Future<void> stopAndResetAudio() async {
    await _audioPlayer.stop();
    isPlaying = false;
    isPaused = false;
    notifyListeners();
  }

  Future<void> toggleRecording() async {
    if (isNotApplicable || isSuccess) return;
    if (isRecording) {
      final path = await record.stop();
      if (path != null) {
        _recordedFilePath = path;
        isRecording = false;
        notifyListeners();
      }
    } else {
      if (await record.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
        await record.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
        isRecording = true;
        notifyListeners();
      }
    }
  }

  Future<void> playRecording() async {
    if (_recordedFilePath != null) {
      await audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  Future<void> deleteRecording() async {
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (await file.exists()) await file.delete();
      _recordedFilePath = null;
      notifyListeners();
    }
  }

  Future<void> handleImageTap(
    BuildContext context, {
    required int imageIndex,
    required MediaType mediaType,
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
            builder: (_) =>
                CameraCaptureScreen(isVideo: mediaType == MediaType.video),
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
                    angle: currentAngle, // Passing currentAngle here
                  )
                : InspectionFullScreenVideo(
                    videoUrl: currentFile!.path,
                    label: "Video",
                  ),
          ),
        );
        if (result == null) return;
        if (result == "recapture") {
          final dynamic newResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CameraCaptureScreen(isVideo: mediaType == MediaType.video),
            ),
          );
          if (newResult == null) return;
          if (newResult is Map) {
            currentFile = newResult['file'];
            currentAngle = newResult['angle'] ?? 0;
          } else if (newResult is File) {
            currentFile = newResult;
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

  Future<void> deleteVideo() async {
    await _deleteOldVideo(_capturedVideo);
    _capturedVideo = null;
    notifyListeners();
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
    final info = await VideoCompress.compressVideo(
      videoFile.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );
    if (info == null || info.file == null) {
      return videoFile;
    }
    return info.file!;
  }

  Future<void> loadExistingTask({
    required InspectionFormController formController,
    required int taskId,
    bool isReInspection = false,
  }) async {
    final existing = formController.getTaskById(taskId);
    if (existing == null) return;
    final bool alreadySaved = formController.isTaskSaved(taskId);
    if (isReInspection && !alreadySaved) {
      selectedOption = null;
      noteController.text = "";
      descriptionController.text = "";
      _capturedImages.fillRange(0, maxImages, null);
      _capturedVideo = null;
      _recordedFilePath = null;
      _imageAngles.clear();
    } else {
      selectedOption = existing.condition;
      noteController.text = existing.note;
      descriptionController.text = existing.description;
      if (existing.imageFiles != null && existing.imageFiles!.isNotEmpty) {
        for (
          int i = 0;
          i < existing.imageFiles!.length && i < _capturedImages.length;
          i++
        ) {
          _capturedImages[i] = existing.imageFiles![i];
        }
      } else if (existing.imageUrls != null && existing.imageUrls!.isNotEmpty) {
        isImageDownloading = true;
        notifyListeners();
        for (
          int i = 0;
          i < existing.imageUrls!.length && i < _capturedImages.length;
          i++
        ) {
          final file = await MediaCacheService.instance.getCachedFile(
            existing.imageUrls![i],
            CachedMediaType.image,
          );
          if (file != null) {
            _capturedImages[i] = file;
          }
        }
        isImageDownloading = false;
      }
      if (existing.videoFile != null) {
        _capturedVideo = existing.videoFile;
      } else if (existing.videoUrl != null) {
        isVideoLoading = true;
        notifyListeners();
        _capturedVideo = await MediaCacheService.instance.getCachedFile(
          existing.videoUrl!,
          CachedMediaType.video,
          onDownloadStart: () {
            isVideoLoading = true;
            notifyListeners();
          },
        );
        isVideoLoading = false;
        notifyListeners();
      }
      if (existing.audioFilePath != null) {
        _recordedFilePath = existing.audioFilePath;
      } else if (existing.audioUrl != null) {
        isAudioDownloading = true;
        notifyListeners();
        final audioFile = await MediaCacheService.instance.getCachedFile(
          existing.audioUrl!,
          CachedMediaType.audio,
          onDownloadStart: () {
            isAudioDownloading = true;
            notifyListeners();
          },
        );
        _recordedFilePath = audioFile?.path;
        isAudioDownloading = false;
        notifyListeners();
      }
    }
    if (formController.isTaskSaved(taskId)) {
      isSuccess = true;
      showSaveButton = false;
    }
    notifyListeners();
  }

  void updateParentTask({
    required InspectionFormController formController,
    required int categoryId,
    required int jobId,
    required int taskId,
    required int formId,
  }) {
    formController.updateTask(
      InspectionTaskData(
        categoryId: categoryId,
        jobId: jobId,
        taskId: taskId,
        formId: formId,
        condition: selectedOption,
        note: noteController.text,
        description: descriptionController.text,
        imageFiles: _capturedImages.whereType<File>().toList(),
        videoFile: _capturedVideo,
        audioFilePath: _recordedFilePath,
        inserted: false,
      ),
    );
  }

  Future<bool> onSavePressed({
    required BuildContext context,
    required InspectionFormController formController,
    required bool inspectionPhotoMandatory,
    required bool inspectionAudioMandatory,
    required int jobId,
    required int taskId,
    required int formId,
    required int categoryId,
    int? inspectionTypeId,
    bool isReInspection = false,
  }) async {
    validationError = null;
    validationType = ValidationType.none;
    if (isLoading) return false;
    if (selectedOption == null) {
      setValidationError(
        "Please select inspection condition",
        ValidationType.condition,
      );
      _showSnackBar(context, validationError!);
      return false;
    }
    if (isNotApplicable) {
    } else {
      final hasAtLeastOneImage = _capturedImages.any((img) => img != null);
      if (inspectionPhotoMandatory && !hasAtLeastOneImage) {
        setValidationError(
          "Inspection photo is required",
          ValidationType.image,
        );
        _showSnackBar(context, validationError!);
        return false;
      }
      if (inspectionAudioMandatory && _recordedFilePath == null) {
        setValidationError(
          "Inspection audio recording is required",
          ValidationType.audio,
        );
        _showSnackBar(context, validationError!);
        return false;
      }
    }
    updateParentTask(
      formController: formController,
      categoryId: categoryId,
      jobId: jobId,
      taskId: taskId,
      formId: formId,
    );
    isLoading = true;
    notifyListeners();
    final willCompleteAll =
        (formController.savedTasks + 1) == formController.totalTasks;
    final int status = isReInspection ? 11 : 5;
    final ApiResponse response = await saveSingleInspectionTask(
      status: status,
      jobId: jobId,
      taskId: taskId,
      formId: formId,
      inspectionTypeId: inspectionTypeId,
      viReInspection: isReInspection,
      vimInspectionType: isReInspection ? 2 : (inspectionTypeId ?? 1),
    );
    if (response.success != true) {
      isLoading = false;
      markSaved();
      notifyListeners();
      return false;
    }
    isLoading = false;
    isSuccess = true;
    showSaveButton = false;
    markSaved();
    formController.markTaskSaved(taskId);
    notifyListeners();
    return false;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<ApiResponse> saveSingleInspectionTask({
    required int status,
    required int jobId,
    required int taskId,
    required int formId,
    int? inspectionTypeId,
    bool? viReInspection,
    String? vimAdditionalComments,
    int? vimInspectionType,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('userToken');
      if (token == null || token.isEmpty) {
        return ApiResponse(
          success: false,
          status: "Unauthorized",
          statusCode: 401,
        );
      }
      List<MultipartFile> imageMultiparts = [];
      MultipartFile? audioMultipart;
      MultipartFile? videoMultipart;
      for (int i = 0; i < _capturedImages.length; i++) {
        final File? imageFile = _capturedImages[i];
        if (imageFile != null && imageFile.existsSync()) {
          imageMultiparts.add(
            await MultipartFile.fromFile(
              imageFile.path,
              filename:
                  "inspection_image_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg",
            ),
          );
        }
      }
      if (_capturedVideo != null && _capturedVideo!.existsSync()) {
        videoMultipart = await MultipartFile.fromFile(
          _capturedVideo!.path,
          filename:
              "inspection_video_${DateTime.now().millisecondsSinceEpoch}.mp4",
        );
      }
      if (recordedFilePath != null && File(recordedFilePath!).existsSync()) {
        audioMultipart = await MultipartFile.fromFile(
          recordedFilePath!,
          filename: recordedFilePath!.split('/').last,
        );
      }
      Map<String, dynamic> payload = {
        "vimJobId": jobId,
        "vimIfMasterId": (formId == 0) ? null : formId,
        "viTaskId": taskId,
        "viGood": isGood,
        "viRepair": isRepair,
        "viPoor": isPoor,
        "viReplace": isReplace,
        "viNotApplicable": isNotApplicable,
        "viDescription": descriptionController.text,
        "viNote": noteController.text,
        "status": status,
        "inserted": false,
      };
      if (viReInspection != null) {
        payload["viReInspection"] = viReInspection;
      }
      if (vimAdditionalComments != null) {
        payload["vimAdditionalComments"] = vimAdditionalComments;
      }
      if (vimInspectionType != null) {
        payload["vimInspectionType"] = vimInspectionType;
      }
      MultipartFile dataPart = MultipartFile.fromString(
        jsonEncode(payload),
        contentType: DioMediaType.parse('application/json'),
      );
      FormData formData = FormData();
      formData.files.add(MapEntry("data", dataPart));
      for (final img in imageMultiparts) {
        formData.files.add(MapEntry("viimagefiles", img));
      }
      if (audioMultipart != null) {
        formData.files.add(MapEntry("viaudiofile", audioMultipart));
      }
      if (videoMultipart != null) {
        formData.files.add(MapEntry("vivideofile", videoMultipart));
      }
      Dio dio = Dio();
      dio.options.headers["Authorization"] = "Bearer $token";
      final response = await dio.post(
        ApiServices.inspectionSingleSave,
        data: formData,
        options: Options(validateStatus: (_) => true),
      );
      final decoded = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: decoded?['data'],
          status: decoded?['status'] ?? "Success",
          timeStamp: decoded?['timeStamp'],
          statusCode: decoded?['statusCode'] ?? 200,
        );
      }
      return ApiResponse(
        success: false,
        status: decoded?['status'] ?? "Failed",
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, status: "Unexpected Error");
    }
  }

  Future<Size> getImageSize(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }

  // void _customshowSnackBar(BuildContext context, String message) {
  //   final messenger = ScaffoldMessenger.of(
  //     Navigator.of(context, rootNavigator: true).context,
  //   );

  //   messenger
  //     ..hideCurrentSnackBar()
  //     ..showSnackBar(
  //       SnackBar(
  //         content: Text(message),
  //         backgroundColor: Colors.red,
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  // }

  void _showValidationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 12),
              const Text(
                "Validation Error",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> onCustomSavePressed({
    required BuildContext context,
    required InspectionFormController formController,
    required bool inspectionPhotoMandatory,
    required bool inspectionAudioMandatory,
    required int jobId,
    required int taskId,
    required int formId,
    int? inspectionTypeId,
    bool isReInspection = false,
  }) async {
    validationError = null;
    validationType = ValidationType.none;
    if (isLoading) return false;
    if (selectedOption == null) {
      setValidationError(
        "Please select inspection condition",
        ValidationType.condition,
      );

      _showValidationDialog(context, validationError!);
      return false;
    }
    final hasAtLeastOneImage = _capturedImages.any((img) => img != null);

    if (inspectionPhotoMandatory && !hasAtLeastOneImage) {
      setValidationError("Inspection photo is required", ValidationType.image);

      _showValidationDialog(context, validationError!);
      return false;
    }

    if (inspectionAudioMandatory && _recordedFilePath == null) {
      setValidationError(
        "Inspection audio recording is required",
        ValidationType.audio,
      );

      _showValidationDialog(context, validationError!);
      return false;
    }
    updateCustomTask(
      formController: formController,
      jobId: jobId,
      taskId: taskId,
      formId: formId,
    );
    isLoading = true;
    notifyListeners();
    final ApiResponse response = await saveSingleInspectionTask(
      status: isReInspection ? 11 : 5,
      jobId: jobId,
      taskId: taskId,
      formId: formId,
      inspectionTypeId: inspectionTypeId,
      viReInspection: isReInspection,
      vimInspectionType: isReInspection ? 2 : (inspectionTypeId ?? 2),
    );
    if (response.success != true) {
      isLoading = false;
      markSaved();
      notifyListeners();
      return false;
    }
    isLoading = false;
    isSuccess = true;
    showSaveButton = false;
    markSaved();
    formController.markTaskSaved(taskId);
    notifyListeners();
    return false;
  }

  void updateCustomTask({
    required InspectionFormController formController,
    required int jobId,
    required int taskId,
    required int formId,
  }) {
    formController.updateTask(
      InspectionTaskData(
        jobId: jobId,
        taskId: taskId,
        formId: formId,
        condition: selectedOption,
        note: noteController.text,
        description: descriptionController.text,
        imageFiles: _capturedImages.whereType<File>().toList(),
        videoFile: _capturedVideo,
        audioFilePath: _recordedFilePath,
        inserted: false,
      ),
    );
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
