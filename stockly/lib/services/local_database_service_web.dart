import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();
  static const String tablaProductos = 'productos';
  static const String tablaRecetas = 'recetas';
  static const String tablaRecetaLineas = 'receta_lineas';
  static const String tablaOperacionesPendientes = 'operaciones_pendientes';

  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  bool get isSupported => false;

  Future<Database> get database async {
    throw UnsupportedError('Local database is not available on web');
  }

  Future<void> initialize() async {}

  Future<void> close() async {}

  Future<bool> hasNetworkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  String generateOperationUuid() {
    return _uuid.v4();
  }
}
