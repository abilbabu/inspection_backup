// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:http/http.dart' as http;
// import 'package:inspection/apiServices/api_services.dart';
// import 'package:inspection/model/apiResponsModel.dart';
// import 'package:inspection/view/basicInspection_screen/widget/carDiagram_screen.dart';
// import 'package:inspection/view/basicInspection_screen/widget/signature_screen.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:video_compress/video_compress.dart';
// import 'package:video_player/video_player.dart';

// enum ResumeAction { none, openDiagram, openSignature }

// class BasicinspectionController with ChangeNotifier {
//   final int jobId;

//   BasicinspectionController({required this.jobId});

//   CameraController? cameraController;
//   bool isCameraInitialized = false;

//   VideoPlayerController? videoController;

//   int currentImage = 0;
//   bool isVideoMode = false;
//   bool isRecording = false;
//   bool videoConfirmed = false;

//   bool isUploading = false;
//   bool isCompleted = false;

//   File? imagePath;
//   File? videoPath;
//   String? carDiagramPath;
//   String? signaturePath;

//   final List<File> capturedImages = [];

//   final List<String> imageNames = [
//     "Front View",
//     "Right View",
//     "Back View",
//     "Left View",
//     "Top View",
//     "Additional Image 1",
//     "Additional Image 2",
//     "Additional Image 3",
//     "Additional Image 4",
//     "360° Vehicle Inspection Video",
//   ];

//   static const int maxVideoSeconds = 50;
//   bool showLastSecondWarning = false;

//   int remainingSeconds = maxVideoSeconds;
//   Timer? _recordingTimer;

//   String formatDuration(Duration d) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
//   }

//   String get currentImages =>
//       currentImage < imageNames.length ? imageNames[currentImage] : "";

//   bool get isAdditionalImageStep => currentImage >= 5 && currentImage <= 8;
//   bool get isVideoStep => currentImage == 9;
//   bool get isDiagramStep => currentImage == 10;
//   bool get isSignatureStep => currentImage == 11;

//   List<Map<String, dynamic>> images = [];
//   Map<String, dynamic>? video;
//   Map<String, dynamic>? diagram;
//   Map<String, dynamic>? signature;

//   ResumeAction resumeAction = ResumeAction.none;

//   Future<ApiResponse> getBasicInspection(int jobId) async {
//     notifyListeners();
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userToken = prefs.getString('userToken');
//       final response = await http.post(
//         Uri.parse(ApiServices.getBasicInspection),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $userToken",
//         },
//         body: jsonEncode({"jobId": jobId}),
//       );
//       final result = jsonDecode(response.body);
//       final data = result["data"];
//       if (data == null) {
//         return ApiResponse(success: false, status: "No data");
//       }
//       final List attachments = data["attachments"] ?? [];
//       images.clear();
//       video = null;
//       diagram = null;
//       signature = null;
//       for (final a in attachments) {
//         final type = a["imageType"];
//         final label = a["label"];
//         debugPrint("Attachment → type:$type label:$label");
//         if (type >= 1 && type <= 6) {
//           images.add(a);
//         } else if (type == 10) {
//           video = a;
//         } else if (type == 11) {
//           diagram = a;
//         } else if (type == 12) {
//           signature = a;
//         }
//       }
//       _resumeInspectionFlow();
//       return ApiResponse(
//         success: result["statusCode"] == 200,
//         statusCode: result['statusCode'],
//         timeStamp: result['timeStamp'],
//         status: result['status'],
//         data: result['data'],
//       );
//     } catch (e) {
//       return ApiResponse(success: false, status: "Unexpected Error");
//     } finally {
//       notifyListeners();
//     }
//   }

//   void _resumeInspectionFlow() {
//     final uploadedLabels = images
//         .map((e) => (e["label"] ?? "").toString())
//         .toSet();
//     for (int i = 0; i <= 4; i++) {
//       if (!uploadedLabels.contains(imageNames[i])) {
//         currentImage = i;
//         isVideoMode = false;
//         resumeAction = ResumeAction.none;
//         notifyListeners();
//         return;
//       }
//     }
//     if (diagram == null) {
//       resumeAction = ResumeAction.openDiagram;
//       notifyListeners();
//       return;
//     }
//     if (signature == null) {
//       resumeAction = ResumeAction.openSignature;
//       notifyListeners();
//       return;
//     }
//     final additionalCount = images
//         .where((e) => e["label"] == "Additional Image")
//         .length;
//     if (additionalCount < 4) {
//       currentImage = 5 + additionalCount;
//       isVideoMode = false;
//       resumeAction = ResumeAction.none;
//       notifyListeners();
//       return;
//     }
//     if (video == null) {
//       currentImage = 9;
//       isVideoMode = true;
//       resumeAction = ResumeAction.none;
//       notifyListeners();
//       return;
//     }
//     isCompleted = true;
//     resumeAction = ResumeAction.none;
//     notifyListeners();
//   }

