import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';
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
  List<Map<String, dynamic>> quickInspectionGroups = [];
  List<Map<String, dynamic>> additionalImageGroups = [];
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
  String? jobInspectionType;

  Future<void> initializeExternalVideo(String url) async {
    try {
      if (externalVideoController != null && isExternalVideoInitialized && external360Video == url) {
        return;
      }
      final oldController = externalVideoController;
      VideoPlayerController newController;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        newController = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        newController = VideoPlayerController.file(File(url));
      }
      await newController.initialize();
      oldController?.removeListener(_externalVideoListener);
      oldController?.dispose();

      externalVideoController = newController;
      externalVideoDuration = newController.value.duration;
      isExternalVideoInitialized = true;
      isExternalVideoPlaying = false;
      newController.addListener(_externalVideoListener);
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing external 360 video: $e");
    }
  }

  Future<void> initializeInternalVideo(String url) async {
    try {
      if (internalVideoController != null && isInternalVideoInitialized && internal360Video == url) {
        return;
      }
      final oldController = internalVideoController;
      VideoPlayerController newController;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        newController = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        newController = VideoPlayerController.file(File(url));
      }
      await newController.initialize();
      oldController?.removeListener(_internalVideoListener);
      oldController?.dispose();

      internalVideoController = newController;
      internalVideoDuration = newController.value.duration;
      isInternalVideoInitialized = true;
      isInternalVideoPlaying = false;
      newController.addListener(_internalVideoListener);
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing internal 360 video: $e");
    }
  }

  void _externalVideoListener() {
    if (externalVideoController == null) return;
    isExternalVideoPlaying = externalVideoController!.value.isPlaying;
    externalVideoPosition = externalVideoController!.value.position;
  }

  void _internalVideoListener() {
    if (internalVideoController == null) return;
    isInternalVideoPlaying = internalVideoController!.value.isPlaying;
    internalVideoPosition = internalVideoController!.value.position;
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
    final bool isInitial = _loadedJobId != jobId;
    if (_loadedJobId == jobId && !forceRefresh) {
      isBasicInspectionLoading = false;
      notifyListeners();
      return;
    }
    _loadedJobId = jobId;
    if (isInitial) {
      isBasicInspectionLoading = true;
      notifyListeners();
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
      quickInspectionGroups.clear();
      additionalImageGroups.clear();
      diagram = null;
      signature = null;
    }
    try {
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
      jobInspectionType = data["jobInspectionType"];
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
        void addGroupToTarget(
          List<Map<String, dynamic>> targetList,
          String label,
          List<Map<String, dynamic>> imageList,
          String? normalVideoUrl,
          String? comment,
          int? videoDuration,
          bool videoFlag,
        ) {
          final trimmedLabel = label.trim();
          final existingIndex = targetList.indexWhere(
            (g) => (g["label"] as String? ?? "").trim().toLowerCase() == trimmedLabel.toLowerCase(),
          );

          if (existingIndex != -1) {
            final existing = targetList[existingIndex];
            final List<Map<String, dynamic>> existingImages = List<Map<String, dynamic>>.from(existing["images"] ?? []);
            final Set<String> existingUrls = existingImages.map((e) => (e["url"] ?? "").toString()).toSet();

            for (var img in imageList) {
              final String url = (img["url"] ?? "").toString();
              if (url.isNotEmpty && !existingUrls.contains(url)) {
                existingImages.add(img);
                existingUrls.add(url);
              }
            }

            existing["images"] = existingImages;
            if (existing["videoUrl"] == null && normalVideoUrl != null) {
              existing["videoUrl"] = normalVideoUrl;
            }
            if ((existing["comment"] == null || existing["comment"].toString().isEmpty) && comment != null) {
              existing["comment"] = comment;
            }
          } else {
            final List<Map<String, dynamic>> uniqueImages = [];
            final Set<String> seenUrls = {};
            for (var img in imageList) {
              final String url = (img["url"] ?? "").toString();
              if (url.isNotEmpty && !seenUrls.contains(url)) {
                seenUrls.add(url);
                uniqueImages.add(img);
              }
            }
            targetList.add({
              "label": label,
              "images": uniqueImages,
              "videoUrl": normalVideoUrl,
              "comment": comment,
              "videoDuration": videoDuration,
              "videoFlag": videoFlag,
            });
          }
        }

        String? extractVideoUrlFromDynamic(dynamic val) {
          if (val == null) return null;
          if (val is String && val.trim().isNotEmpty) return val.trim();
          if (val is Map) {
            final u = val["iaUrl"] ?? val["url"] ?? val["path"] ?? val["videoUrl"] ?? val["ia_url"];
            if (u != null && u.toString().trim().isNotEmpty) return u.toString().trim();
          }
          if (val is List && val.isNotEmpty) {
            for (var sub in val) {
              final res = extractVideoUrlFromDynamic(sub);
              if (res != null && res.isNotEmpty) return res;
            }
          }
          return null;
        }

        external360Video ??= extractVideoUrlFromDynamic(attachments["external360"]) ??
                             extractVideoUrlFromDynamic(attachments["external360Video"]) ??
                             extractVideoUrlFromDynamic(attachments["360"]) ??
                             extractVideoUrlFromDynamic(attachments["video360"]);

        internal360Video ??= extractVideoUrlFromDynamic(attachments["internal360"]) ??
                             extractVideoUrlFromDynamic(attachments["internal360Video"]);

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
            String? url = item["iaUrl"] ?? item["url"];
            if (url == null || url.toString().trim().isEmpty) continue;
            final cleanUrl = url.toString().trim();
            if (iaType == 0 && (iaImageType == 0 || iaImageType == null)) {
              imageList.add({"url": cleanUrl});
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && (iaImageType == 0 || iaImageType == null)) {
              normalVideoUrl = cleanUrl;
              comment ??= item["iaInspectionNote"];
            }
            final bool is360 = iaImageType == 10 ||
                item["is360"] == true ||
                item["attachType"] == 10 ||
                item["attachType"] == "10" ||
                item["iaInspectionType"] == 0;
            if (iaType == 2 && is360) {
              external360Video = cleanUrl;
              external360Comment = item["iaInspectionNote"];
            }
          }
          addGroupToTarget(
            externalGroups,
            label,
            imageList,
            normalVideoUrl,
            comment,
            videoDuration,
            videoFlag,
          );
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
            String? url = item["iaUrl"] ?? item["url"];
            if (url == null || url.toString().trim().isEmpty) continue;
            final cleanUrl = url.toString().trim();
            if (iaType == 0 && (iaImageType == 0 || iaImageType == null)) {
              imageList.add({"url": cleanUrl});
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && (iaImageType == 0 || iaImageType == null)) {
              normalVideoUrl = cleanUrl;
              comment ??= item["iaInspectionNote"];
            }
            final bool is360 = iaImageType == 10 ||
                item["is360"] == true ||
                item["attachType"] == 10 ||
                item["attachType"] == "10" ||
                item["iaInspectionType"] == 1;
            if (iaType == 2 && is360) {
              internal360Video = cleanUrl;
              internal360Comment = item["iaInspectionNote"];
            }
          }
          addGroupToTarget(
            internalGroups,
            label,
            imageList,
            normalVideoUrl,
            comment,
            videoDuration,
            videoFlag,
          );
        }
        List quick = attachments["quickInspectionImages"] ?? [];
        List additional = attachments["additionalImages"] ?? [];
        for (var group in quick) {
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
            String? url = item["iaUrl"];
            if (url == null || url.isEmpty) continue;
            if (iaType == 0 && iaImageType == 14) {
              imageList.add({"url": url});
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && iaImageType == 14) {
              normalVideoUrl = url;
              comment ??= item["iaInspectionNote"];
            }
          }
          addGroupToTarget(
            quickInspectionGroups,
            label,
            imageList,
            normalVideoUrl,
            comment,
            videoDuration,
            videoFlag,
          );
        }
        for (var group in additional) {
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
            String? url = item["iaUrl"];
            if (url == null || url.isEmpty) continue;
            if (iaType == 0 && iaImageType == 15) {
              imageList.add({"url": url});
              comment ??= item["iaInspectionNote"];
            }
            if (iaType == 2 && iaImageType == 15) {
              normalVideoUrl = url;
              comment ??= item["iaInspectionNote"];
            }
          }
          addGroupToTarget(
            additionalImageGroups,
            label,
            imageList,
            normalVideoUrl,
            comment,
            videoDuration,
            videoFlag,
          );
        }
        if (attachments["cardiagram"] != null) {
          diagram = {"url": attachments["cardiagram"]};
        }
        if (attachments["signature"] != null) {
          signature = {"url": attachments["signature"]};
        }
      }

      // Local storage fallback for pending/recently captured 360 videos
      try {
        final pendingQueue = await LocalUploadStorageService.getQueue();
        for (var task in pendingQueue) {
          if (task.jobId == jobId) {
            for (var m in task.mediaItems) {
              if (m.is360 ||
                  task.fields["attachType"] == "10" ||
                  task.fields["inspectionImageId"] == "-10" ||
                  task.fields["inspectionImageId"] == "-20") {
                final f = File(m.filePath);
                if (f.existsSync()) {
                  final isExternal = task.fields["stage"] == "external360" ||
                      task.fields["inspectionImageId"] == "-10" ||
                      (task.fields["iaInspectionType"] ?? "0") == "0";
                  if (isExternal) {
                    external360Video ??= m.filePath;
                  } else {
                    internal360Video ??= m.filePath;
                  }
                }
              }
            }
          }
        }

        final extDraft = await LocalUploadStorageService.getDraftMedia(
            jobId: jobId, stageKey: 'external360');
        if (extDraft != null && extDraft['video'] is File) {
          final file = extDraft['video'] as File;
          if (file.existsSync()) {
            external360Video ??= file.path;
          }
        }
        final intDraft = await LocalUploadStorageService.getDraftMedia(
            jobId: jobId, stageKey: 'internal360');
        if (intDraft != null && intDraft['video'] is File) {
          final file = intDraft['video'] as File;
          if (file.existsSync()) {
            internal360Video ??= file.path;
          }
        }
      } catch (_) {}
      if (external360Video != null && external360Video!.isNotEmpty) {
        initializeExternalVideo(external360Video!);
      }
      if (internal360Video != null && internal360Video!.isNotEmpty) {
        initializeInternalVideo(internal360Video!);
      }
    } catch (e) {
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

  Future<bool> saveCustomerComplaint(int jobId, String complaint) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse("${ApiServices.baseUrl}jobcard/updateCustomerComplaint"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({
          "jobId": jobId,
          "customerComplaint": complaint,
        }),
      );
      if (response.statusCode == 200) {
        additionalCommentsController.text = complaint;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
