import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
    final RenderBox box =
        imageKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    final Offset normalizedPosition = Offset(
      size.width > 0 ? localPosition.dx / size.width : 0.0,
      size.height > 0 ? localPosition.dy / size.height : 0.0,
    );
    currentStroke = [normalizedPosition];
    strokes.add(currentStroke);
    strokeColors.add(selectedColor);
    redoStrokes.clear();
    redoColors.clear();
    notifyListeners();
  }

  void onPanUpdate(DragUpdateDetails details) {
    final RenderBox box =
        imageKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final Size size = box.size;
    final Offset normalizedPosition = Offset(
      size.width > 0 ? localPosition.dx / size.width : 0.0,
      size.height > 0 ? localPosition.dy / size.height : 0.0,
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
      // If no strokes were drawn, immediately use the clean asset.
      // This is 100% reliable, instant, and never black.
      if (strokes.isEmpty) {
        return await _fallbackCleanAsset();
      }

      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize || boundary.size.isEmpty) {
        return await _fallbackCleanAsset();
      }

      if (boundary.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }

      // pixelRatio 2.0 provides plenty of resolution for diagram markings
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return await _fallbackCleanAsset();
      }
      
      final directory = await getTemporaryDirectory();
      final tempPngPath =
          '${directory.path}/temp_car_diagram_${DateTime.now().millisecondsSinceEpoch}.png';
      final pngFile = File(tempPngPath);
      await pngFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      final jpgPath =
          '${directory.path}/car_diagram_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
            tempPngPath,
            jpgPath,
            quality: 75,
            format: CompressFormat.jpeg,
            minWidth: 1080,
            minHeight: 1080,
          );

      // Clean up the temporary PNG file
      try {
        if (await pngFile.exists()) {
          await pngFile.delete();
        }
      } catch (e) {
      }

      if (compressedXFile != null) {
        return compressedXFile.path;
      }
      return tempPngPath; // Fallback to raw png if compression fails
    } catch (e) {
      debugPrint("Error in saveMarkedImage: $e");
      return await _fallbackCleanAsset();
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
