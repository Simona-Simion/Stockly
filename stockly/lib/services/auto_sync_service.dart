import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stockly/repositories/operacion_sync_repository.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'catalogo_local_sync_service.dart';
import 'local_database_service.dart';

class AutoSyncService {
  AutoSyncService({
    OperacionSyncRepository? operacionSyncRepository,
    ApiService? apiService,
    CatalogoLocalSyncService? catalogoLocalSyncService,
  }) : _operacionSyncRepository =
           operacionSyncRepository ?? OperacionSyncRepository(),
       _apiService = apiService ?? ApiService(),
       _catalogoLocalSyncService =
           catalogoLocalSyncService ?? CatalogoLocalSyncService();

  final OperacionSyncRepository _operacionSyncRepository;
  final ApiService _apiService;
  final CatalogoLocalSyncService _catalogoLocalSyncService;

  static const Duration _periodicSyncInterval = Duration(minutes: 2);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool _wasOffline = false;

  Future<void> start() async {
    final localDatabaseService = LocalDatabaseService.instance;

    print('AUTOSYNC start');
    print('AUTOSYNC apiBaseUrl: $apiBaseUrl');

    if (!localDatabaseService.isSupported) {
      return;
    }

    _periodicSyncTimer ??= Timer.periodic(_periodicSyncInterval, (_) {
      unawaited(sincronizarSiCorresponde());
    });

    if (_connectivitySubscription != null) {
      return;
    }

    final hasNetwork = await localDatabaseService.hasNetworkConnection();
    _wasOffline = !hasNetwork;

    _connectivitySubscription = localDatabaseService.onConnectivityChanged
        .listen((results) async {
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

    if (hasNetwork) {
      await sincronizarSiCorresponde();
    }
  }

  Future<void> sincronizarSiCorresponde() async {
    final localDatabaseService = LocalDatabaseService.instance;
    final session = Supabase.instance.client.auth.currentSession;

    if (!localDatabaseService.isSupported || _isSyncing) {
      return;
    }

    if (session == null) {
      print('AUTOSYNC cancelado: no hay sesion');
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
      print('AUTOSYNC backend no disponible');
      return;
    }

    _isSyncing = true;

    try {
      print('AUTOSYNC iniciando sincronizacion');
      await _operacionSyncRepository.sincronizarPendientesYErroresTecnicos();
      await _catalogoLocalSyncService.refrescarDesdeBackend();
      print('AUTOSYNC sincronizacion completada');
    } catch (e, st) {
      print('AUTOSYNC error en sincronizacion inicial: $e');
      print('AUTOSYNC stacktrace: $st');
      _wasOffline = true;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }
}
