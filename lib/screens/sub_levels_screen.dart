import 'package:flutter/material.dart';
import '../services/utility.dart';
import '../screens/game_screen.dart';

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

  late List<int> subStars;
  late List<bool> subUnlocked;

  final LevelStateService _levelService = LevelStateService();

  @override
  void initState() {
    super.initState();
    subStars = List<int>.filled(totalSubLevels, 0);
    subUnlocked = List<bool>.filled(totalSubLevels, false);
    _loadSubLevelsState();
  }

  /// Načteme hvězdy sub-úrovní a zda jsou odemčené
  Future<void> _loadSubLevelsState() async {
    for (int i = 0; i < totalSubLevels; i++) {
      final subIndex = i + 1;
      final stars = await _levelService.getSubLevelStars(widget.mainLevel, subIndex);
      subStars[i] = stars;

      if (i == 0) {
        // První sub-level vždy odemčený
        subUnlocked[i] = true;
      } else {
        subUnlocked[i] = (subStars[i - 1] > 0);
      }
    }
    setState(() {});
  }

  String _getSubImagePath(int index) {
    final subIndex = index + 1;
    if (!subUnlocked[index]) {
      return 'lib/res/img/sub${subIndex}_locked.png';
    }
    final stars = subStars[index];
    return 'lib/res/img/sub${subIndex}_$stars.png';
  }

  /// Pouze pokud subUnlocked[index] je true -> spustíme hru
  void _onSubLevelTap(int index) {
    final subLevel = index + 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mainLevel: widget.mainLevel,
          subLevel: subLevel,
          onGameFinished: () {
            _loadSubLevelsState();
            widget.onSubLevelsChanged();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Podúrovně úrovně ${widget.mainLevel}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            final isUnlocked = subUnlocked[index];

            return GestureDetector(
              onTap: isUnlocked ? () => _onSubLevelTap(index) : null,
              child: Image.asset(imagePath),
            );
          },
        ),
      ),
    );
  }
}
