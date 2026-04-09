import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/operacion_sync_repository.dart';
import 'api_service.dart';
import 'local_database_service.dart';

class AutoSyncService {
  AutoSyncService({
    OperacionSyncRepository? operacionSyncRepository,
    ApiService? apiService,
  })  : _operacionSyncRepository =
            operacionSyncRepository ?? OperacionSyncRepository(),
        _apiService = apiService ?? ApiService();

  final OperacionSyncRepository _operacionSyncRepository;
  final ApiService _apiService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _wasOffline = false;

  Future<void> start() async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported) {
      return;
    }

    if (_connectivitySubscription != null) {
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    _wasOffline = !hasNetwork;

    _connectivitySubscription =
        localDatabaseService.onConnectivityChanged.listen((results) async {
      final hasNetwork = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!hasNetwork) {
        _wasOffline = true;
        return;
      }

      if (!_wasOffline) {
        return;
      }

      _wasOffline = false;
      await sincronizarSiCorresponde();
    });
  }

  Future<void> sincronizarSiCorresponde() async {
    final localDatabaseService = LocalDatabaseService.instance;

    if (!localDatabaseService.isSupported || _isSyncing) {
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    if (!hasNetwork) {
      _wasOffline = true;
      return;
    }

    final backendAvailable = await _apiService.isBackendAvailable();
    if (!backendAvailable) {
      _wasOffline = true;
      return;
    }

    _isSyncing = true;

    try {
      await _operacionSyncRepository.sincronizarPendientes();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
