import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';

class ComponentListWidget extends StatefulWidget {
  final int? jobId;

  const ComponentListWidget({super.key, this.jobId});

  @override
  State<ComponentListWidget> createState() => _ComponentListWidgetState();
}

class _ComponentListWidgetState extends State<ComponentListWidget> {
  final String inspectionName = "360 Degree Inspection";

  final List<InspectionTask> tasks = [
    InspectionTask(
      taskName: "Mechanical - Task 1",
      components: [
        ComponentItem(name: "Brake Pad"),
        ComponentItem(name: "Clutch Plate"),
      ],
    ),
    InspectionTask(
      taskName: "Mechanical - Task 2",
      components: [ComponentItem(name: "Oil Filter")],
    ),
    InspectionTask(
      taskName: "Electrical - Task 4",
      components: [
        ComponentItem(name: "Battery"),
        ComponentItem(name: "Fuse"),
      ],
    ),
  ];

  Future<bool> _showRejectConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Reject Component"),
              content: const Text(
                "Are you sure you want to reject this component?",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("NO"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("YES"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => context.go('/home'),
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor,
        appBar: CustomAppBar(
          title: 'Component List',
          onBackPress: () => context.go('/home'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildInspectionHeader(),
              const SizedBox(height: 12),
              Expanded(child: _buildTaskList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          inspectionName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (_, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskHeader(task),
              const SizedBox(height: 10),
              ...task.components.map(_buildComponentTile).toList(),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _addComponentDialog(task),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Component"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskHeader(InspectionTask task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          task.taskName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (_showAcceptAll(task))
          OutlinedButton(
            onPressed: () => _acceptAll(task),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text("Accept All"),
          ),
      ],
    );
  }

  Widget _buildComponentTile(ComponentItem component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _componentBgColor(component.status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(component.name), _buildComponentAction(component)],
      ),
    );
  }

  Widget _buildComponentAction(ComponentItem component) {
    if (component.status == ComponentStatus.accepted) {
      return _statusChip("Accepted", Colors.green);
    }
    if (component.status == ComponentStatus.rejected) {
      return _statusChip("Rejected", Colors.red);
    }
    return Row(
      children: [
        _iconActionButton(
          icon: Icons.check,
          color: Colors.green,
          onTap: () {
            setState(() {
              component.status = ComponentStatus.accepted;
            });
          },
        ),
        const SizedBox(width: 8),
        _iconActionButton(
          icon: Icons.close,
          color: Colors.red,
          onTap: () async {
            final bool confirm = await _showRejectConfirmation();
            if (!confirm) return;
            setState(() {
              component.status = ComponentStatus.rejected;
            });
          },
        ),
      ],
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  bool _showAcceptAll(InspectionTask task) {
    return task.components.any((c) => c.status == ComponentStatus.none);
  }

  Color _componentBgColor(ComponentStatus status) {
    switch (status) {
      case ComponentStatus.accepted:
        return Colors.green.withOpacity(0.12);
      case ComponentStatus.rejected:
        return Colors.red.withOpacity(0.12);
      default:
        return const Color(0xFFF8F9FB);
    }
  }

  void _acceptAll(InspectionTask task) {
    setState(() {
      for (var c in task.components) {
        c.status = ComponentStatus.accepted;
      }
    });
  }

  void _addComponentDialog(InspectionTask task) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Component",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Component name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      setState(() {
                        task.components.add(
                          ComponentItem(
                            name: controller.text.trim(),
                            status: ComponentStatus.accepted,
                          ),
                        );
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Add Component"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum ComponentStatus { none, accepted, rejected }

class InspectionTask {
  final String taskName;
  final List<ComponentItem> components;
  InspectionTask({required this.taskName, required this.components});
}

class ComponentItem {
  final String name;
  ComponentStatus status;
  ComponentItem({required this.name, this.status = ComponentStatus.none});
}
