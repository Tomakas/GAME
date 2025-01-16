import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            // Zatím bez specifické akce
          },
          child: Image.asset(
            'lib/res/levels.jpg',
            fit: BoxFit.cover, // Obrázek bude roztažen na celou obrazovku
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
