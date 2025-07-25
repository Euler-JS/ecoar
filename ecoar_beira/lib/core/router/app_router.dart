import 'package:ecoar_beira/features/ar/presentation/pages/ar_experience_page.dart';
import 'package:ecoar_beira/features/ar/presentation/pages/ar_real_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Main pages imports
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/scanner/presentation/pages/scanner_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/challenges/presentation/pages/challenge_detail_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';

// Navigation
import '../../features/navigation/presentation/pages/main_navigation_page.dart';

// AR pages imports
import '../../features/ar/presentation/pages/ar_compatibility_page.dart';
import '../../features/ar/presentation/pages/ar_tutorial_page.dart';

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
      
      // AR Compatibility & Tutorial
      GoRoute(
        path: '/ar-compatibility',
        name: 'ar_compatibility',
        builder: (context, state) => const ARCompatibilityPage(),
      ),
      GoRoute(
        path: '/ar-tutorial',
        name: 'ar_tutorial',
        builder: (context, state) => const ARTutorialPage(),
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
          // return RealARExperiencePage(markerId: markerId);
          return RealARPage();
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
