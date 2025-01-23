import 'package:flutter/material.dart';
import '../services/utility.dart';

class SubLevelsScreen extends StatefulWidget {
  final int mainLevel;
  final VoidCallback onSubLevelsChanged;

  const SubLevelsScreen({
    Key? key,
    required this.mainLevel,
    required this.onSubLevelsChanged,
  }) : super(key: key);

  @override
  State<SubLevelsScreen> createState() => _SubLevelsScreenState();
}

class _SubLevelsScreenState extends State<SubLevelsScreen> {
  static const int totalSubLevels = 5;

  late List<int> subStars;     // hvězdičky (0–3) pro 5 podúrovní
  late List<bool> subUnlocked; // zamčené / odemčené

  // 1) Načteme si službu
  final LevelStateService _levelService = LevelStateService();

  @override
  void initState() {
    super.initState();
    subStars    = List<int>.filled(totalSubLevels, 0);
    subUnlocked = List<bool>.filled(totalSubLevels, false);

    _loadSubLevelsState();
  }

  /// 2) Načítáme hvězdičky z _levelService.getSubLevelStars(...)
  Future<void> _loadSubLevelsState() async {
    for (int i = 0; i < totalSubLevels; i++) {
      final subIndex = i + 1;
      final stars = await _levelService.getSubLevelStars(widget.mainLevel, subIndex);
      subStars[i] = stars;

      // Odemčená, pokud i == 0, nebo předchozí subIndex má aspoň 1 hvězdu
      if (i == 0) {
        subUnlocked[i] = true;
      } else {
        subUnlocked[i] = (subStars[i - 1] > 0);
      }
    }
    setState(() {});
  }

  /// 3) Přepočet hvězdiček hlavní úrovně dle součtu subStars
  /// a zápis do "level_X"
  Future<void> _updateMainLevelStars() async {
    final sumStars = subStars.fold<int>(0, (acc, x) => acc + x); // 0..15
    int mainLevelStars;
    if (sumStars < 5) {
      mainLevelStars = 0;
    } else if (sumStars < 10) {
      mainLevelStars = 1;
    } else if (sumStars < 15) {
      mainLevelStars = 2;
    } else {
      mainLevelStars = 3;
    }

    // Nastavení hvězdiček pro danou hlavní úroveň
    await _levelService.setLevelStars(widget.mainLevel, mainLevelStars);

    // Zavoláme callback, aby se v "LevelsScreen" aktualizovala data
    widget.onSubLevelsChanged();
  }

  /// 4) Sestavení cesty k obrázku z ImageLevelManager
  String _getSubImagePath(int index) {
    final subIndex = index + 1;
    final isUnlocked = subUnlocked[index];
    final stars = subStars[index];
    return ImageLevelManager.subLevelImagePath(subIndex, isUnlocked, stars);
  }

  /// Klik na podúroveň -> zvýší hvězdičku (max 3), odemkne další atd.
  Future<void> _onSubLevelTap(int index) async {
    if (!subUnlocked[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Podúroveň ${index + 1} je zamčená.')),
      );
      return;
    }

    if (subStars[index] < 3) {
      final newStarCount = subStars[index] + 1;
      subStars[index] = newStarCount;

      // Uložit do SharedPreferences (přes službu)
      await _levelService.setSubLevelStars(widget.mainLevel, index + 1, newStarCount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Podúroveň ${index + 1} má nyní $newStarCount hvězdiček.')),
      );

      // Odemknout další sub-level (pokud existuje)
      final nextIndex = index + 1;
      if (nextIndex < totalSubLevels && subStars[index] > 0) {
        subUnlocked[nextIndex] = true;
      }

      setState(() {});
      // Přepočítat hvězdy hlavní úrovně
      await _updateMainLevelStars();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Podúroveň ${index + 1} už má 3 hvězdičky.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Podúrovně úrovně ${widget.mainLevel}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: totalSubLevels,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final imagePath = _getSubImagePath(index);
            return GestureDetector(
              onTap: () => _onSubLevelTap(index),
              child: Image.asset(imagePath),
            );
          },
        ),
      ),
    );
  }
}
