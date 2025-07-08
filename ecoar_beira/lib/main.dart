import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/markers/presentation/bloc/markers_bloc.dart';
import 'features/user/presentation/bloc/user_bloc.dart';
import 'features/gamification/presentation/bloc/gamification_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize dependencies
  await initializeDependencies();
  
  // Initialize logger
  AppLogger.init();
  
  runApp(const EcoARBeiraApp());
}

class EcoARBeiraApp extends StatelessWidget {
  const EcoARBeiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<UserBloc>()),
        BlocProvider(create: (_) => getIt<MarkersBloc>()),
        BlocProvider(create: (_) => getIt<GamificationBloc>()),
      ],
      child: MaterialApp.router(
        title: 'EcoAR Beira',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // Prevent font scaling
            ),
            child: child!,
          );
        },
      ),
    );
  }
}