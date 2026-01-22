import 'package:flutter/material.dart';
import 'pantalla_curso.dart';

/// Archivo de prueba para ejecutar solo PantallaCurso
///
/// Para probar, cambia temporalmente main.dart:
///
/// import 'test_pantalla_curso.dart';
/// void main() {
///   runApp(const TestPantallaCurso());
/// }

void main() {
  runApp(const TestPantallaCurso());
}

class TestPantallaCurso extends StatelessWidget {
  const TestPantallaCurso({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Test Pantalla Curso',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PantallaCurso(),
    );
  }
}
