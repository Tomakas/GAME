import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/utility.dart';

/// Tato obrazovka:
/// - Načítá slova z vocabulary.json dle kategorie (mainLevel)
/// - Sub-úroveň (1..4) dělí slova na 4 segmenty podle ID (bez překryvu),
/// - Sub-úroveň 5 vezme 20 náhodných slov z celé kategorie.
/// - Po špatné odpovědi se slovo vrátí do fronty (pendingWords) a znovu se zobrazí.
/// - Písmena v letterPool se NEOPAKUJÍ (každé písmeno max. 1×), doplní se do 12 distinct.
/// - Ignorujeme koncovky -s, -es; také tolerujeme rozdíl v koncovém 'e' => "spice" vs. "spices" je OK.
/// - Po dokončení testu: 0 chyb = 3*, 1 chyba = 2*, 2+ = 1* (aspoň 1 hvězda)
/// - Ukazujeme 1s zelenou fajfku při správné odpovědi; při chybě dialog se správným slovem.
class GameScreen extends StatefulWidget {
  final int mainLevel;   // Např. 1..10
  final int subLevel;    // Např. 1..5
  final VoidCallback onGameFinished;

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

  /// Seznam všech slov dané kategorie (setříděný podle ID)
  List<Map<String,dynamic>> sortedCategoryWords = [];

  /// "Čekající" seznam slov, která ještě nebyla správně zodpovězena.
  List<Map<String,dynamic>> pendingWords = [];

  /// Aktuálně řešené slovo (z pendingWords)
  Map<String,dynamic>? currentWord;

  /// Počet chyb (špatných odpovědí)
  int mistakesCount = 0;

  bool isLoading = true;
  bool isFinished = false;

  /// Zadávané písmeno (uživatel skládá)
  String typedAnswer = "";

  /// 12 písmen (distinct)
  List<String> letterPool = [];

  /// Zda probíhá feedback => zablokujeme tlačítka
  bool inFeedback = false;

  /// Zobrazíme 1s zelenou fajfku
  bool showGreenCheck = false;

