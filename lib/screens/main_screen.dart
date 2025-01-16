import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'goals_screen.dart';
import 'practise_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Hlavní obrazovka aplikace, která obsahuje spodní navigační lištu
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Seznam widgetů, které se budou zobrazovat v závislosti na tlačítku
  static final List<Widget> _pages = [
    const GameScreen(),
    const GoalsScreen(),
    const PractiseScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tělo aplikace se mění podle indexu vybraného v navigaci
      body: _pages[_selectedIndex],

      // Spodní lišta s 5 tlačítky (větší ikony, každá jiná barva)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset, size: 32.0, color: Colors.blue),
            label: '', // Bez textu
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag, size: 32.0, color: Colors.green),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school, size: 32.0, color: Colors.orange),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 32.0, color: Colors.purple),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 32.0, color: Colors.red),
            label: '',
          ),
        ],
      ),
    );
  }
}
