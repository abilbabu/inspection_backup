import 'package:flutter/material.dart';
import 'package:inspection/utils/network_sync_manager.dart';

/// A UI banner/badge widget that informs the user when media items
/// are stored locally and currently waiting for internet connection to sync.
class OfflineSyncStatusBadge extends StatelessWidget {
  const OfflineSyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final syncManager = NetworkSyncManager();

    return ListenableBuilder(
      listenable: syncManager,
      builder: (context, _) {
        final pendingCount = syncManager.pendingCount;
        final isOnline = syncManager.isNetworkAvailable;

        if (pendingCount == 0 && isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isOnline
              ? Colors.amber.shade700
              : Colors.orange.shade900,
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_upload : Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  !isOnline
                      ? "Offline: $pendingCount media item(s) saved locally."
                      : "Syncing $pendingCount pending media upload(s)...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isOnline && pendingCount > 0)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              if (!isOnline)
                TextButton(
                  onPressed: () => syncManager.syncIfConnected(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Retry Sync",
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
