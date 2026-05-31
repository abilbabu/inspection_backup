import 'dart:io';

class InspectionTaskData {
  final int? categoryId;
  final int jobId;
  final int taskId;
  final int formId;
  final String? condition;
  final String note;
  final String description;
  // final File? imageFile;
  final String? audioFilePath;
  // final String? imageUrl;
  final String? audioUrl;
  final bool inserted;
  bool isSaved;
  final File? videoFile;     // local capture
  final String? videoUrl;

  final List<File>? imageFiles;
  final List<String>? imageUrls;

  InspectionTaskData({
   this.categoryId,
    required this.jobId,
    required this.taskId,
    required this.formId,
    required this.condition,
    required this.note,
    required this.description,
    this.audioFilePath,
    this.audioUrl,
    this.inserted = false,
    this.isSaved = false,
    this.imageFiles,
    this.imageUrls,
    this.videoUrl,
     this.videoFile,
  });
}


