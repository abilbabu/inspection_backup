import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inspection/controller/inspectionCard_controller.dart';
import 'package:inspection/controller/inspectionFormController.dart';
import 'package:inspection/model/inspectionTaskModel.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/inspection_screen/widgets/fullscreen_image_screen.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_card.dart';
import 'package:inspection/view/inspection_screen/widgets/inspection_fullscreenvideo.dart';
import 'package:provider/provider.dart';

/// Detailed Confirmation Modal for Reviewing Marked Components (Replace, Repair, Poor)
/// prior to final submission across General Inspection, Custom Inspection,
/// General Re-Inspection, and Custom Re-Inspection workflows.
class InspectionReviewConfirmationModal extends StatefulWidget {
  final int jobId;
  final int formId;
  final int inspectionTypeId;
  final bool isReInspection;
  final Map<String, dynamic>? Function(int taskId) lookupComponent;

  const InspectionReviewConfirmationModal({
    super.key,
    required this.jobId,
    required this.formId,
    required this.inspectionTypeId,
    this.isReInspection = false,
    required this.lookupComponent,
  });

  /// Displays the confirmation modal.
  /// Returns `true` if the user confirms submission, `false` or `null` if cancelled.
  static Future<bool?> show({
    required BuildContext context,
    required int jobId,
    required int formId,
    required int inspectionTypeId,
    bool isReInspection = false,
    required Map<String, dynamic>? Function(int taskId) lookupComponent,
  }) {
    final formController = context.read<InspectionFormController>();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: formController),
          ],
          child: InspectionReviewConfirmationModal(
            jobId: jobId,
            formId: formId,
            inspectionTypeId: inspectionTypeId,
            isReInspection: isReInspection,
            lookupComponent: lookupComponent,
          ),
        );
      },
    );
  }

  @override
  State<InspectionReviewConfirmationModal> createState() =>
      _InspectionReviewConfirmationModalState();
}

