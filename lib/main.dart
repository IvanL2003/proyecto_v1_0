import 'package:flutter/material.dart';
import 'principal.dart'; // si está en otro archivo, cámbialo al nombre correcto

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // quita el banner de "Debug"
      title: 'Bottom Bar Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Principal(), // aquí mostramos tu widget
    );
  }
}