//   Future<void> initCamera(List<CameraDescription> cameras) async {
//     if (cameraController != null) return;
//     cameraController = CameraController(
//       cameras.first,
//       ResolutionPreset.high,
//       enableAudio: true,
//     );
//     await cameraController!.initialize();
//     isCameraInitialized = true;
//     notifyListeners();
//   }

//   Future<void> stopCamera() async {
//     try {
//       _stopRecordingTimer();
//       videoController?.pause();
//       await videoController?.dispose();
//       videoController = null;
//       if (cameraController != null) {
//         await cameraController!.dispose();
//         cameraController = null;
//       }
//       isCameraInitialized = false;
//     } catch (_) {}
//   }

//   Future<File> compressImage(File file) async {
//     final dir = await getTemporaryDirectory();
//     final targetPath = path.join(
//       dir.path,
//       'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
//     );
//     final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
//       file.absolute.path,
//       targetPath,
//       quality: 60,
//       format: CompressFormat.jpeg,
//     );
//     return compressed == null ? file : File(compressed.path);
//   }

//   Future<void> captureImage() async {
//     if (cameraController == null ||
//         !cameraController!.value.isInitialized ||
//         cameraController!.value.isTakingPicture) {
//       return;
//     }
//     final XFile rawImage = await cameraController!.takePicture();
//     imagePath = await compressImage(File(rawImage.path));
//     notifyListeners();
//   }

//   void recaptureImage() {
//     imagePath = null;
//     notifyListeners();
//   }

//   Future<void> confirmImage() async {
//     if (imagePath == null) return;
//     await runWithLoader(() async {
//       final success = await uploadSingleAttachment(
//         file: imagePath!,
//         attachType: _attachTypeByIndex(currentImage),
//         label: imageNames[currentImage],
//         type: 0,
//         status: 2,
//         additionalComment: "",
//       );
//       if (success) {
//         capturedImages.add(imagePath!);
//         imagePath = null;
//         _nextStep();
//       }
//     });
//   }

//   void skipStep() {
//     if (!isAdditionalImageStep) return;
//     imagePath = null;
//     currentImage = 9;
//     isVideoMode = true;
//     notifyListeners();
//   }

//   Future<File?> compressVideo(String path) async {
//     try {
//       final media = await VideoCompress.compressVideo(
//         path,
//         quality: VideoQuality.LowQuality,
//         deleteOrigin: false,
//         includeAudio: false,
//       );
//       return media?.file;
//     } catch (_) {
//       return null;
//     }
//   }

//   Future<void> toggleVideoRecording() async {
//     if (cameraController == null || isUploading) return;
//     await runWithLoader(() async {
//       if (cameraController!.value.isRecordingVideo) {
//         _stopRecordingTimer();

//         final XFile file = await cameraController!.stopVideoRecording();

//         videoPath = await compressVideo(file.path) ?? File(file.path);

//         videoController?.dispose();
//         videoController = VideoPlayerController.file(videoPath!)
//           ..addListener(_videoListener);
//         await videoController!.initialize();
//         videoController!.setLooping(true);
//         isRecording = false;
//         videoConfirmed = false;
//         notifyListeners();
//       } else {
//         await cameraController!.prepareForVideoRecording();
//         await cameraController!.startVideoRecording();
//         isRecording = true;
//         _startRecordingTimer();

//         notifyListeners();
//       }
//     });
//   }

//   void videoPlayPause() {
//     if (videoController == null) return;

//     final vc = videoController!;

//     // ▶️ If video ended → restart
//     if (vc.value.position >= vc.value.duration) {
//       vc.seekTo(Duration.zero);
//       vc.play();
//     } else {
//       vc.value.isPlaying ? vc.pause() : vc.play();
//     }

//     notifyListeners();
//   }

//   void _videoListener() {
//     if (videoController == null) return;
//     final vc = videoController!;

//     if (!vc.value.isInitialized) return;

//     // ▶️ When video finishes, force UI refresh (icon changes)
//     if (vc.value.position >= vc.value.duration && !vc.value.isPlaying) {
//       notifyListeners();
//     }
//   }

//   void _startRecordingTimer() {
//     remainingSeconds = maxVideoSeconds;
//     showLastSecondWarning = false;
//     _recordingTimer?.cancel();

//     _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
//       remainingSeconds--;
//       notifyListeners();

//       // ⚠️ 1 SECOND WARNING
//       if (remainingSeconds == 1) {
//         showLastSecondWarning = true;
//         notifyListeners();
//         return;
//       }

