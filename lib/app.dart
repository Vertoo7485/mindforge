import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/finance/screens/finance_screen.dart';
import 'features/planner/screens/planner_screen.dart';
import 'features/rpg/screens/character_screen.dart';

class MindForgeApp extends StatelessWidget {
  const MindForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Forge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FinanceScreen(),
    PlannerScreen(),
    CharacterScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Финансы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Планер',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Персонаж',
          ),
        ],
      ),
    );
  }
}
