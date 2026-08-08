import 'dart:convert';

class MediaItemQueue {
  final String filePath;
  final String type; // "0" for image, "1" for video, "2" for audio
  final bool is360;
  final int imgIndex;

  MediaItemQueue({
    required this.filePath,
    required this.type,
    this.is360 = false,
    this.imgIndex = 0,
  });

  bool get isImage => type == "0";
  bool get isVideo => type == "1";
  bool get isAudio => type == "2";

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'type': type,
      'is360': is360,
      'imgIndex': imgIndex,
    };
  }

  factory MediaItemQueue.fromJson(Map<String, dynamic> json) {
    return MediaItemQueue(
      filePath: json['filePath'] ?? '',
      type: json['type'] ?? '0',
      is360: json['is360'] ?? false,
      imgIndex: json['imgIndex'] ?? 0,
    );
  }
}

class UploadQueueModel {
  final String id;
  final int jobId;
  final String endpointUrl;
  final List<MediaItemQueue> mediaItems;
  final Map<String, String> fields;
  final String status; // 'pending', 'uploading', 'failed', 'completed'
  final int retryCount;
  final String createdAt;

  UploadQueueModel({
    required this.id,
    required this.jobId,
    required this.endpointUrl,
    required this.mediaItems,
    required this.fields,
    this.status = 'pending',
    this.retryCount = 0,
    required this.createdAt,
  });

  UploadQueueModel copyWith({
    String? status,
    int? retryCount,
  }) {
    return UploadQueueModel(
      id: this.id,
      jobId: this.jobId,
      endpointUrl: this.endpointUrl,
      mediaItems: this.mediaItems,
      fields: this.fields,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'endpointUrl': endpointUrl,
      'mediaItems': mediaItems.map((item) => item.toJson()).toList(),
      'fields': fields,
      'status': status,
      'retryCount': retryCount,
      'createdAt': createdAt,
    };
  }

  factory UploadQueueModel.fromJson(Map<String, dynamic> json) {
    return UploadQueueModel(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? 0,
      endpointUrl: json['endpointUrl'] ?? '',
      mediaItems: (json['mediaItems'] as List<dynamic>?)
              ?.map((item) => MediaItemQueue.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      fields: Map<String, String>.from(json['fields'] ?? {}),
      status: json['status'] ?? 'pending',
      retryCount: json['retryCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  String encode() => jsonEncode(toJson());

  factory UploadQueueModel.decode(String str) =>
      UploadQueueModel.fromJson(jsonDecode(str));
}
