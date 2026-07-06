import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/view/inspection_screen/inspection_summary_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class InspectionsummarypageController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, List<InspectionItem>> groupedItems = {};
  int? vimInspectionTypeId;
  int? vimIfMasterId;
  String inspectionFormName = "";
  bool isInspectionAssigned = false;
  bool isPredefinedInspectionAssigned = false;
  bool isCustomInspectionAssigned = false;
  String technicianComment = "";
  String previousTechnicianComment = "";
  String supervisorComment = "";
  String previousSupervisorComment = "";
  String saComment = "";
  String previousSaComment = "";
  bool hasReinspection = false;
  int jobStatus = 0;

  final SpeechToText _speechToText = SpeechToText();

  bool speechEnabled = false;
  bool isListening = false;
  Timer? silenceTimer;

  String _baseText = "";
  String _currentSpeech = "";

  TextEditingController? _speechController;

  Future<void> initSpeech() async {
    speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  void startSilenceTimer() {
    silenceTimer?.cancel();

    silenceTimer = Timer(const Duration(seconds: 2), () async {
      if (isListening) {
        await stopListening();
      }
    });
  }

  Future<void> startListening({
    required TextEditingController controller,
  }) async {
    if (!speechEnabled) {
      speechEnabled = await _speechToText.initialize();
    }

    if (!speechEnabled) return;

    _speechController = controller;

    // Save existing note
    _baseText = controller.text.trim();

    _currentSpeech = "";

    isListening = true;
    notifyListeners();

    await _speechToText.listen(
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      onResult: onSpeechResult,
    );
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    if (_speechController == null) return;

    _currentSpeech = result.recognizedWords.trim();

    // Show live text while speaking
    if (_baseText.isEmpty) {
      _speechController!.text = _currentSpeech;
    } else {
      _speechController!.text = "$_baseText $_currentSpeech";
    }

    _speechController!.selection = TextSelection.fromPosition(
      TextPosition(offset: _speechController!.text.length),
    );

    // Stop when speech is finished
    if (result.finalResult) {
      stopListening();
    }

    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();

    isListening = false;

    // Save the final text so the next recording appends after it
    _baseText = _speechController?.text.trim() ?? "";

    notifyListeners();
  }

  @override
  void dispose() {
    silenceTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  Future<ApiResponse> getInspectionSummary(int jobId) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse(ApiServices.getInspectionSummary),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"jobId": jobId}),
      );
      final result = jsonDecode(response.body);
      groupedItems.clear();
      inspectionFormName = "";
      isInspectionAssigned = false;
      isPredefinedInspectionAssigned = false;
      isCustomInspectionAssigned = false;
      technicianComment = "";
      previousTechnicianComment = "";
      supervisorComment = "";
      previousSupervisorComment = "";
      saComment = "";
      previousSaComment = "";
      jobStatus = 0;
      final inspections = List.from(
        result["data"]["inspections"] as List? ?? [],
      );
      hasReinspection = inspections.any((insp) =>
          insp["master"]?["vimInspectionType"] == 2 ||
          insp["master"]?["vimInspectionType"]?.toString() == "2");
      for (int i = 0; i < inspections.length; i++) {
        final insp = inspections[i];
        final _ = insp["master"] ?? {};
        final _ = insp["inspectionTasks"] as List? ?? [];
      }
      inspections.sort((a, b) {
        final aVal = a["master"]?["vimId"];
        final bVal = b["master"]?["vimId"];
        final aId = aVal is num ? aVal.toInt() : int.tryParse(aVal?.toString() ?? "") ?? 0;
        final bId = bVal is num ? bVal.toInt() : int.tryParse(bVal?.toString() ?? "") ?? 0;
        return aId.compareTo(bId);
      });
      final jobCard = result["data"]["jobCard"] ?? {};
      jobStatus = int.tryParse(jobCard["jobStatus"]?.toString() ?? "") ?? 0;
      final attachments =
          jobCard["attachments"] as List? ?? [];
      final Map<int, Map<int, List<String>>> imageMap = {};
      final Map<int, Map<int, String>> videoMap = {};
      final Map<int, Map<int, String>> audioMap = {};
      for (final att in attachments) {
        final taskId = att["iaInspectionTaskId"];
        final inspectionId = att["iaInspectionId"];
        if (taskId == null || inspectionId == null) continue;
        
        final int taskInt = taskId is num ? taskId.toInt() : int.tryParse(taskId.toString()) ?? 0;
        final int inspInt = inspectionId is num ? inspectionId.toInt() : int.tryParse(inspectionId.toString()) ?? 0;
        
        final rawType = att["iaType"] ?? att["type"];
        final int type = rawType is num
            ? rawType.toInt()
            : int.tryParse(rawType?.toString() ?? "") ?? 0;
        final String currentUrl = (att["iaUrl"] ?? att["url"])?.toString() ?? "";
        if (currentUrl.isEmpty) continue;

        if (type == 0) {
          final list = imageMap
              .putIfAbsent(inspInt, () => {})
              .putIfAbsent(taskInt, () => []);
          if (!list.contains(currentUrl)) {
            list.add(currentUrl);
          }
        }
        if (type == 1) {
          audioMap.putIfAbsent(inspInt, () => {})[taskInt] = currentUrl;
        }
        if (type == 2) {
          videoMap.putIfAbsent(inspInt, () => {})[taskInt] = currentUrl;
        }
      }

      for (final inspection in inspections) {
        final master = inspection["master"] ?? {};
        final int vimId = master["vimId"] is num
            ? (master["vimId"] as num).toInt()
            : int.tryParse(master["vimId"]?.toString() ?? "") ?? 0;
        if (vimId == 0) continue;

        final categories = inspection["inspectionTasks"] as List? ?? [];
        for (final category in categories) {
          final categoryTasks = category["tasks"] as List? ?? [];
          for (final task in categoryTasks) {
            final taskId = task["viTaskId"];
            if (taskId == null) continue;
            final int taskInt = taskId is num
                ? taskId.toInt()
                : int.tryParse(taskId.toString()) ?? 0;
            if (taskInt == 0) continue;

            final taskAttachments = task["attachments"] as List? ?? [];
            for (final att in taskAttachments) {
              final rawType = att["iaType"] ?? att["type"];
              final int type = rawType is num
                  ? rawType.toInt()
                  : int.tryParse(rawType?.toString() ?? "") ?? 0;
              final String currentUrl = (att["iaUrl"] ?? att["url"])?.toString() ?? "";
              if (currentUrl.isEmpty) continue;

              if (type == 0) {
                final list = imageMap
                    .putIfAbsent(vimId, () => {})
                    .putIfAbsent(taskInt, () => []);
                if (!list.contains(currentUrl)) {
                  list.add(currentUrl);
                }
              } else if (type == 1) {
                audioMap.putIfAbsent(vimId, () => {})[taskInt] = currentUrl;
              } else if (type == 2) {
                videoMap.putIfAbsent(vimId, () => {})[taskInt] = currentUrl;
              }
            }
          }
        }
      }
      if (inspections.length > 1) {
        isInspectionAssigned = true;
        final assignedInspection = inspections[1];
        final master = assignedInspection["master"];
        if (master["vimIfMasterId"] == null) {
          isCustomInspectionAssigned = true;
          isInspectionAssigned = true;
        } else {
          isPredefinedInspectionAssigned = true;
          isInspectionAssigned = true;
        }
      }
      final Map<String, Map<String, InspectionItem>> categoryTaskMap = {};
      for (int i = 0; i < inspections.length; i++) {
        final inspection = inspections[i];
        final master = inspection["master"];
        if (master == null) continue;
        final int vimId = master["vimId"] is num ? (master["vimId"] as num).toInt() : int.tryParse(master["vimId"].toString()) ?? 0;
        final int? inspType = master["vimInspectionType"] is num
            ? (master["vimInspectionType"] as num).toInt()
            : int.tryParse(master["vimInspectionType"]?.toString() ?? "");
        final int? ifMasterId = master["vimIfMasterId"];
        final tasks = inspection["inspectionTasks"] as List? ?? [];
        vimInspectionTypeId = inspType;
        vimIfMasterId = ifMasterId;
        final String techComm =
            master["vimAdditionalComments"]?.toString() ?? "";
        final String supComm = master["vimSupervisorComment"]?.toString() ?? "";
        final String serviceComm = master["vimSaComment"]?.toString() ?? "";

        final bool isCustom = ifMasterId == null || ifMasterId == 0;
        final bool isReinspectionRun = inspType == 2;

        if (isReinspectionRun) {
          technicianComment = techComm;
          supervisorComment = supComm;
          saComment = serviceComm;
        } else {
          previousTechnicianComment = techComm;
          if (technicianComment.isEmpty) {
            technicianComment = techComm;
          }
          previousSupervisorComment = supComm;
          if (supervisorComment.isEmpty) {
            supervisorComment = supComm;
          }
          previousSaComment = serviceComm;
          if (saComment.isEmpty) {
            saComment = serviceComm;
          }
        }
        if (master["formName"] != null &&
            master["formName"].toString().trim().isNotEmpty) {
          inspectionFormName = master["formName"].toString();
        } else if (ifMasterId == null || ifMasterId == 0) {
          inspectionFormName = "Custom Inspection";
        } else {
          inspectionFormName = "Inspection Report";
        }
        if (tasks.isEmpty) continue;
        for (final category in tasks) {
          final name = category["taskCategoryName"]?.toString() ?? "General";
          final categoryTasks = category["tasks"] as List? ?? [];
          if (categoryTasks.isEmpty) continue;

          final categoryMap = categoryTaskMap.putIfAbsent(name, () => {});
          for (final task in categoryTasks) {
            final taskId = task["viTaskId"];
            final taskKey =
                taskId?.toString() ?? task["taskName"]?.toString() ?? "";
            if (taskKey.isEmpty) continue;
            final flags = task["inspectionTaskFlags"] ?? {};

            final existing = categoryMap[taskKey];
            final wasReInspection = existing?.viReInspection ?? false;
            final double reTime =
                double.tryParse(task["viReInspectionTime"]?.toString() ?? "") ??
                0.0;
            final isReInspection =
                task["viReInspection"] == true ||
                task["viReInspection"] == 1 ||
                task["viReInspection"]?.toString() == "true" ||
                reTime > 0.0;

            final String note = (task["viNote"] ?? "").toString();
            final String initialNote = (task["viDescription"] ?? "").toString();


            final int taskIntId = taskId is num ? taskId.toInt() : int.tryParse(taskId?.toString() ?? "") ?? 0;
            final List<String> images = imageMap[vimId]?[taskIntId] ?? [];
            final String? video = videoMap[vimId]?[taskIntId];
            final String? audio = audioMap[vimId]?[taskIntId];

            List<String> finalImages = [];
            String? finalVideo;
            String? finalAudio;
            String finalNote = "";
            String finalInitialNote = "";

            List<String> reImages = const [];
            String? reVideo;
            String? reAudio;
            String? reNote;
            String? reInitialNote;

            if (isReinspectionRun) {
              // Re-inspection: Keep the initial run's media from 'existing'
              finalImages = existing?.imageUrls ?? [];
              finalVideo = existing?.videoUrl;
              finalAudio = existing?.audioUrl;
              finalNote = existing?.note ?? "";
              finalInitialNote = existing?.initialNote ?? "";

              // Re-inspection media goes to separate fields
              reImages = images;
              reVideo = video;
              reAudio = audio;
              reNote = note;
              reInitialNote = initialNote;
            } else {
              // Initial or other run: media goes to the main fields
              finalImages = images;
              finalVideo = video;
              finalAudio = audio;
              finalNote = note;
              finalInitialNote = initialNote;
            }

            final InspectionStatus? finalOriginalStatus = existing != null
                ? (existing.originalStatus ?? existing.status)
                : null;

            final bool currentMarked =
                task["viGood"] == true || task["viGood"] == 1 || task["viGood"]?.toString() == "true" ||
                task["viRepair"] == true || task["viRepair"] == 1 || task["viRepair"]?.toString() == "true" ||
                task["viPoor"] == true || task["viPoor"] == 1 || task["viPoor"]?.toString() == "true" ||
                task["viReplace"] == true || task["viReplace"] == 1 || task["viReplace"]?.toString() == "true" ||
                task["viNotApplicable"] == true || task["viNotApplicable"] == 1 || task["viNotApplicable"]?.toString() == "true" ||
                images.isNotEmpty || video != null || audio != null || note.trim().isNotEmpty || initialNote.trim().isNotEmpty;

            bool finalIsMarked = false;
            bool finalIsReInspectionMarked = false;

            if (isReinspectionRun) {
              finalIsMarked = existing?.isMarked ?? false;
              finalIsReInspectionMarked = currentMarked;
            } else {
              finalIsMarked = currentMarked;
              finalIsReInspectionMarked = false;
            }

            categoryMap[taskKey] = InspectionItem(
              title: task["taskName"] ?? "",
              category: name,
              taskId: taskId is num
                  ? taskId.toInt()
                  : int.tryParse(taskId?.toString() ?? ""),
              status: _mapStatus(task),
              originalStatus: finalOriginalStatus,
              allowGood: flags["good"] == true,
              allowRepair: flags["repair"] == true,
              allowPoor: flags["poor"] == true,
              allowReplace: flags["replace"] == true,
              allowNA: flags["notApplicable"] == true,
              imageUrls: finalImages,
              videoUrl: finalVideo,
              audioUrl: finalAudio,
              note: finalNote,
              initialNote: finalInitialNote,
              viReInspection: isReInspection || wasReInspection,
              reInspectionImageUrls: reImages,
              reInspectionVideoUrl: reVideo,
              reInspectionAudioUrl: reAudio,
              reInspectionNote: reNote,
              reInspectionInitialNote: reInitialNote,
              isMarked: finalIsMarked,
              isReInspectionMarked: finalIsReInspectionMarked,
            );
          }
        }
      }
      categoryTaskMap.forEach((categoryName, tasksMap) {
        groupedItems[categoryName] = tasksMap.values.toList();
      });
      return ApiResponse(
        success: result["statusCode"] == 200,
        statusCode: result['statusCode'],
        timeStamp: result['timeStamp'],
        status: result['status'],
        data: result['data'],
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  InspectionStatus _mapStatus(Map task) {
    final replace =
        task["viReplace"] == true ||
        task["viReplace"] == 1 ||
        task["viReplace"]?.toString() == "true";
    final repair =
        task["viRepair"] == true ||
        task["viRepair"] == 1 ||
        task["viRepair"]?.toString() == "true";
    final poor =
        task["viPoor"] == true ||
        task["viPoor"] == 1 ||
        task["viPoor"]?.toString() == "true";
    final good =
        task["viGood"] == true ||
        task["viGood"] == 1 ||
        task["viGood"]?.toString() == "true";
    if (replace) return InspectionStatus.replace;
    if (repair) return InspectionStatus.repair;
    if (poor) return InspectionStatus.poor;
    if (good) return InspectionStatus.good;
    return InspectionStatus.na;
  }
}
