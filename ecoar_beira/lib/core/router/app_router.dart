// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/ar/presentation/pages/ar_experience_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/challenges/presentation/pages/challenge_detail_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash & Onboarding
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      
      // Authentication
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main App with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationPage(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapPage(),
          ),
          GoRoute(
            path: '/scanner',
            name: 'scanner',
            builder: (context, state) => const ScannerPage(),
          ),
          GoRoute(
            path: '/leaderboard',
            name: 'leaderboard',
            builder: (context, state) => const LeaderboardPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      
      // AR Experience (Full Screen)
      GoRoute(
        path: '/ar/:markerId',
        name: 'ar_experience',
        builder: (context, state) {
          final markerId = state.pathParameters['markerId']!;
          return ARExperiencePage(markerId: markerId);
        },
      ),
      
      // Challenge Detail
      GoRoute(
        path: '/challenge/:challengeId',
        name: 'challenge_detail',
        builder: (context, state) {
          final challengeId = state.pathParameters['challengeId']!;
          return ChallengeDetailPage(challengeId: challengeId);
        },
      ),
    ],
  );
}

// lib/features/navigation/presentation/pages/main_navigation_page.dart
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('map');
        break;
      case 2:
        context.goNamed('scanner');
        break;
      case 3:
        context.goNamed('leaderboard');
        break;
      case 4:
        context.goNamed('profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}