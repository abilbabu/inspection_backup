import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class InspectionscreenimageController extends ChangeNotifier {
  late File displayedImage;

  bool imageLoaded = false;
  bool isEditMode = false;
  bool isLoading = false;
  bool isSuccess = false;
  int rotationAngle = 0;

  final List<List<Offset>> strokes = [];
  final List<List<Offset>> redoStack = [];
  List<Offset> currentStroke = [];

  final GlobalKey imageKey = GlobalKey();

  Future<void> init(File file, int angle) async {
    displayedImage = file;
    if (angle != 0) {
      await _fixRotation(angle);
    }
    await preloadImage();
  }

  Future<void> _fixRotation(int angle) async {
    try {
      final bytes = await displayedImage.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original != null && angle != 0) {
        img.Image fixed = img.copyRotate(original, angle: angle);
        await displayedImage.writeAsBytes(img.encodeJpg(fixed));
      }
    } catch (e) {
      debugPrint("Rotation fix error: $e");
    }
  }

  Future<void> preloadImage() async {
    final image = Image.file(displayedImage);
    final completer = Completer<void>();
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((_, __) => completer.complete()));
    await completer.future;
    imageLoaded = true;
    notifyListeners();
  }

  void toggleEditMode() {
    isEditMode = !isEditMode;
    if (isEditMode) clearAll();
    notifyListeners();
  }

  void startStroke(Offset point) {
    currentStroke = [point];
    strokes.add(currentStroke);
    redoStack.clear();
    notifyListeners();
  }

  void updateStroke(Offset point) {
    currentStroke.add(point);
    notifyListeners();
  }

  void endStroke() {
    currentStroke = [];
  }

  void undo() {
    if (strokes.isNotEmpty) {
      redoStack.add(strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (redoStack.isNotEmpty) {
      strokes.add(redoStack.removeLast());
      notifyListeners();
    }
  }

  void clearAll() {
    strokes.clear();
    redoStack.clear();
    notifyListeners();
  }

  Future<File?> saveImageWithStrokes() async {
    if (isLoading || isSuccess) return null;
    isLoading = true;
    notifyListeners();
    try {
      final ui.Image baseImage = await _loadUiImage(displayedImage);
      const int targetWidth = 1080;
      final double scale = targetWidth / baseImage.width;
      final int _ = (baseImage.height * scale).round();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(
          0,
          0,
          baseImage.width.toDouble(),
          baseImage.height.toDouble(),
        ),
      );
      canvas.drawImage(baseImage, Offset.zero, Paint());
      final RenderBox box =
          imageKey.currentContext!.findRenderObject() as RenderBox;
      final Size widgetSize = box.size;
      final scaleX = baseImage.width / widgetSize.width;
      final scaleY = baseImage.height / widgetSize.height;
      final paint = Paint()
        ..color = Colors.red
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final stroke in strokes) {
        if (stroke.length < 2) continue;
        final path = Path()
          ..moveTo(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
        }
        canvas.drawPath(path, paint);
      }
      final picture = recorder.endRecording();
      final img = await picture.toImage(baseImage.width, baseImage.height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      final compressed = await compressImage(file);
      isSuccess = true;
      return compressed;
    } catch (e) {
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ui.Image> _loadUiImage(File file) async {
    final data = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );
    return file;
  }

  Future<void> rotateImage() async {
    try {
      final bytes = await displayedImage.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) return;
      img.Image rotated = img.copyRotate(original, angle: 90);
      final rotatedBytes = Uint8List.fromList(img.encodeJpg(rotated));
      final tempDir = await Directory.systemTemp.createTemp();
      final newFile = File('${tempDir.path}/rotated.jpg');
      await newFile.writeAsBytes(rotatedBytes);
      displayedImage = newFile;
      notifyListeners();
    } catch (e) {
      debugPrint("Rotate error: $e");
    }
  }
}
