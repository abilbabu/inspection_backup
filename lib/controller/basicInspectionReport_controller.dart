import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class BasicInspectionReportController with ChangeNotifier {
  int? vimDocType;
  String? note;
  TextEditingController additionalCommentsController = TextEditingController();
  Map<int, bool> selectedCheckBox = {};
  Map<int, String> checkBoxType = {};
  Map<String, dynamic>? diagram;
  Map<String, dynamic>? signature;
  List<Map<String, dynamic>> allEssentials = [];
  List<int> selectedEssentialIds = [];
  double fuelValue = 0;
  List<String> fuelMarks = ["E", "1/4", "1/2", "3/4", "F"];
  List<Map<String, dynamic>> externalGroups = [];
  List<Map<String, dynamic>> internalGroups = [];
  String? external360Video;
  String? internal360Video;
  String? external360Comment;
  String? internal360Comment;
  String? essentialImageUrl;
  VideoPlayerController? externalVideoController;
  VideoPlayerController? internalVideoController;
  bool isVideoPlaying = false;
  bool isBasicInspectionLoading = false;
  bool isEssentialsLoading = false;
  bool get isLoading => isBasicInspectionLoading || isEssentialsLoading;
  int? get loadedJobId => _loadedJobId;
  bool isExternalVideoInitialized = false;
  bool isInternalVideoInitialized = false;
  bool isExternalVideoPlaying = false;
  bool isInternalVideoPlaying = false;
  bool isVideoInitialized = false;
  int? _loadedJobId;
  Duration externalVideoPosition = Duration.zero;
  Duration externalVideoDuration = Duration.zero;
  Duration internalVideoPosition = Duration.zero;
  Duration internalVideoDuration = Duration.zero;

  Future<void> initializeExternalVideo(String url) async {
    externalVideoController?.dispose();
    externalVideoController = VideoPlayerController.network(url);
    await externalVideoController!.initialize();
    externalVideoDuration = externalVideoController!.value.duration;
    isExternalVideoInitialized = true;
    isExternalVideoPlaying = false;
    externalVideoController!.addListener(_externalVideoListener);
    notifyListeners();
  }

  Future<void> initializeInternalVideo(String url) async {
    internalVideoController?.dispose();
    internalVideoController = VideoPlayerController.network(url);
    await internalVideoController!.initialize();
    internalVideoDuration = internalVideoController!.value.duration;
    isInternalVideoInitialized = true;
    isInternalVideoPlaying = false;
    internalVideoController!.addListener(_internalVideoListener);
    notifyListeners();
  }

  void _externalVideoListener() {
    if (externalVideoController == null) return;

    final isPlaying = externalVideoController!.value.isPlaying;
    final newPosition = externalVideoController!.value.position;

    bool needsNotify = false;
    if (isPlaying != isExternalVideoPlaying) {
      isExternalVideoPlaying = isPlaying;
      needsNotify = true;
    }
    if (newPosition.inSeconds != externalVideoPosition.inSeconds) {
      externalVideoPosition = newPosition;
      needsNotify = true;
    }

    if (needsNotify) {
      notifyListeners();
    }
  }

  void _internalVideoListener() {
    if (internalVideoController == null) return;

    final isPlaying = internalVideoController!.value.isPlaying;
    final newPosition = internalVideoController!.value.position;

    bool needsNotify = false;
    if (isPlaying != isInternalVideoPlaying) {
      isInternalVideoPlaying = isPlaying;
      needsNotify = true;
    }
    if (newPosition.inSeconds != internalVideoPosition.inSeconds) {
      internalVideoPosition = newPosition;
      needsNotify = true;
    }

    if (needsNotify) {
      notifyListeners();
    }
  }

  void toggleExternalPlayPause() {
    if (externalVideoController == null) return;
    if (externalVideoController!.value.isPlaying) {
      externalVideoController!.pause();
      isExternalVideoPlaying = false;
    } else {
      externalVideoController!.play();
      isExternalVideoPlaying = true;
    }
    notifyListeners();
  }

  void toggleInternalPlayPause() {
    if (internalVideoController == null) return;
    if (internalVideoController!.value.isPlaying) {
      internalVideoController!.pause();
      isInternalVideoPlaying = false;
    } else {
      internalVideoController!.play();
      isInternalVideoPlaying = true;
    }
    notifyListeners();
  }

  void seekExternalVideo(Duration position) {
    externalVideoController?.seekTo(position);
  }

  void seekInternalVideo(Duration position) {
    internalVideoController?.seekTo(position);
  }

  void clearLoadedJobId() {
    _loadedJobId = null;
    isBasicInspectionLoading = true;
    isEssentialsLoading = true;
  }

  Future<void> getBasicInspection(int jobId, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _loadedJobId = null;
    }
    if (_loadedJobId == jobId) {
      isBasicInspectionLoading = false;
      notifyListeners();
      return;
    }
    _loadedJobId = jobId;
    isBasicInspectionLoading = true;
    notifyListeners();
    try {
      externalVideoController?.dispose();
      internalVideoController?.dispose();
      externalVideoController = null;
      internalVideoController = null;
      isExternalVideoInitialized = false;
      isInternalVideoInitialized = false;
      isExternalVideoPlaying = false;
      isInternalVideoPlaying = false;
      external360Video = null;
      internal360Video = null;
      external360Comment = null;
      internal360Comment = null;
      externalGroups.clear();
      internalGroups.clear();
      diagram = null;
      signature = null;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse(ApiServices.getBasicInspection),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({"jobId": jobId}),
      );
      final result = jsonDecode(response.body);
      final data = result["data"];
      vimDocType = data["vimDocType"];
      note = (data["note"] ?? "").toString().trim();
      essentialImageUrl = data["essentinalImage"];
      String fuelMark = (data["vFuelMark"] ?? "E").toString();
      fuelValue = fuelMarks.indexOf(fuelMark).toDouble();
      if (fuelValue < 0) {
        fuelValue = 0;
      }
      additionalCommentsController.text = (data["vimAdditionalComments"] ?? "")
          .toString()
          .trim();
      selectedEssentialIds = (data["essentialDetails"] ?? [])
          .map<int>((e) => e["veId"] as int)
          .toSet()
          .toList();
      final attachments = data["basicinspectionattachments"];
      if (attachments != null) {
        List external = attachments["externalImages"] ?? [];
        List internal = attachments["internalImages"] ?? [];
        for (var group in external) {
          String label = group["label"] ?? "";
          bool videoFlag = group["videoFlag"] ?? false;
          int? videoDuration = group["videoDuration"];
          List attachList = group["attachments"] ?? [];
          List<Map<String, dynamic>> imageList = [];
          String? normalVideoUrl;
          String? comment;
          for (var item in attachList) {
            int? iaType = item["iaType"];
            int? iaImageType = item["iaImageType"];
            String url = item["iaUrl"];
            if (iaType == 0 && iaImageType == 0) {
              imageList.add({"url": url});
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && iaImageType == 0) {
              normalVideoUrl = url;
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && iaImageType == 10) {
              external360Video = url;
              external360Comment = item["iaInspectionNote"];
            }
          }
          externalGroups.add({
            "label": label,
            "images": imageList,
            "videoUrl": normalVideoUrl,
            "comment": comment,
            "videoDuration": videoDuration,
            "videoFlag": videoFlag,
          });
        }
        for (var group in internal) {
          String label = group["label"] ?? "";
          bool videoFlag = group["videoFlag"] ?? false;
          int? videoDuration = group["videoDuration"];
          List attachList = group["attachments"] ?? [];
          List<Map<String, dynamic>> imageList = [];
          String? normalVideoUrl;
          String? comment;
          for (var item in attachList) {
            int? iaType = item["iaType"];
            int? iaImageType = item["iaImageType"];
            String url = item["iaUrl"];
            if (iaType == 0 && iaImageType == 0) {
              imageList.add({"url": url});
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && iaImageType == 0) {
              normalVideoUrl = url;
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && iaImageType == 10) {
              internal360Video = url;
              internal360Comment = item["iaInspectionNote"];
            }
          }
          internalGroups.add({
            "label": label,
            "images": imageList,
            "videoUrl": normalVideoUrl,
            "comment": comment,
            "videoDuration": videoDuration,
            "videoFlag": videoFlag,
          });
        }
        if (attachments["cardiagram"] != null) {
          diagram = {"url": attachments["cardiagram"]};
        }
        if (attachments["signature"] != null) {
          signature = {"url": attachments["signature"]};
        }
      }
      if (external360Video != null && external360Video!.isNotEmpty) {
        await initializeExternalVideo(external360Video!);
      }
      if (internal360Video != null && internal360Video!.isNotEmpty) {
        await initializeInternalVideo(internal360Video!);
      }
    } catch (e) {
      debugPrint("Error : $e");
    } finally {
      isBasicInspectionLoading = false;
      notifyListeners();
    }
  }

  String get documentTypeText {
    switch (vimDocType) {
      case 0:
        return "Soft Copy";
      case 1:
        return "Hard Copy";
      case 2:
        return "N/A";
      default:
        return "";
    }
  }

  Future<void> getVehicleEssentialList({String? defaultValue}) async {
    isEssentialsLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse(ApiServices.getvehicleEssentialList);
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
        final List list = res['data'] ?? [];
        allEssentials = List<Map<String, dynamic>>.from(list);
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
      debugPrint("Error: $e");
    } finally {
      isEssentialsLoading = false;
      notifyListeners();
    }
  }

  String getEssentialNameById(int id) {
    try {
      return allEssentials
          .firstWhere((e) => e["veId"] == id)["veName"]
          .toString();
    } catch (e) {
      return "Unknown";
    }
  }
}
