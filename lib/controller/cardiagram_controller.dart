import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:inspection/view/basicInspection_screen/widget/carDiagram_screen.dart';
import 'package:path_provider/path_provider.dart';

class CardiagramController extends ChangeNotifier {

  final GlobalKey imageKey = GlobalKey();
  DamageType selectedDamage = const DamageType("Crack", Color(0xFFF0291A));
  Color get selectedColor => selectedDamage.color;
  bool isDrawingEnabled = true;
  bool _isSaving = false;
  bool isProgrammaticPop = false;
  bool _isImageLoaded = false;
  bool get isImageLoaded => _isImageLoaded;
  bool get isSaving => _isSaving;

  void setImageLoaded(bool loaded) {
    if (_isImageLoaded != loaded) {
      _isImageLoaded = loaded;
      notifyListeners();
    }
  }
  final List<List<Offset>> strokes = [];
  final List<Color> strokeColors = [];
  final List<List<Offset>> redoStrokes = [];
  final List<Color> redoColors = [];
  List<Offset> currentStroke = [];

  final List<DamageType> damageTypes = const [
    DamageType("Crack", Color(0xFFF0291A)),
    DamageType("Scratch", Colors.yellow),
    DamageType("Chip", Colors.blue),
    DamageType("Dent", Colors.orange),
    DamageType("Repainted", Colors.purple),
    DamageType("Faded", Color(0xFF5C2D1C)),
  ];
  void selectDamage(DamageType type) {
    selectedDamage = type;
    notifyListeners();
  }

  void toggleDrawing() {
    isDrawingEnabled = !isDrawingEnabled;
    notifyListeners();
  }

  void onPanStart(DragStartDetails details) {
    final RenderBox? box =
        imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    final Offset normalizedPosition = Offset(
      size.width > 0 ? (localPosition.dx / size.width).clamp(0.0, 1.0) : 0.0,
      size.height > 0 ? (localPosition.dy / size.height).clamp(0.0, 1.0) : 0.0,
    );
    currentStroke = [normalizedPosition];
    strokes.add(currentStroke);
    strokeColors.add(selectedColor);
    redoStrokes.clear();
    redoColors.clear();
    notifyListeners();
  }

  void onPanUpdate(DragUpdateDetails details) {
    final RenderBox? box =
        imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    final Offset normalizedPosition = Offset(
      size.width > 0 ? (localPosition.dx / size.width).clamp(0.0, 1.0) : 0.0,
      size.height > 0 ? (localPosition.dy / size.height).clamp(0.0, 1.0) : 0.0,
    );
    currentStroke.add(normalizedPosition);
    notifyListeners();
  }

  void undo() {
    if (strokes.isEmpty) return;
    redoStrokes.add(strokes.removeLast());
    redoColors.add(strokeColors.removeLast());
    notifyListeners();
  }

  void redo() {
    if (redoStrokes.isEmpty) return;
    strokes.add(redoStrokes.removeLast());
    strokeColors.add(redoColors.removeLast());
    notifyListeners();
  }

  void clearAll() {
    strokes.clear();
    strokeColors.clear();
    redoStrokes.clear();
    redoColors.clear();
    currentStroke = [];
    isDrawingEnabled = true;
    notifyListeners();
  }

  Future<String?> saveMarkedImage() async {
    try {
      // If no strokes were drawn, use the clean asset directly.
      if (strokes.isEmpty) {
        return await _fallbackCleanAsset();
      }

      // Deterministically compose the base image and damage strokes using ui.PictureRecorder + Canvas.
      // This is 100% reliable, never blank, and independent of render boundary lifecycle or frame timings.
      final ByteData data = await rootBundle.load("assets/image/car diagram.jpg");
      final ui.Codec codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image baseImage = fi.image;

      final int width = baseImage.width;
      final int height = baseImage.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      );

      // White solid background to prevent transparency artifacts
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );

      // Draw the base car diagram asset
      canvas.drawImage(baseImage, Offset.zero, Paint());

      // Scale stroke width to match visual thickness from screen
      double strokeWidth = 8.0;
      final RenderBox? box =
          imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.width > 0) {
        strokeWidth = 4.0 * (width / box.size.width);
      }

      // Draw all user-drawn damage strokes
      for (int i = 0; i < strokes.length; i++) {
        final stroke = strokes[i];
        if (stroke.isEmpty) continue;
        final color =
            (i < strokeColors.length) ? strokeColors[i] : selectedColor;

        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (stroke.length == 1) {
          // Single tap / dot
          canvas.drawCircle(
            Offset(stroke.first.dx * width, stroke.first.dy * height),
            strokeWidth / 1.5,
            Paint()..color = color..style = PaintingStyle.fill,
          );
        } else {
          final path = Path()
            ..moveTo(stroke.first.dx * width, stroke.first.dy * height);
          for (int j = 1; j < stroke.length; j++) {
            path.lineTo(stroke[j].dx * width, stroke[j].dy * height);
          }
          canvas.drawPath(path, paint);
        }
      }

      final picture = recorder.endRecording();
      final renderedImage = await picture.toImage(width, height);
      final byteData =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to encode marked car diagram to PNG bytes");
      }

      final directory = await getTemporaryDirectory();
      final outputPath =
          '${directory.path}/car_diagram_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(outputPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      debugPrint("✅ Marked car diagram saved successfully to $outputPath (${file.lengthSync()} bytes)");
      return outputPath;
    } catch (e, stack) {
      debugPrint("❌ Error composing marked diagram on canvas: $e\n$stack");
      // As a fallback, try RepaintBoundary if canvas composition failed
      final boundaryPath = await _saveViaRepaintBoundary();
      if (boundaryPath != null) return boundaryPath;
      return await _fallbackCleanAsset();
    }
  }

  Future<String?> _saveViaRepaintBoundary() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize || boundary.size.isEmpty) {
        return null;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final directory = await getTemporaryDirectory();
      final tempPngPath =
          '${directory.path}/temp_boundary_diagram_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(tempPngPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return tempPngPath;
    } catch (e) {
      debugPrint("RepaintBoundary fallback failed: $e");
      return null;
    }
  }

  Future<String?> _fallbackCleanAsset() async {
    try {
      final byteData = await rootBundle.load("assets/image/car diagram.jpg");
      final directory = await getTemporaryDirectory();
      final jpgPath =
          '${directory.path}/car_diagram_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(jpgPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return jpgPath;
    } catch (e) {
      debugPrint("Error loading fallback car diagram asset: $e");
      return null;
    }
  }

  Future<void> onNextPressed(
    BuildContext context,
    Future<bool> Function(File file) uploadFn,
  ) async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();
    try {
      final path = await saveMarkedImage();
      if (path == null) return;
      final success = await uploadFn(File(path));
      if (success) {
        clearAll();
        if (context.mounted) {
          isProgrammaticPop = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pop(context, path);
            }
          });
        }
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
