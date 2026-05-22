import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/view/global_widgets/cameraCaptureScreen.dart';
import 'package:inspection/view/inspection_screen/widgets/fullscreen_image_screen.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VehicleessentialController extends ChangeNotifier {
  bool isLoading = false;
  Map<int, bool> selectedCheckBox = {};
  Map<int, String> checkBoxType = {};
  String notes = '';

  final Map<int, String> documentTypes = {
    0: "Soft Copy",
    1: "Hard Copy",
    2: "N/A",
  };

  int? selectedDocumentTypeId;

  final SpeechToText _speechToText = SpeechToText();

  bool speechEnabled = false;
  bool isListening = false;
  bool showListeningUI = false;

  Timer? silenceTimer;

  TextEditingController notesController = TextEditingController();

  bool isImageLoading = false;

  List<File?> _capturedImages = List.generate(1, (_) => null);

  File? imageAt(int index) {
    return _capturedImages[index];
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

  Future<void> getvehicleEssentialList({String? defaultValue}) async {
    final url = Uri.parse(ApiServices.getvehicleEssentialList);
    isLoading = true;
    notifyListeners();
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
        final List list = res["data"];
        checkBoxType.clear();
        selectedCheckBox.clear();
        for (final item in list) {
          final int id = item["veId"];
          final String name = item["veName"];
          checkBoxType[id] = name;
          selectedCheckBox[id] = false;
        }
      }
    } catch (e) {
      print("Vehicle essential error: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  void toggleCheckbox(int id) {
    selectedCheckBox[id] = !(selectedCheckBox[id] ?? false);
    notifyListeners();
  }

  List<int> getSelectedIds() {
    return selectedCheckBox.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  void setDocumentType(int id) {
    selectedDocumentTypeId = id;
    notifyListeners();
  }

  Future<void> handleImageTap(
    BuildContext context, {
    required int imageIndex,
  }) async {
    if (isImageLoading) return;
    isImageLoading = true;
    notifyListeners();
    try {
      File? currentFile = _capturedImages[imageIndex];
      int currentAngle = 0;
      if (currentFile == null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CameraCaptureScreen(isVideo: false),
          ),
        );
        if (result == null || result is! Map) return;
        currentFile = result['file'];
        currentAngle = result['angle'];
      }
      while (true) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageScreen(
              imageFile: currentFile!,
              angle: currentAngle, // Pass angle to the screen
            ),
          ),
        );
        if (result == null) return;
        if (result == "recapture") {
          final captureResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CameraCaptureScreen(isVideo: false),
            ),
          );
          if (captureResult == null) return;
          currentFile = captureResult['file'];
          currentAngle = captureResult['angle'];
          continue;
        }
        if (result is File) {
          final compressed = await compressImage(result);
          await _deleteOldImage(_capturedImages[imageIndex]);
          _capturedImages[imageIndex] = compressed;
          notifyListeners();
          return;
        }
      }
    } finally {
      isImageLoading = false;
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
        );
    if (compressedXFile == null) return file;
    return File(compressedXFile.path);
  }

  Future<bool> submitVehicleEssential({
    required int jobId,
    required int vId,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      Dio dio = Dio();
      final essentinalImage = _capturedImages[0];
      Map<String, dynamic> payload = {
        "jobId": jobId,
        "vId": vId,
        "type": 0,
        "note": notes,
        "docType": selectedDocumentTypeId,
        "status": 2,
        "veId": getSelectedIds(),
      };
      FormData formData = FormData.fromMap({
        "payload": MultipartFile.fromString(
          jsonEncode(payload),
          contentType: DioMediaType.parse("application/json"),
        ),
        if (essentinalImage != null)
          "essentinalImage": await MultipartFile.fromFile(
            essentinalImage.path,
            filename: essentinalImage.path.split('/').last,
          ),
      });
      final response = await dio.post(
        ApiServices.submitVehicleEssential,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $userToken",
            "Content-Type": "multipart/form-data",
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    isLoading = false;
    selectedCheckBox.clear();
    checkBoxType.clear();
    notes = '';
    notesController.clear();
    selectedDocumentTypeId = null;
    _capturedImages[0] = null;
    silenceTimer?.cancel();
    _speechToText.stop();
    isListening = false;
    showListeningUI = false;
    notifyListeners();
  }
}
