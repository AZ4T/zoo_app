// lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/details_page.dart';
import '../pages/map_page.dart';
import '../pages/settings_page.dart';
import '../providers/animal_provider.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  static const _labels = ['Home', 'Profile', 'Details', 'Map', 'Settings'];
  static const _icons  = [
    Icons.home,
    Icons.person,
    Icons.pets,
    Icons.map,
    Icons.settings,
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Details tab tapped
      final hasSelection = context.read<AnimalProvider>().selectedAnimal != null;
      if (!hasSelection) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an animal first.')),
        );
        return; // don't switch
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedAnimal = context.watch<AnimalProvider>().selectedAnimal;

    // Build a list of the five slots, with slot #2 changing if no selection
    final pages = <Widget>[
      const HomePage(),
      const ProfilePage(),

      // Details slot: either the real DetailsPage or a placeholder
      if (selectedAnimal != null)
        const DetailsPage()
      else
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No animal selected.\n\n'
              'Tap one of the items on the Home tab to view details here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),

      const MapPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: List.generate(_labels.length, (i) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: _labels[i],
          );
        }),
      ),
    );
  }
}
