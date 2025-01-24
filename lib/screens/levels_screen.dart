import 'package:flutter/material.dart';
import '../services/utility.dart';
import 'sub_levels_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({Key? key}) : super(key: key);

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final int totalLevels = 10;

  late List<int> starCounts;
  late List<bool> unlocked;

  // 1) Vytvoříme si službu
  final LevelStateService _levelService = LevelStateService();

  @override
  void initState() {
    super.initState();
    starCounts = List<int>.filled(totalLevels, 0);
    unlocked  = List<bool>.filled(totalLevels, false);

    _loadLevelStates();
  }

  /// 2) Místo přímého volání SharedPreferences, voláme metody _levelService
  Future<void> _loadLevelStates() async {
    for (int i = 0; i < totalLevels; i++) {
      final levelNumber = i + 1;

      // Kolik hvězdiček má hlavní úroveň?
      final stars = await _levelService.getLevelStars(levelNumber);
      starCounts[i] = stars;

      // Je úroveň odemčená?
      final isUnlocked = await _levelService.isLevelUnlocked(levelNumber);
      unlocked[i] = isUnlocked;
    }

    setState(() {});
  }


  /// 4) Místo lokální metody _getLevelImagePath voláme ImageLevelManager
  String _getLevelImagePath(int index) {
    final levelNumber = index + 1;
    final stars = starCounts[index];
    final isUnlocked = unlocked[index];
    return ImageLevelManager.levelImagePath(levelNumber, isUnlocked, stars);
  }

  /// Klik na hlavní úroveň -> otevře sub-levels
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
        title: const Text('Hlavní úrovně')
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
