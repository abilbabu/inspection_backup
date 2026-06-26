import 'package:flutter/material.dart';
import 'package:inspection/controller/inspectionCard_controller.dart';
import 'package:inspection/model/inspectionTaskModel.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';

class InspectionFormController extends ChangeNotifier {
  final Map<int, InspectionTaskData> _tasks = {};
  final Set<int> _savedTaskIds = {};

  final Set<int> _readOnlyTaskIds = {};

  int _totalTasks = 0;

  int get totalTasks => _totalTasks;
  int get savedTasks => _savedTaskIds.length;
  double get progress => _totalTasks == 0 ? 0 : savedTasks / _totalTasks;
  bool get allTasksSaved => _totalTasks > 0 && savedTasks == _totalTasks;

  int? activeTaskId; //warning
  InspectioncardController? activeController; // warning

  /// Keeps pending tasks first, saved tasks last
  List<InspectionTaskData> get orderedTasks {
    final pending = <InspectionTaskData>[];
    final saved = <InspectionTaskData>[];

    for (final task in _tasks.values) {
      if (_savedTaskIds.contains(task.taskId)) {
        saved.add(task);
      } else {
        pending.add(task);
      }
    }
    return [...pending, ...saved];
  }

  void setTotalTasks(int count) {
    _totalTasks = count;
    notifyListeners();
  }

  void markTaskSaved(int taskId) {
    if (_savedTaskIds.contains(taskId)) return;
    _savedTaskIds.add(taskId);

    // 🔒 Auto-lock when saved
    _readOnlyTaskIds.add(taskId);

    notifyListeners();
  }

  /// 🔒 Explicit read-only setter (used during restore)
  void setTaskReadOnly(int taskId, bool value) {
    if (value) {
      _readOnlyTaskIds.add(taskId);
    } else {
      _readOnlyTaskIds.remove(taskId);
    }
    notifyListeners();
  }

  bool isTaskReadOnly(int taskId) {
    return _readOnlyTaskIds.contains(taskId);
  }

  void updateTask(InspectionTaskData data) {
    _tasks[data.taskId] = data;
    notifyListeners();
  }

  InspectionTaskData? getTaskById(int taskId) {
    return _tasks[taskId];
  }

  bool isTaskSaved(int taskId) {
    return _savedTaskIds.contains(taskId);
  }

  void makeTaskEditable(int taskId) {
    _savedTaskIds.remove(taskId);
    _readOnlyTaskIds.remove(taskId);
    notifyListeners();
  }

  void reset() {
    _tasks.clear();
    _savedTaskIds.clear();
    _readOnlyTaskIds.clear();
    _totalTasks = 0;
    notifyListeners();
  }

  //warning
  void setActiveCard(int taskId, InspectioncardController controller) {
    activeTaskId = taskId;
    activeController = controller;
  }

  Future<bool> checkUnsavedBeforeEditing(
    BuildContext context,
    int taskId,
    InspectioncardController controller,
  ) async {
    if (activeController != null &&
        activeController!.hasUnsavedChanges &&
        activeTaskId != taskId) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.warning_amber,
            color: ColorConstants.orangecolor,
            size: 40,
          ),
          title: Text(
            "Unsaved Changes",
            style: ApptextstyleConstants.lightText(
              color: ColorConstants.blackColor,
              fontSize: 18,
            ),
          ),
          content:  Text(
            "You have unsaved changes in another card. Continue without saving?",
            style: ApptextstyleConstants.italicText(
                color: ColorConstants.activecolor,
                fontSize: 15,
              ),
          ),
          actions: [
            TextButton(
              child:  Text("Cancel", style: ApptextstyleConstants.extraLightText(
              color: ColorConstants.blackColor,
              fontSize: 15,
            ),),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return false;
      }
    }

    setActiveCard(taskId, controller);
    return true;
  }
}
