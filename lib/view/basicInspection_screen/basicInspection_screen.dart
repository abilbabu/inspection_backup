// // ignore_for_file: use_build_context_synchronously

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:inspection/controller/basicInspection_controller.dart';
// import 'package:inspection/utils/constant/appTextStyle_constants.dart';
// import 'package:inspection/utils/constant/color_constants.dart';
// import 'package:inspection/view/global_widgets/customAppBar.dart';
// import 'package:inspection/view/global_widgets/customButtonWidget.dart';
// import 'package:provider/provider.dart';
// import 'package:video_player/video_player.dart';

// class BasicinspectionScreen extends StatefulWidget {
//   final int jobId;
//   const BasicinspectionScreen({super.key, required this.jobId});

//   @override
//   State<BasicinspectionScreen> createState() => _BasicinspectionScreenState();
// }

// class _BasicinspectionScreenState extends State<BasicinspectionScreen> {
//   late final BasicinspectionController _controller;
//   late final Future<List<CameraDescription>> _cameraFuture;

//   bool isLoading = false;
//   bool isSuccess = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = BasicinspectionController(jobId: widget.jobId);
//     _cameraFuture = availableCameras();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _controller.getBasicInspection(widget.jobId);
//       if (!mounted) return;
//       switch (_controller.resumeAction) {
//         case ResumeAction.openDiagram:
//           _controller.openCarDiagram(context);
//           break;
//         case ResumeAction.openSignature:
//           _controller.openSignature(context);
//           break;
//         case ResumeAction.none:
//           break;
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.stopCamera();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _controller,
//       child: PopScope(
//         canPop: false,
//         onPopInvoked: (_) async {
//           if (await _showExitConfirmation()) {
//             _controller.stopCamera();
//             context.go('/home');
//           }
//         },
//         child: Scaffold(
//           appBar: CustomAppBar(
//             title: "Basic Inspection",
//             onBackPress: () async {
//               if (await _showExitConfirmation()) {
//                 _controller.stopCamera();
//                 context.go('/home');
//               }
//             },
//           ),
//           body: FutureBuilder<List<CameraDescription>>(
//             future: _cameraFuture,
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (!_controller.isCameraInitialized) {
//                 _controller.initCamera(snapshot.data!);
//               }
//               return Consumer<BasicinspectionController>(
//                 builder: (context, controller, child) {
//                   if (!controller.isCameraInitialized ||
//                       controller.cameraController == null) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 25,
//                       horizontal: 12,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           controller.currentImages,
//                           style: ApptextstyleConstants.lightText(
//                             fontSize: 18,
//                             color: ColorConstants.blackColor,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Expanded(
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Container(
//                               width: double.infinity,
//                               decoration: BoxDecoration(
//                                 border: Border.all(
//                                   color: ColorConstants.syanColor,
//                                   width: 2.5,
//                                 ),
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: _previewWidget(controller),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         controller.isVideoMode
//                             ? _videoControls(context, controller)
//                             : _imageControls(context, controller),
//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _previewWidget(BasicinspectionController controller) {
//     if (controller.isVideoMode && controller.isRecording) {
//       return Stack(
//         children: [
//           CameraPreview(controller.cameraController!),

//           // ⏱️ COUNTDOWN TIMER
//           Positioned(
//             top: 12,
//             right: 12,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.65),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 controller.showLastSecondWarning
//                     ? "⚠️ Auto recording is in progress"
//                     : "00:${controller.remainingSeconds.toString().padLeft(2, '0')}",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     }

//     if (controller.isVideoMode && controller.videoPath != null) {
//       final vc = controller.videoController!;

//       return SizedBox(
//         width: double.infinity,
//         child: Stack(
//           alignment: Alignment.bottomCenter,
//           children: [
//             Positioned.fill(
//               child: FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: vc.value.size.width,
//                   height: vc.value.size.height,
//                   child: VideoPlayer(vc),
//                 ),
//               ),
//             ),

//             // ⏱️ VIDEO TIME (LIVE)
//             Positioned(
//               bottom: 12,
//               left: 12,
//               child: ValueListenableBuilder<VideoPlayerValue>(
//                 valueListenable: vc,
//                 builder: (context, value, child) {
//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 10,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       "${controller.formatDuration(value.position)} / "
//                       "${controller.formatDuration(value.duration)}",
//                       style: const TextStyle(color: Colors.white, fontSize: 12),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: ValueListenableBuilder<VideoPlayerValue>(
//                 valueListenable: vc,
//                 builder: (context, value, child) {
//                   final bool isEnded =
//                       value.position >= value.duration && !value.isPlaying;

//                   return GestureDetector(
//                     onTap: () {
//                       if (isEnded) {
//                         vc.seekTo(Duration.zero);
//                         vc.play();
//                       } else {
//                         value.isPlaying ? vc.pause() : vc.play();
//                       }
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: ColorConstants.buttonGradient,
//                       ),
//                       child: CircleAvatar(
//                         radius: 26,
//                         backgroundColor: Colors.transparent,
//                         child: Icon(
//                           value.isPlaying ? Icons.pause : Icons.play_arrow,
//                           size: 30,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//     if (controller.imagePath != null) {
//       return GestureDetector(
//         onTap: controller.recaptureImage,
//         child: Image.file(
//           controller.imagePath!,
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: double.infinity,
//         ),
//       );
//     }
//     return CameraPreview(controller.cameraController!);
//   }

//   Widget _imageControls(
//     BuildContext context,
//     BasicinspectionController controller,
//   ) {
//     if (controller.imagePath != null) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Tap image to re-capture*",
//             style: ApptextstyleConstants.lightText(
//               fontSize: 12,
//               color: ColorConstants.errorcolor,
//             ),
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             width: double.infinity,
//             child: CustomButtonWidget(
//               text: "DONE",
//               textSize: 16,
//               icon: Icons.check,
//               isDisabled: controller.isUploading,
//               showLoader: controller.isUploading,
//               onPressed: controller.confirmImage,
//             ),
//           ),
//         ],
//       );
//     }
//     return Row(
//       children: [
//         Expanded(
//           child: CustomButtonWidget(
//             text: controller.isUploading ? "Please wait..." : "CAPTURE IMAGE",
//             textSize: 16,
//             icon: Icons.camera_alt,
//             isDisabled: controller.isUploading,
//             showLoader: controller.isUploading,
//             onPressed: controller.captureImage,
//           ),
//         ),
//         if (controller.isAdditionalImageStep) const SizedBox(width: 10),
//         if (controller.isAdditionalImageStep)
//           Expanded(
//             child: CustomButtonTwo(
//               text: "SKIP",
//               onPressed: controller.skipStep,
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _videoControls(
//     BuildContext context,
//     BasicinspectionController controller,
//   ) {
//     if (controller.videoPath != null && !controller.videoConfirmed) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Tap video to re-record*",
//             style: ApptextstyleConstants.lightText(
//               fontSize: 12,
//               color: ColorConstants.errorcolor,
//             ),
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             width: double.infinity,
//             child: CustomButtonWidget(
//               text: "DONE",
//               textSize: 16,
//               icon: Icons.check,
//               isDisabled: controller.isUploading,
//               showLoader: controller.isUploading,
//               onPressed: () => controller.confirmVideo(context),
//             ),
//           ),
//         ],
//       );
//     }
//     return Row(
//       children: [
//         Expanded(
//           child: CustomButtonWidget(
//             text: controller.isRecording ? "STOP RECORDING" : "START RECORDING",
//             // text: controller.isRecording ? "STOP" : "START",
//             textSize: 14,
//             icon: controller.isRecording ? Icons.stop : Icons.videocam,
//             isDisabled: controller.isUploading,
//             showLoader: controller.isUploading,
//             onPressed: controller.isUploading
//                 ? null
//                 : controller.isRecording
//                 ? controller.stopRecording
//                 : controller.toggleVideoRecording,
//           ),
//         ),
//         const SizedBox(width: 10),
//         if (controller.isVideoStep)
//           Expanded(
//             child: CustomButtonTwo(
//               text: "SKIP",
//               isDisabled: controller.isRecording,
//               onPressed: controller.isRecording
//                   ? null
//                   : () => controller.skipVideo(context),
//             ),
//           ),
//       ],
//     );
//   }

//   Future<bool> _showExitConfirmation() async {
//     return await showDialog<bool>(
//           context: context,
//           barrierDismissible: false,
//           builder: (_) => AlertDialog(
//             title: const Text("Discard changes?"),
//             content: const Text(
//               "Unsaved changes will be cleared. Are you sure you want to go back?",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context, false),
//                 child: const Text("NO"),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text("YES"),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }
// }
