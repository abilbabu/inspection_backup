import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:inspection/apiServices/media_upload_sync_service.dart';
import 'package:inspection/utils/local_upload_storage_service.dart';

class NetworkSyncManager extends ChangeNotifier {
  static final NetworkSyncManager _instance = NetworkSyncManager._internal();
  factory NetworkSyncManager() => _instance;
  NetworkSyncManager._internal();

  Timer? _periodicSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isNetworkAvailable = true;
  bool get isNetworkAvailable => _isNetworkAvailable;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  /// Initialize sync manager listener & periodic queue inspector
  void initialize() async {
    // Reset any tasks left stuck in 'uploading' status due to prior app crashes
    await LocalUploadStorageService.resetOrphanedUploadingTasks();
    await refreshPendingCount();
    
    // Check network and sync immediately on launch
    syncIfConnected();

    // Listen to real-time connectivity changes using connectivity_plus
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        syncIfConnected();
      } else {
        _isNetworkAvailable = false;
        notifyListeners();
      }
    });

    // Set up periodic check every 30 seconds to auto-drain queue when online
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncIfConnected();
    });
  }

  /// Check active internet connectivity via socket DNS lookup
  Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      _isNetworkAvailable = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _isNetworkAvailable = false;
    }
    notifyListeners();
    return _isNetworkAvailable;
  }

  /// Trigger queue processing if network is available
  Future<void> syncIfConnected() async {
    final hasNet = await checkInternetConnection();
    await refreshPendingCount();
    if (hasNet && _pendingCount > 0) {
      await MediaUploadSyncService.processQueue();
      await refreshPendingCount();
    }
  }

  /// Refresh pending count for UI badges or notification banners
  Future<int> refreshPendingCount() async {
    final pending = await LocalUploadStorageService.getPendingTasks();
    _pendingCount = pending.length;
    notifyListeners();
    return _pendingCount;
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
