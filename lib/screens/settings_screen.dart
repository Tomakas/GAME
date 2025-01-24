import 'package:flutter/material.dart';
import '../services/utility.dart'; // upravte dle vaší cesty

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int totalLevels = 10;
  final int totalSubLevels = 5;

  // Vytvoříme instanci služby
  final LevelStateService _levelService = LevelStateService();

  Future<void> _resetAll() async {
    // Smažeme hvězdy hlavních úrovní
    await _levelService.resetAllLevels(totalLevels);
    // Smažeme hvězdy podúrovní
    await _levelService.resetAllSubLevels(totalLevels, totalSubLevels);

    // Zde můžeme dát snackBar s oznámením
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Všechny úrovně i podúrovně byly úspěšně resetovány.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // V AppBar přidáme tlačítko zpět
      appBar: AppBar(
        title: const Text('Nastavení'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // vrátí se zpět
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _resetAll,
          child: const Text('Reset všeho'),
        ),
      ),
    );
  }
}