class _InspectionReviewConfirmationModalState
    extends State<InspectionReviewConfirmationModal> {
  int _getConditionWeight(String? condition) {
    final cond = condition?.trim().toLowerCase() ?? "";
    if (cond == "replace") return 0;
    if (cond == "repair") return 1;
    if (cond == "poor") return 2;
    return 3;
  }

  bool _isMarkedCondition(String? condition) {
    final cond = condition?.trim().toLowerCase() ?? "";
    return cond == "replace" || cond == "repair" || cond == "poor";
  }

  @override
  Widget build(BuildContext context) {
    final formController = context.watch<InspectionFormController>();

    // Filter all saved tasks marked as Replace, Repair, or Poor
    final markedTasks = formController.orderedTasks.where((task) {
      return formController.isTaskSaved(task.taskId) &&
          _isMarkedCondition(task.condition);
    }).toList();

    // Sort: Replace first, Repair second, Poor third
    markedTasks.sort((a, b) {
      return _getConditionWeight(a.condition)
          .compareTo(_getConditionWeight(b.condition));
    });

    final replaceCount = markedTasks
        .where((t) => t.condition?.trim().toLowerCase() == "replace")
        .length;
    final repairCount = markedTasks
        .where((t) => t.condition?.trim().toLowerCase() == "repair")
        .length;
    final poorCount = markedTasks
        .where((t) => t.condition?.trim().toLowerCase() == "poor")
        .length;

    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 36 : 14,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: mediaQuery.size.height * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Header with Badges & Dismiss
            _buildModalHeader(
              context,
              totalMarked: markedTasks.length,
              replaceCount: replaceCount,
              repairCount: repairCount,
              poorCount: poorCount,
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 2. Meaningful Description Banner
            _buildDescriptionBanner(),

            // 3. Scrollable List of Components or Empty State
            Expanded(
              child: markedTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: markedTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = markedTasks[index];
                        final compMeta = widget.lookupComponent(task.taskId) ?? {};
                        return _buildComponentCard(
                          context,
                          task: task,
                          compMeta: compMeta,
                          formController: formController,
                        );
                      },
                    ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 4. Sticky Bottom Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader(
    BuildContext context, {
    required int totalMarked,
    required int replaceCount,
    required int repairCount,
    required int poorCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 24,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Review Marked Components",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildCountChip(
                      label: "$totalMarked Total",
                      bgColor: const Color(0xFFF1F5F9),
                      textColor: const Color(0xFF475569),
                    ),
                    if (replaceCount > 0)
                      _buildCountChip(
                        label: "$replaceCount Replace",
                        bgColor: const Color(0xFFFEE2E2),
                        textColor: const Color(0xFFDC2626),
                      ),
                    if (repairCount > 0)
                      _buildCountChip(
                        label: "$repairCount Repair",
                        bgColor: const Color(0xFFFEF3C7),
                        textColor: const Color(0xFFD97706),
                      ),
                    if (poorCount > 0)
                      _buildCountChip(
                        label: "$poorCount Poor",
                        bgColor: const Color(0xFFEDE9FE),
                        textColor: const Color(0xFF7C3AED),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
            splashRadius: 20,
            tooltip: "Close",
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDescriptionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Color(0xFF0284C7),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Please review all the components marked as Replace, Repair, or Poor before submitting the inspection. Verify the recorded conditions, notes, and attached media to ensure that all information is accurate. You can update any item before proceeding.",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0369A1),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDCFCE7),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 34,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "No Critical Components Marked",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "No components are currently marked as Replace, Repair, or Poor. All components are in Good or Not Applicable condition. You can safely proceed with submission.",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentCard(
    BuildContext context, {
    required InspectionTaskData task,
    required Map<String, dynamic> compMeta,
    required InspectionFormController formController,
  }) {
    final String componentName =
        compMeta["itcName"]?.toString() ?? "Component #${task.taskId}";
    final String categoryName = compMeta["categoryName"]?.toString() ??
        (widget.isReInspection ? "Re-Inspection" : "Inspection");
    final String condition = task.condition ?? "Unknown";

    // Condition styling
    final Color condBg;
    final Color condBorder;
    final Color condColor;
    final IconData condIcon;
    final String condUpper = condition.trim().toUpperCase();

    switch (condUpper) {
      case "REPLACE":
        condBg = const Color(0xFFFEE2E2);
        condBorder = const Color(0xFFFCA5A5);
        condColor = const Color(0xFFDC2626);
        condIcon = Icons.error_outline_rounded;
        break;
      case "REPAIR":
        condBg = const Color(0xFFFEF3C7);
        condBorder = const Color(0xFFFDE68A);
        condColor = const Color(0xFFD97706);
        condIcon = Icons.build_circle_outlined;
        break;
      case "POOR":
        condBg = const Color(0xFFEDE9FE);
        condBorder = const Color(0xFFDDD6FE);
        condColor = const Color(0xFF7C3AED);
        condIcon = Icons.warning_amber_rounded;
        break;
      default:
        condBg = const Color(0xFFF1F5F9);
        condBorder = const Color(0xFFCBD5E1);
        condColor = const Color(0xFF475569);
        condIcon = Icons.info_outline_rounded;
    }

    // Media gathering
    final List<dynamic> attachedImages = [];
    if (task.imageFiles != null) {
      for (final f in task.imageFiles!) {
        if (f != null && f.existsSync()) {
          attachedImages.add(f);
        }
      }
    }
    if (task.imageUrls != null) {
      for (final u in task.imageUrls!) {
        if (u != null && u.trim().isNotEmpty) {
          attachedImages.add(u);
        }
      }
    }

    final bool hasVideo =
        task.videoFile != null || (task.videoUrl != null && task.videoUrl!.isNotEmpty);
    final bool hasAudio =
        task.audioFilePath != null || (task.audioUrl != null && task.audioUrl!.isNotEmpty);
    final String? customerComments = compMeta["customerComments"]?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Component Name, Category & Condition Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      componentName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Condition Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: condBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: condBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(condIcon, size: 14, color: condColor),
                    const SizedBox(width: 5),
                    Text(
                      condUpper,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: condColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Observations & Technician Notes
          if (task.note.trim().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.note_alt_outlined,
              iconColor: const Color(0xFF0284C7),
              label: "Technician Note:",
              value: task.note.trim(),
            ),
            const SizedBox(height: 6),
          ],

          if (task.description.trim().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.remove_red_eye_outlined,
              iconColor: const Color(0xFF475569),
              label: "Observations:",
              value: task.description.trim(),
            ),
            const SizedBox(height: 6),
          ],

          if (customerComments != null && customerComments.trim().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.person_pin_outlined,
              iconColor: const Color(0xFFD97706),
              label: "Customer Comment:",
              value: customerComments.trim(),
            ),
            const SizedBox(height: 6),
          ],

          // 3. Media Previews (Images, Video, Audio)
          if (attachedImages.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  "Attached Photos (${attachedImages.length}):",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, imgIdx) {
                  final imgItem = attachedImages[imgIdx];
                  return _buildImageThumbnail(
                    context,
                    item: imgItem,
                    label: "$componentName Photo ${imgIdx + 1}",
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (hasVideo) ...[
            const SizedBox(height: 2),
            InkWell(
              onTap: () {
                final String? videoPathOrUrl =
                    task.videoFile?.path ?? task.videoUrl;
                if (videoPathOrUrl != null && videoPathOrUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspectionFullScreenVideo(
                        videoUrl: videoPathOrUrl,
                        label: componentName,
                        isReadOnly: true,
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFDC2626),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Attached Video",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "(Tap to preview)",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (hasAudio) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.mic_rounded, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 6),
                  Text(
                    "Audio Recording Attached",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 4. Update / Edit Action Button
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: const Color(0xFFF0F9FF),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: Color(0xFF0284C7),
                ),
                label: const Text(
                  "Update Component",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
                onPressed: () {
                  _openEditComponentSheet(
                    context,
                    taskId: task.taskId,
                    compMeta: compMeta,
                    formController: formController,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0F172A),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context, {
    required dynamic item,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        if (item is File) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImageScreen(
                imageFile: item,
                isReadOnly: true,
              ),
            ),
          );
        } else if (item is String) {
          _showNetworkImageFullscreen(context, url: item, label: label);
        }
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: item is File
              ? Image.file(
                  item,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                  ),
                )
              : Image.network(
                  item.toString(),
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                  ),
                ),
        ),
      ),
    );
  }

  void _showNetworkImageFullscreen(
    BuildContext context, {
    required String url,
    required String label,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (c, e, s) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditComponentSheet(
    BuildContext context, {
    required int taskId,
    required Map<String, dynamic> compMeta,
    required InspectionFormController formController,
  }) async {
    final categoryId = compMeta["categoryId"] is num
        ? (compMeta["categoryId"] as num).toInt()
        : int.tryParse(compMeta["categoryId"]?.toString() ?? "") ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: formController),
            ChangeNotifierProvider(create: (_) => InspectioncardController()),
          ],
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sheet header with title and close button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Update: ${compMeta["itcName"] ?? 'Component'}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: InspectionCard(
                        jobid: widget.jobId,
                        taskid: taskId,
                        formid: widget.formId,
                        title: compMeta["itcName"]?.toString() ?? "",
                        categoryId: categoryId,
                        inspectionTypeid: widget.inspectionTypeId,
                        isReInspection: widget.isReInspection,
                        isInBottomSheet: true,
                        onSaved: () {
                          // Auto close edit sheet once successfully saved
                          if (Navigator.canPop(sheetContext)) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        inspectionTaskGoodFlag: compMeta["allowGood"] ?? true,
                        inspectionTaskRepairFlag:
                            compMeta["allowRepair"] ?? true,
                        inspectionTaskReplaceFlag:
                            compMeta["allowReplace"] ?? true,
                        inspectionTaskPoorFlag: compMeta["allowPoor"] ?? true,
                        inspectionTaskNotApplicable:
                            compMeta["allowNotApplicable"] ?? false,
                        inspectionTaskPhotoFlag: compMeta["allowPhoto"] ?? true,
                        inspectionTaskAudioFlag: compMeta["allowAudio"] ?? true,
                        inspectionPhotoMandatory:
                            compMeta["photoMandatory"] ?? false,
                        inspectionAudioMandatory:
                            compMeta["audioMandatory"] ?? false,
                        inspectionTaskInstruction:
                            compMeta["instructionText"]?.toString(),
                        assemblyCodeName:
                            compMeta["assemblyCodeName"]?.toString(),
                        assemblyCodeDesc:
                            compMeta["assemblyCodeDesc"]?.toString(),
                        repairGroupName: compMeta["repairGroupName"]?.toString(),
                        repairGroupDesc: compMeta["repairGroupDesc"]?.toString(),
                        allowMultipleImage: true,
                        allowVideo: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 1. Back / Cancel Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFFF8FAFC),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "Back / Cancel",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Confirm & Submit Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: ColorConstants.buttonGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.lightblueColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Confirm & Submit",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
