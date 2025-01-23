import 'package:shared_preferences/shared_preferences.dart';

/// Služba pro práci se stavem úrovní a podúrovní (ukládání do SharedPreferences).
class LevelStateService {
  // ========== Hlavní úrovně ==========

  /// Uloží počet hvězdiček pro danou hlavní úroveň (1..N).
  Future<void> setLevelStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level_$level', stars);
  }

  /// Načte počet hvězdiček pro danou hlavní úroveň (1..N).
  Future<int> getLevelStars(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('level_$level') ?? 0;
  }

  /// Zjistí, zda je hlavní úroveň odemčená.
  /// - Úroveň 1 je vždy odemčená.
  /// - Ostatní úrovně se odemknou, pokud předchozí úroveň má >= 1 hvězdu.
  Future<bool> isLevelUnlocked(int level) async {
    if (level == 1) return true;
    final prevStars = await getLevelStars(level - 1);
    return (prevStars > 0);
  }

  /// Hromadně vynuluje hvězdičky pro všechny hlavní úrovně (1..totalLevels).
  /// Pozn.: V UI pak nezapomeňte ručně zajistit, aby se úroveň 1 tvářila jako odemčená.
  Future<void> resetAllLevels(int totalLevels) async {
    final prefs = await SharedPreferences.getInstance();
    for (int lv = 1; lv <= totalLevels; lv++) {
      await prefs.setInt('level_$lv', 0);
    }
  }

  // ========== Podúrovně ==========

  /// Uloží počet hvězdiček (0..3) pro podúroveň subIndex (1..5)
  /// patřící k hlavní úrovni (mainLevel).
  Future<void> setSubLevelStars(int mainLevel, int subIndex, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sub_${mainLevel}_$subIndex', stars);
  }

  /// Načte počet hvězdiček (0..3) pro podúroveň subIndex (1..5)
  /// patřící k hlavní úrovni (mainLevel).
  Future<int> getSubLevelStars(int mainLevel, int subIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sub_${mainLevel}_$subIndex') ?? 0;
  }

  /// Hromadně vynuluje všechny podúrovně (1..totalSubLevels)
  /// pro všechny hlavní úrovně (1..totalLevels).
  Future<void> resetAllSubLevels(int totalLevels, int totalSubLevels) async {
    final prefs = await SharedPreferences.getInstance();
    for (int lv = 1; lv <= totalLevels; lv++) {
      for (int sub = 1; sub <= totalSubLevels; sub++) {
        await prefs.setInt('sub_${lv}_$sub', 0);
      }
    }
  }
}

/// Správa cest k obrázkům pro hlavní úrovně a podúrovně.
class ImageLevelManager {
  static const String _basePath = 'lib/res/img';

  /// Sestaví cestu k obrázku hlavní úrovně (lX_0..lX_3 nebo lX_locked.png).
  static String levelImagePath(int level, bool isUnlocked, int stars) {
    if (!isUnlocked) {
      return '$_basePath/l${level}_locked.png';
    }
    return '$_basePath/l${level}_$stars.png';
  }

  /// Sestaví cestu k obrázku podúrovně (subX_0..subX_3 nebo subX_locked.png).
  static String subLevelImagePath(int subIndex, bool isUnlocked, int stars) {
    if (!isUnlocked) {
      return '$_basePath/sub${subIndex}_locked.png';
    }
    return '$_basePath/sub${subIndex}_$stars.png';
  }
}
