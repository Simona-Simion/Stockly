import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  static const String _databaseName = 'stockly_local.db';
  static const int _databaseVersion = 1;
  static const String tablaProductos = 'productos';
  static const String tablaRecetas = 'recetas';
  static const String tablaRecetaLineas = 'receta_lineas';
  static const String tablaOperacionesPendientes = 'operaciones_pendientes';

  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  Database? _database;

  bool get isSupported => true;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> close() async {
    if (_database == null) {
      return;
    }

    await _database!.close();
    _database = null;
  }

  Future<bool> hasNetworkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  String generateOperationUuid() {
    return _uuid.v4();
  }

  Future<Database> _openDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/$_databaseName';

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaProductos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        codigo_barras TEXT,
        unidad_medida TEXT,
        stock_actual REAL NOT NULL DEFAULT 0,
        stock_minimo REAL,
        precio_unidad REAL,
        activo INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablaRecetas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio_venta REAL,
        activo INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablaRecetaLineas (
        id TEXT PRIMARY KEY,
        receta_id TEXT NOT NULL,
        producto_id TEXT NOT NULL,
        cantidad REAL NOT NULL,
        unidad_medida TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tablaOperacionesPendientes (
        id_local INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid_operacion TEXT NOT NULL UNIQUE,
        tipo_operacion TEXT NOT NULL,
        referencia_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        fecha_creacion_local TEXT NOT NULL,
        empleado_id TEXT,
        device_id TEXT,
        estado TEXT NOT NULL,
        motivo_conflicto TEXT,
        reintentos INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await _onCreate(db, newVersion);
    }
  }
}
