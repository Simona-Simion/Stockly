import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:stockly/services/local_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'providers/alerta_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/receta_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auto_sync_service.dart';
import 'services/fcm_service.dart';
import 'services/local_database_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FcmService.solicitarPermiso();
  await LocalDatabaseService.instance.initialize();
  //await LocalDatabaseService.instance.resetearOperacionesEnviando();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlertaProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => RecetaProvider()),
      ],
      child: const StocklyApp(),
    ),
  );
}

class StocklyApp extends StatelessWidget {
  const StocklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      // Redirige a login o a la app segun el estado de autenticacion
      home: const _AppBootstrap(child: _AuthGate()),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap({required this.child});

  final Widget child;

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  final AutoSyncService _autoSyncService = AutoSyncService();

  @override
  void initState() {
    super.initState();
    _autoSyncService.start();
  }

  @override
  void dispose() {
    _autoSyncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Widget que escucha AuthProvider y muestra LoginScreen o HomeScreen
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    print('AUTH_GATE build');
    print('AUTH_GATE autenticado: ${authProvider.isAuthenticated}');
    print('AUTH_GATE perfilCargando: ${authProvider.perfilCargando}');
    print('AUTH_GATE usuario cargado: ${authProvider.usuario != null}');

    if (authProvider.isAuthenticated && authProvider.perfilCargando) {
      print('AUTH_GATE mostrando carga');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.isAuthenticated && authProvider.usuario != null) {
      print('AUTH_GATE mostrando HOME');
      return const HomeScreen();
    }

    print('AUTH_GATE mostrando LOGIN');
    return const LoginScreen();
  }
}