//       // ⛔ STOP AT 0
//       if (remainingSeconds <= 0) {
//         timer.cancel();
//         await autoStopRecording();
//         return;
//       }

//       notifyListeners();
//     });
//   }

//   Future<void> stopRecording() async {
//     if (cameraController == null) return;
//     if (!cameraController!.value.isRecordingVideo) return;
//     if (isUploading) return;

//     isUploading = true;
//     notifyListeners();

//     try {
//       _stopRecordingTimer();
//       final XFile file = await cameraController!.stopVideoRecording();
//       videoPath = await compressVideo(file.path) ?? File(file.path);

//       videoController?.dispose();
//       videoController = VideoPlayerController.file(videoPath!)
//         ..addListener(_videoListener);

//       await videoController!.initialize();
//       videoController!.setLooping(true);

//       isRecording = false;
//       videoConfirmed = false;
//     } catch (e) {
//       debugPrint("❌ Stop recording error: $e");
//     } finally {
//       isUploading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> autoStopRecording() async {
//     if (isUploading || !isRecording) return;
//     isUploading = true;
//     notifyListeners();
//     if (cameraController == null || !cameraController!.value.isRecordingVideo)
//       return;

//     final XFile file = await cameraController!.stopVideoRecording();

//     videoPath = await compressVideo(file.path) ?? File(file.path);

//     videoController?.dispose();
//     videoController = VideoPlayerController.file(videoPath!)
//       ..addListener(_videoListener);
//     await videoController!.initialize();
//     videoController!.setLooping(true);

//     isRecording = false;
//     videoConfirmed = false;
//     isUploading = false;
//     notifyListeners();
//   }

//   void _stopRecordingTimer() {
//     _recordingTimer?.cancel();
//     _recordingTimer = null;
//     _recordingTimer = null;
//     showLastSecondWarning = false;
//   }

//   Future<void> confirmVideo(BuildContext context) async {
//     if (videoPath == null) return;
//     await runWithLoader(() async {
//       final success = await uploadSingleAttachment(
//         file: videoPath!,
//         attachType: 10,
//         label: imageNames[currentImage],
//         type: 2,
//         status: 2,
//         additionalComment: "",
//       );
//       if (!success) return;
//       videoController?.dispose();
//       videoController = null;
//       isRecording = false;
//       videoConfirmed = true;
//       isVideoMode = false;
//       currentImage = 11;
//       openCarDiagram(context);
//     });
//   }

//   void skipVideo(BuildContext context) {
//     _stopRecordingTimer();
//     videoController?.dispose();
//     videoController = null;
//     videoPath = null;
//     isRecording = false;
//     isVideoMode = false;
//     currentImage = 10;
//     notifyListeners();
//     openCarDiagram(context);
//   }

//   void openCarDiagram(BuildContext context) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChangeNotifierProvider.value(
//           value: this,
//           child: CardiagramScreen(jobId: jobId),
//         ),
//       ),
//     );
//     if (result != null) {
//       carDiagramPath = result;
//       notifyListeners();
//       openSignature(context);
//     }
//   }

//   void openSignature(BuildContext context) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChangeNotifierProvider.value(
//           value: this,
//           child: SignatureScreen(jobId: jobId),
//         ),
//       ),
//     );
//     if (result != null) {
//       signaturePath = result;
//       notifyListeners();
//     }
//   }

//   void _nextStep() {
//     if (currentImage < imageNames.length - 1) {
//       currentImage++;
//       isVideoMode = isVideoStep;
//       notifyListeners();
//     }
//   }

//   int _attachTypeByIndex(int index) {
//     if (index <= 4) return index + 1;
//     return 6;
//   }

//   Future<bool> uploadSingleAttachment({
//     required File file,
//     required int attachType,
//     required String label,
//     required int type,
//     required int status,
//     required String additionalComment,
//   }) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('userToken');
//       if (token == null || token.isEmpty) return false;
//       Dio dio = Dio()
//         ..options.headers = {
//           "Authorization": "Bearer $token",
//           "Accept": "application/json",
//         };
//       final formData = FormData.fromMap({
//         "job_id": jobId,
//         "attachType": attachType,
//         "type": type,
//         "file": await MultipartFile.fromFile(file.path),
//         "status": status,
//         "additionalComment": additionalComment,
//         "inspectionNote": "",
//         "inspectionImageId": "",
//       });
//       await dio.post(ApiServices.basicInspection, data: formData);
//       return true;
//     } catch (e) {
//       debugPrint("❌ Upload error: $e");
//       return false;
//     }
//   }

//   Future<void> runWithLoader(Future<void> Function() action) async {
//     if (isUploading) return;
//     isUploading = true;
//     notifyListeners();
//     try {
//       await action();
//     } finally {
//       isUploading = false;
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     stopCamera();
//     super.dispose();
//   }
// }
