// lib/features/navigation/presentation/pages/main_navigation_page.dart
import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationPage extends StatefulWidget {
  final Widget child;
  
  const MainNavigationPage({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final String location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/home':
        _selectedIndex = 0;
        break;
      case '/map':
        _selectedIndex = 1;
        break;
      case '/scanner':
        _selectedIndex = 2;
        break;
      case '/leaderboard':
        _selectedIndex = 3;
        break;
      case '/profile':
        _selectedIndex = 4;
        break;
      default:
        _selectedIndex = 0;
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/scanner');
        break;
      case 3:
        context.go('/leaderboard');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                size: 24,
              ),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 1 ? Icons.map : Icons.map_outlined,
                size: 24,
              ),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2 
                      ? AppTheme.primaryGreen 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIndex == 2 
                      ? Icons.qr_code_scanner 
                      : Icons.qr_code_scanner_outlined,
                  color: _selectedIndex == 2 
                      ? Colors.white 
                      : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              label: 'Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 3 ? Icons.leaderboard : Icons.leaderboard_outlined,
                size: 24,
              ),
              label: 'Ranking',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 4 ? Icons.person : Icons.person_outline,
                size: 24,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}