import 'package:flutter/material.dart';
import 'package:nau/screens_driver/DriverHomeScreen.dart';
import '../pages/mapa/RouteEditorScreen.dart';
import '../pages/profile_screen.dart';
import '../pages/settings_page.dart';
import '../services/auth/auth_services.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}
class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  String get currentUid => AuthService().getCurrentUid();

  List<Widget> get _screens => [
    DriverHomeScreen( uid: currentUid),
    const RouteEditorScreen(),
    PerfilScreen(uid: currentUid),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}