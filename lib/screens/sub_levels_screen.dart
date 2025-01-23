import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Obrazovka s 5 podúrovněmi pro danou hlavní úroveň [mainLevel].
/// Při každé změně hvězdiček podúrovní se přepočítá součet hvězdiček
/// (0–15) a nastaví se hvězdy hlavní úrovně (0–3).
class SubLevelsScreen extends StatefulWidget {
  final int mainLevel;
  final VoidCallback onSubLevelsChanged;
  // Callback pro obnovu stavu v GameScreen, až se vrátíme zpět

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

  late List<int> subStars;     // hvězdičky podúrovní 0–3
  late List<bool> subUnlocked; // zamčené / odemčené podúrovně

  @override
  void initState() {
    super.initState();
    subStars = List<int>.filled(totalSubLevels, 0, growable: false);
    subUnlocked = List<bool>.filled(totalSubLevels, false, growable: false);

    _loadSubLevelsState();
  }

  /// Načte hvězdičky (0–3) pro každou z 5 podúrovní dané hlavní úrovně
  Future<void> _loadSubLevelsState() async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 1; i <= totalSubLevels; i++) {
      final key = 'sub_${widget.mainLevel}_$i';
      final stars = prefs.getInt(key) ?? 0;
      subStars[i - 1] = stars;

      if (i == 1) {
        subUnlocked[i - 1] = true; // první podúroveň vždy odemčená,
      } else {
        final prevStars = subStars[i - 2];
        subUnlocked[i - 1] = (prevStars > 0);
      }
    }

    setState(() {});
  }

  /// Přepočítá součet hvězdiček v podúrovních (0–15)
  /// a dle tabulky jej uloží jako hvězdy hlavní úrovně (0–3).
  Future<void> _updateMainLevelStars() async {
    final prefs = await SharedPreferences.getInstance();
    final sumStars = subStars.fold<int>(0, (acc, x) => acc + x);
    // 0..15

    int mainLevelStars;
    if (sumStars < 5) {
      mainLevelStars = 0;
    } else if (sumStars < 10) {
      mainLevelStars = 1;
    } else if (sumStars < 15) {
      mainLevelStars = 2;
    } else {
      // sumStars == 15
      mainLevelStars = 3;
    }

    // Uložíme do SharedPreferences, např. level_1 = 2 hvězdy
    await prefs.setInt('level_${widget.mainLevel}', mainLevelStars);

    // Požadujeme, aby se v GameScreen znovu načetl stav
    widget.onSubLevelsChanged();
  }

  /// Vrátí cestu k obrázku subX_0..subX_3 nebo subX_locked
  String _getSubImagePath(int index) {
    final subIndex = index + 1;
    if (!subUnlocked[index]) {
      return 'lib/res/img/sub${subIndex}_locked.png';
    }
    final stars = subStars[index];
    return 'lib/res/img/sub${subIndex}_$stars.png';
  }

  /// Klik na konkrétní podúroveň -> přidá hvězdičku (max 3)
  /// a odemkne další sub-level, pak aktualizuje hvězdy hlavní úrovně.
  Future<void> _onSubLevelTap(int index) async {
    if (!subUnlocked[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Podúroveň ${index + 1} je zamčená.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    if (subStars[index] < 3) {
      subStars[index]++;
      final key = 'sub_${widget.mainLevel}_${index + 1}';
      await prefs.setInt(key, subStars[index]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Podúroveň ${index + 1} má nyní ${subStars[index]} hvězdiček.')),
      );

      // Odemčení další sub-level (pokud je v rozsahu)
      final nextIndex = index + 1;
      if (nextIndex < totalSubLevels && subStars[index] > 0) {
        subUnlocked[nextIndex] = true;
      }

      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Podúroveň ${index + 1} už má 3 hvězdičky.')),
      );
    }

    // Po každé změně hvězdiček v sub-levelu přepočítej hvězdy hlavní úrovně
    await _updateMainLevelStars();
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
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
