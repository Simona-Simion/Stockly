import 'package:sqflite/sqflite.dart';

import '../models/usuario.dart';
import 'local_database_service.dart';

class UsuarioLocalService {
  Future<Database> get _database async =>
      LocalDatabaseService.instance.database;

  Future<void> guardarUsuario(Usuario usuario) async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete(LocalDatabaseService.tablaUsuarios);
      await txn.insert(
        LocalDatabaseService.tablaUsuarios,
        _toMap(usuario),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<Usuario?> obtenerUsuarioGuardado() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return null;
    }

    final db = await _database;
    final rows = await db.query(
      LocalDatabaseService.tablaUsuarios,
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  Future<void> borrarUsuario() async {
    if (!LocalDatabaseService.instance.isSupported) {
      return;
    }

    final db = await _database;
    await db.delete(LocalDatabaseService.tablaUsuarios);
  }

  Usuario _fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      supabaseUserId: map['supabase_user_id'] as String,
      email: map['email'] as String,
      nombre: map['nombre'] as String,
      rol: map['rol'] == 'ADMIN' ? Rol.ADMIN : Rol.EMPLEADO,
    );
  }

  Map<String, dynamic> _toMap(Usuario usuario) {
    return {
      'id': usuario.id,
      'supabase_user_id': usuario.supabaseUserId,
      'email': usuario.email,
      'nombre': usuario.nombre,
      'rol': usuario.rol.name,
    };
  }
}