  /// Kolik slov celkem v sub-úrovni (pro zobrazení "X / total")
  int initialCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWordsAndStart();
  }

  /// 1) Načteme JSON, setřídíme podle ID, vybereme segment pro sub-level
  /// 1..4 => rozdělení bez překryvu
  /// 5 => 20 náhodných
  Future<void> _loadWordsAndStart() async {
    try {
      final dataString = await rootBundle.loadString('lib/res/vocabulary.json');
      final List<dynamic> jsonData = json.decode(dataString);

      final categoryName = _getCategoryByLevel(widget.mainLevel);

      // Filtrovat dle kategorie
      List<Map<String,dynamic>> filtered = jsonData.where((item) {
        return item['Category'] == categoryName;
      }).map((e) => e as Map<String,dynamic>).toList();

      // Seřadit dle ID (vzestupně)
      filtered.sort((a,b) {
        final idA = int.tryParse(a['ID'] ?? '0') ?? 0;
        final idB = int.tryParse(b['ID'] ?? '0') ?? 0;
        return idA.compareTo(idB);
      });

      final N = filtered.length;
      if (N == 0) {
        // Nic k zodpovězení
        setState(() {
          isLoading = false;
          isFinished = true;
        });
        return;
      }

      List<Map<String,dynamic>> chosen = [];

      if (widget.subLevel >= 1 && widget.subLevel <= 4) {
        // Nepřekrývající se segmenty => 1/4, 2/4, ...
        final startIndex = (N * (widget.subLevel - 1)) ~/ 4;
        final endIndex   = (N * widget.subLevel) ~/ 4;
        chosen = filtered.sublist(startIndex, endIndex);
        // Můžete shuffle, pokud chcete => chosen.shuffle(Random());
      } else if (widget.subLevel == 5) {
        // 20 náhodných z celé kategorie
        final howMany = min(20, N);
        chosen = _randomSample(filtered, howMany);
      }

      sortedCategoryWords = filtered; // jen pro referenci (pokud byste chtěli)
      pendingWords = List.from(chosen);
      initialCount = pendingWords.length;

      setState(() {
        isLoading = false;
      });

      _pickNextWord();
    } catch(e) {
      print('Load error: $e');
      setState(() {
        isLoading = false;
        isFinished = true;
      });
    }
  }

  /// Pomocná metoda pro sub-level => kategorie
  String _getCategoryByLevel(int lvl) {
    switch (lvl) {
      case 1:  return "Food";
      case 2:  return "Nature";
      case 3:  return "Animals";
      case 4:  return "Numbers, Colors";
      case 5:  return "Home";
      case 6:  return "Travel";
      case 7:  return "Family";
      case 8:  return "Time";
      case 9:  return "Hobbies";
      case 10: return "People";
      default: return "Food";
    }
  }

  /// Náhodný sub-seznam
  List<Map<String,dynamic>> _randomSample(List<Map<String,dynamic>> source, int count) {
    if (count >= source.length) {
      return List.from(source);
    }
    final temp = List<Map<String,dynamic>>.from(source);
    temp.shuffle(Random());
    return temp.take(count).toList();
  }

  /// Vybere další slovo z pendingWords, pokud existuje
  void _pickNextWord() {
    if (pendingWords.isEmpty) {
      _finishTest();
      return;
    }
    // Vezmeme frontu => first
    currentWord = pendingWords.first;
    typedAnswer = "";
    _prepareLettersForCurrentWord();
  }

  /// Z listu písmen (slovo) vyrobí set => neduplikovat
  /// Doplňujeme do 12 distinct písmen => letterPool
  void _prepareLettersForCurrentWord() {
    if (currentWord == null) {
      letterPool = [];
      return;
    }
    final en = (currentWord!['EN'] ?? '') as String;
    final up = en.trim().toUpperCase();

    // set písmen
    final wordSet = <String>{};
    for (var ch in up.split('')) {
      wordSet.add(ch);
    }

    var letters = wordSet.toList(); // distinct
    if (letters.length > 12) {
      letters = letters.sublist(0, 12);
    }
    // Doplň random, aby bylo 12
    while (letters.length < 12) {
      final r = _randomLetter();
      if (!letters.contains(r)) {
        letters.add(r);
      }
    }
    letters.shuffle(Random());
    letterPool = letters;
  }

  /// Náhodné písmeno [A-Z]
  String _randomLetter() {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final i = Random().nextInt(alphabet.length);
    return alphabet[i];
  }

  /// Klik na písmeno
  void _onLetterTap(String letter) {
    if (inFeedback) return;
    setState(() {
      typedAnswer += letter;
    });
  }

  /// Zpět
  void _onBackspace() {
    if (inFeedback) return;
    if (typedAnswer.isNotEmpty) {
      setState(() {
        typedAnswer = typedAnswer.substring(0, typedAnswer.length - 1);
      });
    }
  }

  /// Vymazat
  void _onClear() {
    if (inFeedback) return;
    setState(() {
      typedAnswer = "";
    });
  }

  /// Potvrdit => vyhodnocení
  void _onConfirm() {
    if (inFeedback) return;
    if (currentWord == null) return;

    final enWord = (currentWord!['EN'] ?? '') as String;
    final correct = _checkWordIgnoringPlural(typedAnswer, enWord);

    if (correct) {
      // SPRÁVNĚ => 1s fajfka => odebrat slovo z pending
      setState(() {
        inFeedback = true;
        showGreenCheck = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          showGreenCheck = false;
          inFeedback = false;
        });
        // Odebrat slovo z pending
        pendingWords.remove(currentWord);
        currentWord = null;
        _pickNextWord();
      });
    } else {
      // ŠPATNĚ => dialog => slovo se vrátí na náhodnou pozici do pending
      mistakesCount++;
      setState(() {
        inFeedback = true;
      });
      final correctAnswer = enWord.toUpperCase();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text('Špatně'),
            content: Text('Správná odpověď: $correctAnswer'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    inFeedback = false;
                  });
                  // Vrátit slovo do pending => random index
                  pendingWords.remove(currentWord);
                  final idx = Random().nextInt(pendingWords.length + 1);
                  pendingWords.insert(idx, currentWord!);
                  currentWord = null;
                  _pickNextWord();
                },
                child: const Text('OK'),
              )
            ],
          );
        },
      );
    }
  }

  /// Porovnání s ignorováním -s/-es a tolerancí koncového 'e'
  bool _checkWordIgnoringPlural(String typed, String correct) {
    String t = typed.trim().toUpperCase();
    String c = correct.trim().toUpperCase();

    t = _removePluralEndings(t);
    c = _removePluralEndings(c);

    // 1) Pokud jsou stejné, OK
    if (t == c) return true;

    // 2) Tolerovat koncové "E" => "SPIC" vs "SPICE"
    if (t.endsWith('E') && t.substring(0, t.length - 1) == c) return true;
    if (c.endsWith('E') && c.substring(0, c.length - 1) == t) return true;

    return false;
  }

  /// Odebírá -ES, -S
  String _removePluralEndings(String word) {
    if (word.endsWith("ES")) {
      // e.g. "SPICES" => "SPIC"
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith("S")) {
      // e.g. "DOGS" => "DOG"
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  /// Dokončení => hvězdy (0chyb=3,1chyb=2,>=2=1)
  Future<void> _finishTest() async {
    setState(() {
      isFinished = true;
    });
    int earnedStars;
    if (mistakesCount == 0) {
      earnedStars = 3;
    } else if (mistakesCount == 1) {
      earnedStars = 2;
    } else {
      earnedStars = 1; // min 1 hvězda
    }

    await _levelService.setSubLevelStars(widget.mainLevel, widget.subLevel, earnedStars);
    await _updateMainLevelStars();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Výsledek testu'),
          content: Text('Chyby: $mistakesCount\nZískané hvězdy: $earnedStars'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Zavřít dialog
                Navigator.of(context).pop();  // Zavřít GameScreen
                widget.onGameFinished();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  Future<void> _updateMainLevelStars() async {
    int sumStars = 0;
    for (int subIndex = 1; subIndex <= 5; subIndex++) {
      final subStars = await _levelService.getSubLevelStars(widget.mainLevel, subIndex);
      sumStars += subStars;
    }

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
    if (isFinished) {
      // test se ukončil => nic
      return Container();
    }

    if (currentWord == null && pendingWords.isNotEmpty) {
      // v pickNextWord => waiting
      return const Scaffold(body: SizedBox());
    }

    // Kolik dokončeno:
    final doneCount = initialCount - pendingWords.length;
    final totalCount = initialCount;

    final czText = (currentWord == null) ? "" : (currentWord!['CZ'] ?? "");

    return Scaffold(
      appBar: AppBar(
        title: Text('Slovo: $doneCount / $totalCount'),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ČESKÉ SLOVO - modře, uppercase
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  czText.toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // 12 distinct písmen
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,  // 4 sloupce => 3 řádky = 12
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: const EdgeInsets.all(8),
                  children: List.generate(12, (i) {
                    final letter = (letterPool.length > i) ? letterPool[i] : '#';
                    return ElevatedButton(
                      onPressed: inFeedback ? null : () => _onLetterTap(letter),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(64, 64),
                        textStyle: const TextStyle(fontSize: 24),
                      ),
                      child: Text(letter),
                    );
                  }),
                ),
              ),

              // Zobrazení typedAnswer
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  typedAnswer.toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Tlačítka dole
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: inFeedback ? null : _onBackspace,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size(64, 48),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Zpět'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: inFeedback ? null : _onClear,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(64, 48),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Vymazat'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: inFeedback ? null : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(64, 48),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Potvrdit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Overlay fajfka (1s) při správné odpovědi
          if (showGreenCheck)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 120,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
