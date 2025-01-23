import 'package:shared_preferences/shared_preferences.dart';

class LevelStateService {
  Future<void> setLevelStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    // Např. klíč 'level_1' bude ukládat počet hvězdiček pro úroveň 1
    await prefs.setInt('level_$level', stars);
  }

  Future<int> getLevelStars(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('level_$level') ?? 0;
  }

  Future<bool> isLevelUnlocked(int level) async {
    if (level == 1) return true; // První úroveň je vždy odemčená

    final prefs = await SharedPreferences.getInstance();
    // Odemčená bude, pokud má předchozí úroveň >= 1 hvězdu
    return (prefs.getInt('level_${level - 1}') ?? 0) > 0;
  }
}

class ImageLevelManager {
  static const String _basePath = 'lib/res/img';

  static String levelImage(int level, {int stars = 0}) {
    if (stars < 0 || stars > 3) stars = 0; // Ošetření neplatné hodnoty
    return stars == 0
        ? '$_basePath/l$level.png'
        : '$_basePath/l${level}_$stars.png';
  }
}
