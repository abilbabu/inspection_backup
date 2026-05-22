import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inspection/view/basicInspection_screen/widget/carDiagram_screen.dart';
import 'package:path_provider/path_provider.dart';

class CardiagramController extends ChangeNotifier {

  final GlobalKey imageKey = GlobalKey();
  DamageType selectedDamage = const DamageType("Crack", Color(0xFFF0291A));
  Color get selectedColor => selectedDamage.color;
  bool isDrawingEnabled = false;
  bool _isSaving = false;
  bool isProgrammaticPop = false;
  bool get isSaving => _isSaving;
  final List<List<Offset>> strokes = [];
  final List<Color> strokeColors = [];
  final List<List<Offset>> redoStrokes = [];
  final List<Color> redoColors = [];
  List<Offset> currentStroke = [];

  final List<DamageType> damageTypes = const [
    DamageType("Scratch", Colors.yellow),
    DamageType("Chip", Colors.blue),
    DamageType("Dent", Colors.orange),
    DamageType("Repainted", Colors.purple),
    DamageType("Faded", Color(0xFF5C2D1C)),
    DamageType("Crack", Color(0xFFF0291A)),
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
    currentStroke = [localPosition];
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
    currentStroke.add(localPosition);
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
    notifyListeners();
  }

  Future<String?> saveMarkedImage() async {
    try {
      final boundary =
          imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/car_diagram_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return path;
    } catch (e) {
      debugPrint("Save error: $e");
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
