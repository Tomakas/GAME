import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub_levels_screen.dart';

/// Zobrazuje hlavní úrovně (1..10). Každá úroveň má 0–3 hvězdičky.
/// Ty se nyní určují podle součtu hvězdiček v podúrovních.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({Key? key}) : super(key: key);

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final int totalLevels = 10;

  late List<int> starCounts; // Hvězdy hlavních úrovní (0–3)
  late List<bool> unlocked;

  @override
  void initState() {
    super.initState();
    starCounts = List<int>.filled(totalLevels, 0, growable: false);
    unlocked = List<bool>.filled(totalLevels, false, growable: false);

    _loadLevelStates();
  }

  /// Načte stav hlavních úrovní (jejich hvězdičky 0–3) a zamčení z SharedPreferences.
  Future<void> _loadLevelStates() async {
    final prefs = await SharedPreferences.getInstance();

    for (int level = 1; level <= totalLevels; level++) {
      // Počet hvězdiček pro hlavní úroveň (0–3, určených součtem z podúrovní)
      final stars = prefs.getInt('level_$level') ?? 0;
      starCounts[level - 1] = stars;

      // Odemčení hlavní úrovně: pokud je level == 1, je vždy odemčená,
      // jinak se odemkne, pokud předchozí hlavní úroveň má aspoň 1 hvězdičku
      if (level == 1) {
        unlocked[level - 1] = true;
      } else {
        final prevStars = starCounts[level - 2];
        unlocked[level - 1] = (prevStars > 0);
      }
    }

    setState(() {});
  }

  /// Resetuje hvězdy i zamčení všech hlavních i podúrovní
  Future<void> _resetAllLevels() async {
    final prefs = await SharedPreferences.getInstance();

    // Vynulujeme všechny hlavní úrovně
    for (int i = 0; i < totalLevels; i++) {
      starCounts[i] = 0;
      await prefs.setInt('level_${i + 1}', 0);
      unlocked[i] = (i == 0); // Jen první úroveň odemčená
    }

    // Vynulujeme i podúrovně (5 pro každou hlavní úroveň)
    for (int mainLevel = 1; mainLevel <= totalLevels; mainLevel++) {
      for (int sub = 1; sub <= 5; sub++) {
        final key = 'sub_${mainLevel}_$sub';
        await prefs.setInt(key, 0);
      }
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset hotov: všechny úrovně i podúrovně vynulovány.')),
    );
  }

  /// Vrací cestu k ikoně hlavní úrovně (lX_0..lX_3 nebo locked)
  String _getLevelImagePath(int index) {
    final levelNumber = index + 1;
    if (!unlocked[index]) {
      return 'lib/res/img/l${levelNumber}_locked.png';
    }
    final stars = starCounts[index];
    // 0–3 hvězdiček
    return 'lib/res/img/l${levelNumber}_$stars.png';
  }

  /// Klik na hlavní úroveň -> otevře se obrazovka podúrovní
  void _onLevelTap(int index) {
    if (!unlocked[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tato úroveň je zatím zamčená.')),
      );
      return;
    }
    final mainLevel = index + 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubLevelsScreen(
          mainLevel: mainLevel,
          onSubLevelsChanged: _loadLevelStates,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hlavní úrovně'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAllLevels,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: totalLevels,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final path = _getLevelImagePath(index);
            return GestureDetector(
              onTap: () => _onLevelTap(index),
              child: Image.asset(path),
            );
          },
        ),
      ),
    );
  }
}
