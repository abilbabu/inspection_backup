import 'package:flutter/material.dart';
import 'package:inspection/controller/basicInspectionReport_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';
import 'package:inspection/utils/network_sync_manager.dart';
import 'package:provider/provider.dart';

/// Interactive UI Widget for the Signature page that displays live upload status
/// breakdown for a specific Job Card (Total, Uploading, Pending, Failed).
class JobUploadStatusWidget extends StatefulWidget {
  final int jobId;
  final ValueChanged<bool>? onSyncStatusChanged;
  const JobUploadStatusWidget({
    super.key,
    required this.jobId,
    this.onSyncStatusChanged,
  });

  @override
  State<JobUploadStatusWidget> createState() => _JobUploadStatusWidgetState();
}

class _JobUploadStatusWidgetState extends State<JobUploadStatusWidget> {
  Map<String, int> _stats = {
    'pending': 0,
    'uploading': 0,
    'failed': 0,
    'totalQueue': 0,
  };
  bool _isLoadingStats = true;
  bool _isRefreshing = false;
  int _lastTotalQueue = -1;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final stats = await LocalUploadStorageService.getJobUploadStats(widget.jobId);
    if (mounted) {
      final totalQueue = stats['totalQueue'] ?? 0;
      final failed = stats['failed'] ?? 0;
      if (_lastTotalQueue > 0 && totalQueue == 0) {
        context.read<BasicInspectionReportController>().getBasicInspection(widget.jobId, forceRefresh: true);
      }
      _lastTotalQueue = totalQueue;
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });

      final isSyncComplete = (totalQueue == 0 && failed == 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onSyncStatusChanged?.call(isSyncComplete);
        }
      });
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isRefreshing = true);
    await LocalUploadStorageService.resetFailedTasksForJob(widget.jobId);
    await NetworkSyncManager().syncIfConnected();
    await _fetchStats();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncManager = NetworkSyncManager();

    return ListenableBuilder(
      listenable: syncManager,
      builder: (context, _) {
        _fetchStats();
        if (_isLoadingStats) {
          return const SizedBox.shrink();
        }
        final pending = _stats['pending'] ?? 0;
        final uploading = _stats['uploading'] ?? 0;
        final failed = _stats['failed'] ?? 0;
        final totalQueue = _stats['totalQueue'] ?? 0;
        final isOnline = syncManager.isNetworkAvailable;

        if (totalQueue == 0 && failed == 0) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "All inspection media synchronized with server",
                    style: ApptextstyleConstants.mediumText(
                      color: Colors.green.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: failed > 0 ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: failed > 0 ? Colors.red.shade300 : Colors.blue.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        failed > 0
                            ? Icons.error_outline
                            : (uploading > 0 ? Icons.cloud_upload : Icons.cloud_queue),
                        color: failed > 0 ? Colors.red.shade800 : Colors.blue.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Basic Inspection Upload Status",
                        style: ApptextstyleConstants.boldText(
                          color: failed > 0 ? Colors.red.shade900 : Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (uploading > 0 || _isRefreshing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBadge("Pending", "$pending", Colors.orange.shade800),
                  _buildStatBadge("Uploading", "$uploading", Colors.blue.shade800),
                  _buildStatBadge("Failed", "$failed", Colors.red.shade800),
                ],
              ),
              if (failed > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Upload failed for some media files due to network timeout or error.",
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _isRefreshing ? null : _handleRetry,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text(
                        "Retry Uploads",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ] else if (!isOnline) ...[
                const SizedBox(height: 8),
                Text(
                  "⚠️ Device is offline. Media saved locally. Connect to network to sync.",
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
