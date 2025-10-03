// lib/main_tabs_screen.dart

import 'package:fasting_tracker/screens/home_screen.dart';
import 'package:fasting_tracker/screens/progress_screen.dart';
import 'package:fasting_tracker/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _selectedIndex = 0;

  // This GlobalKey is our "handle" to access the state and methods
  // of the HomeScreen widget.
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  // We use `late final` because we need to initialize this list in initState
  // to properly assign the key.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize the pages list here and assign the key to HomeScreen
    _pages = <Widget>[
      HomeScreen(key: _homeScreenKey), // Key is assigned here
      const ProgressScreen(),
      const SettingsScreen(),
    ];
  }

  // A list of titles for our AppBar, corresponding to each page
  static const List<String> _pageTitles = <String>[
    'Fasting Tracker',
    'My Progress',
    'Settings',
  ];

  // This function is called by the BottomNavigationBar when a tab is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use the key to get the current state of the HomeScreen.
    // This allows us to check if a fast is running.
    final homeState = _homeScreenKey.currentState;
    final isFasting = homeState?.isFasting ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // IndexedStack preserves the state of the screens when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // The FloatingActionButton is only shown if we are on the HomeScreen (index 0)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          // We use the key to call the public method inside HomeScreenState
          setState(() {
            homeState?.handleFastButtonPress();
          });

        },
        label: Text(isFasting ? 'End Fast' : 'Start Fast'),
        icon: Icon(isFasting ? Icons.stop : Icons.play_arrow),
        backgroundColor: const Color(0xFFE94560),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'Fast',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFE94560),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1A1A2E).withOpacity(0.9),
      ),
    );
  }
}