import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Hlavní widget aplikace
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basic Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}
