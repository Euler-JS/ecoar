import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/user/presentation/bloc/user_bloc.dart';
import '../../features/markers/presentation/bloc/markers_bloc.dart';
import '../../features/gamification/presentation/bloc/gamification_bloc.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  AppLogger.i('Initializing dependencies...');
  
  // External Dependencies
  _registerExternalDependencies();
  
  // Core Services
  await _registerCoreServices();
  
  // Data Sources
  _registerDataSources();
  
  // Repositories
  _registerRepositories();
  
  // Use Cases
  _registerUseCases();
  
  // BLoCs
  _registerBlocs();
  
  AppLogger.i('Dependencies initialized successfully');
}

void _registerExternalDependencies() {
  // HTTP Client
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    
    dio.options.baseUrl = AppConfig.fullApiUrl;
    dio.options.connectTimeout = AppConfig.networkTimeout;
    dio.options.receiveTimeout = AppConfig.networkTimeout;
    dio.options.headers.addAll(AppConfig.defaultHeaders);
    
    if (AppConfig.isDebug) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => AppLogger.d('HTTP: $object'),
      ));
    }
    
    return dio;
  });
  
  // Connectivity
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
}

Future<void> _registerCoreServices() async {
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive Adapters (when models are generated)
  // Hive.registerAdapter(UserModelAdapter());
  // Hive.registerAdapter(MarkerModelAdapter());
  // etc.
  
  // Open Hive Boxes
  await _openHiveBoxes();
  
  // Register boxes as singletons
  getIt.registerLazySingleton<Box>(() => Hive.box('user'), instanceName: 'userBox');
  getIt.registerLazySingleton<Box>(() => Hive.box('markers'), instanceName: 'markersBox');
  getIt.registerLazySingleton<Box>(() => Hive.box('challenges'), instanceName: 'challengesBox');
  getIt.registerLazySingleton<Box>(() => Hive.box('settings'), instanceName: 'settingsBox');
  getIt.registerLazySingleton<Box>(() => Hive.box('cache'), instanceName: 'cacheBox');
}

Future<void> _openHiveBoxes() async {
  try {
    await Future.wait([
      Hive.openBox('user'),
      Hive.openBox('markers'),
      Hive.openBox('challenges'),
      Hive.openBox('settings'),
      Hive.openBox('cache'),
    ]);
    AppLogger.i('Hive boxes opened successfully');
  } catch (e, stackTrace) {
    AppLogger.e('Error opening Hive boxes', e, stackTrace);
    rethrow;
  }
}

void _registerDataSources() {
  // Local Data Sources
  // getIt.registerLazySingleton<UserLocalDataSource>(
  //   () => UserLocalDataSourceImpl(userBox: getIt(instanceName: 'userBox')),
  // );
  
  // Remote Data Sources
  // getIt.registerLazySingleton<UserRemoteDataSource>(
  //   () => UserRemoteDataSourceImpl(client: getIt<Dio>()),
  // );
  
  AppLogger.i('Data sources registered');
}

void _registerRepositories() {
  // Repositories
  // getIt.registerLazySingleton<UserRepository>(
  //   () => UserRepositoryImpl(
  //     localDataSource: getIt<UserLocalDataSource>(),
  //     remoteDataSource: getIt<UserRemoteDataSource>(),
  //     connectivity: getIt<Connectivity>(),
  //   ),
  // );
  
  AppLogger.i('Repositories registered');
}

void _registerUseCases() {
  // Use Cases
  // getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  // getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  // getIt.registerLazySingleton(() => GetUserProfileUseCase(getIt<UserRepository>()));
  
  AppLogger.i('Use cases registered');
}

void _registerBlocs() {
  // BLoCs
  getIt.registerFactory<AuthBloc>(() => AuthBloc());
  getIt.registerFactory<UserBloc>(() => UserBloc());
  getIt.registerFactory<MarkersBloc>(() => MarkersBloc());
  getIt.registerFactory<GamificationBloc>(() => GamificationBloc());
  
  AppLogger.i('BLoCs registered');
}

// Helper function to clear all dependencies (useful for testing)
Future<void> clearDependencies() async {
  await getIt.reset();
  await Hive.close();
}