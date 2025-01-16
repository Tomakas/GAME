import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Vytvoříme seznam 10 položek, přičemž každá položka bude
    // ExpansionTile s 3 pododkazy
    final List<Widget> expansionTiles = List.generate(10, (index) {
      return ExpansionTile(
        title: Text('Odkaz ${index + 1}'),
        children: List.generate(6, (subIndex) {
          return ListTile(
            title: Text('Pododkaz ${subIndex + 1}'),
            onTap: () {
              // Zatím bez akce
            },
          );
        }),
      );
    });

    return Scaffold(
      // Můžeme vrátit Scaffold, pokud chceme pro GameScreen vlastní AppBar,
      // anebo jen prosté widgety. Pro ukázku použijeme Scaffold.
      appBar: AppBar(
        title: const Text('Game'),
      ),
      body: ListView(
        children: expansionTiles,
      ),
    );
  }
}
