import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // pro rootBundle.loadString
import '../services/utility.dart';

/// Tato obrazovka provádí testování slovíček podle vybrané úrovně
/// a sub-úrovně:
/// - Úroveň 1 => kategorie "Food"
/// - Sub-úroveň 1–4 => testujeme jen 1/4 slov z dané kategorie
/// - Sub-úroveň 5 => testujeme všechna slova z dané kategorie
///
/// Po dokončení testu a určení počtu chyb se podle tabulky
/// (0 chyb = 3 hvězdy, 1 chyba = 2 hvězdy, 2 chyby = 1 hvězda, jinak 0)
/// nastaví hvězdy v sub-úrovni.
class GameScreen extends StatefulWidget {
  final int mainLevel;     // 1..10
  final int subLevel;      // 1..5
  final VoidCallback onGameFinished;
  // Callback, abychom se mohli po skončení vrátit a zaktualizovat UI v SubLevelsScreen

  const GameScreen({
    Key? key,
    required this.mainLevel,
    required this.subLevel,
    required this.onGameFinished,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final LevelStateService _levelService = LevelStateService();

  List<Map<String, dynamic>> allWords = [];
  List<Map<String, dynamic>> selectedWords = [];

  int currentIndex = 0;    // index právě testovaného slovíčka
  int mistakesCount = 0;   // počet chyb

  bool isLoading = true;
  bool isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadWordsAndStart();
  }

  /// 1) Načteme JSON (vocabulary.json) a vybereme příslušnou kategorii
  Future<void> _loadWordsAndStart() async {
    try {
      final dataString = await rootBundle.loadString('lib/res/vocabulary.json');
      final List<dynamic> jsonData = json.decode(dataString);

      // Zde určete kategorii podle mainLevelu:
      // V zadání: "Téma pro úroveň jedna je 'Food'."
      // Pokud byste měli pro level 2 "Nature" atd., definujte si mapování:
      String categoryName = _getCategoryByLevel(widget.mainLevel);

      // Filtrovat slova z JSON, která mají "Category": categoryName
      allWords = jsonData.where((item) {
        return item['Category'] == categoryName;
      }).map((e) => e as Map<String,dynamic>).toList();

      // Rozhodnout, kolik slov z kategorie vybereme:
      // subLevel 1-4 => 1/4 slov, subLevel 5 => všechna slova
      int total = allWords.length;
      if (widget.subLevel >= 1 && widget.subLevel <= 4) {
        // Čtvrtinu
        int quarterCount = (total / 4).ceil();
        // Vybereme náhodně quarterCount z allWords
        selectedWords = _randomSample(allWords, quarterCount);
      } else {
        // subLevel = 5 => všechna slova
        selectedWords = List.from(allWords);
      }

      // Můžeme dále shuffle(nout) selectedWords, aby byly pokaždé v jiném pořadí
      selectedWords.shuffle(Random());

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      // Ošetřit chybu
      print('Chyba při načítání JSON: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Pomocná metoda pro mapování mainLevel -> kategorie
  String _getCategoryByLevel(int mainLevel) {
    // Zde si vytvořte vlastní mapování
    // Např. level 1 => "Food", level 2 => "Nature", atd.
    // V zadání je uvedeno "Pro level 1 => 'Food'".
    // V reálném projektu byste to mohli mít v nějaké konfigurační tabulce.
    switch (mainLevel) {
      case 1: return "Food";
      case 2: return "Nature";
      case 3: return "Animals";
      case 4: return "Numbers, Colors";
      case 5: return "Home";
      case 6: return "Travel";
      case 7: return "Family";
      case 8: return "Time";
      case 9: return "Hobbies";
      case 10: return "People";
      default: return "Food";
    }
  }

  /// Metoda pro náhodný výběr 'count' prvků ze seznamu
  List<Map<String,dynamic>> _randomSample(
      List<Map<String,dynamic>> source,
      int count,
      ) {
    if (count >= source.length) {
      return List.from(source);
    }
    // Kopii pro shuffle
    final tempList = List<Map<String,dynamic>>.from(source);
    tempList.shuffle(Random());
    return tempList.take(count).toList();
  }

  /// 2) Logika pro kliknutí na tlačítko "Správně" / "Chybně"
  /// (zjednodušená simulace testu)
  void _answerQuestion(bool wasCorrect) {
    if (!wasCorrect) {
      mistakesCount++;
    }
    // Posun na další slovo
    if (currentIndex < selectedWords.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      // Dokončeno
      _finishTest();
    }
  }

  /// 3) Dokončení testu => vyhodnotíme počet hvězd, uložíme do sub-levelu
  Future<void> _finishTest() async {
    setState(() {
      isFinished = true;
    });

    // Podle počtu chyb
    int earnedStars = 0;
    if (mistakesCount == 0) {
      earnedStars = 3;
    } else if (mistakesCount == 1) {
      earnedStars = 2;
    } else if (mistakesCount == 2) {
      earnedStars = 1;
    } else {
      earnedStars = 0;
    }

    // Uložit hvězdy do sub-levelu
    await _levelService.setSubLevelStars(widget.mainLevel, widget.subLevel, earnedStars);

    // Přepočítat hvězdy hlavní úrovně (analogicky jako v SubLevelsScreen)
    await _updateMainLevelStars();

    // Po dokončení můžeme zobrazit dialog nebo rovnou volat callback,
    // a pak se Navigator.pop() do sub-levels screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Výsledky testu'),
          content: Text(
            'Chyby: $mistakesCount\n'
                'Získané hvězdy: $earnedStars',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Vrátit se do SubLevelsScreen
                Navigator.of(context).pop();
                // Zavolat callback
                widget.onGameFinished();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  /// Přepočet hvězd hlavní úrovně podle součtu hvězd sub-úrovní (0..15)
  Future<void> _updateMainLevelStars() async {
    // Sečteme hvězdy všech sub-levelů
    int sumStars = 0;
    for (int subIndex = 1; subIndex <= 5; subIndex++) {
      int subStars = await _levelService.getSubLevelStars(widget.mainLevel, subIndex);
      sumStars += subStars;
    }
    // sumStars = 0..15 => mapování 0–4 -> 0, 5–9 -> 1, 10–14 -> 2, 15 -> 3
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

    await _levelService.setLevelStars(widget.mainLevel, mainLevelStars);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (selectedWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Test slovíček'),
        ),
        body: const Center(
          child: Text('V této kategorii nejsou k dispozici žádná slovíčka.'),
        ),
      );
    }

    if (isFinished) {
      // Po dokončení testu (zde můžeme zobrazit nějakou "Gratulaci"
      // nebo jsme to už vyřešili AlertDialogem v _finishTest())
      return Container();
    }

    // Získáme právě testované slovíčko
    final currentWord = selectedWords[currentIndex];
    final enWord = currentWord['EN'] ?? '(??)';
    final czWord = currentWord['CZ'] ?? '(??)';

    return Scaffold(
      appBar: AppBar(
        title: Text('Test (sub-level ${widget.subLevel})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Otázka ${currentIndex + 1} / ${selectedWords.length}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              // Např. zobrazíme EN slovo a uživatel má říci, co je to česky
              'Anglické slovíčko: $enWord\n\n'
                  'Jak se řekne česky?',
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Zjednodušeně: uživatel řekne, zda "odpověděl správně" nebo "špatně"
            // V reálné aplikaci byste měli textfield, multiple choice, apod.
            ElevatedButton.icon(
              onPressed: () => _answerQuestion(false),
              icon: const Icon(Icons.close),
              label: const Text('Chybně'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _answerQuestion(true),
              icon: const Icon(Icons.check),
              label: const Text('Správně'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),

            const Spacer(),

            // Pro informaci zobrazíme i "CZ" slovíčko
            // (v reálném kvízu by to bylo až po vyhodnocení)
            Text(
              'Správná odpověď: $czWord',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
