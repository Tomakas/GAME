import 'package:flutter/material.dart';
import 'levels_screen.dart';
import 'practise_screen.dart';
import 'settings_screen.dart';
import 'goals_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Metoda pro navigaci na jinou obrazovku
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domovská obrazovka'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tlačítko pro přechod do "Hra"
            ElevatedButton(
              onPressed: () => _navigateTo(context, const LevelsScreen()),
              child: const Text('Hra'),
            ),
            const SizedBox(height: 16),
            // Tlačítko pro přechod do "Procvičování"
            ElevatedButton(
              onPressed: () => _navigateTo(context, const PractiseScreen()),
              child: const Text('Procvičování'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateTo(context, const GoalsScreen()),
              child: const Text('Úspěchy'),
            ),
            const SizedBox(height: 16),
            // Tlačítko pro přechod do "Nastavení"
            ElevatedButton(
              onPressed: () => _navigateTo(context, const SettingsScreen()),
              child: const Text('Nastavení'),
            ),
          ],
        ),
      ),
    );
  }
}
