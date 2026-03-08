import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/producto_provider.dart';
import 'providers/receta_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // MultiProvider registra todos los providers en la raíz de la app.
    // Así cualquier pantalla puede acceder al estado sin pasarlo manualmente.
    MultiProvider(
      providers: [
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
          seedColor: const Color(0xFF1565C0), // azul corporativo
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
