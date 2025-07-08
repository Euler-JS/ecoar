class AppConfig {
  static const String appName = 'EcoAR Beira';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  
  // API Configuration
  static const String baseUrl = 'https://api.ecoar-beira.com';
  static const String apiVersion = 'v1';
  static const String apiKey = 'your_api_key_here';
  
  // Features Flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDeveloperMode = false;
  static const bool enableBetaFeatures = false;
  
  // AR Configuration
  static const double markerDetectionRange = 50.0; // meters
  static const int maxCachedARScenes = 10;
  static const double arTrackingThreshold = 0.8;
  static const int arSessionTimeoutMinutes = 30;
  
  // Gamification
  static const int pointsPerMarkerScan = 50;
  static const int pointsPerQuizComplete = 100;
  static const int pointsPerChallengeComplete = 200;
  static const int pointsPerTrailComplete = 500;
  static const int pointsPerBadgeEarned = 250;
  static const int pointsPerShare = 25;
  
  // User Levels and Requirements
  static const Map<String, int> levelThresholds = {
    'iniciante': 0,
    'explorador': 500,
    'guardiaoVerde': 2000,
    'ecoHeroi': 5000,
  };
  
  // App Limits
  static const int maxOfflineMarkers = 50;
  static const int maxCachedImages = 100;
  static const double maxImageSizeMB = 5.0;
  static const int sessionTimeoutMinutes = 60;
  
  // Location Settings
  static const double defaultLatitude = -19.8437; // Beira, Mozambique
  static const double defaultLongitude = 34.8389;
  static const double defaultZoom = 14.0;
  static const double nearbyRadiusKm = 5.0;
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Notification Settings
  static const bool enablePushNotifications = true;
  static const bool enableLocationReminders = true;
  static const bool enableAchievementNotifications = true;
  
  // Environment-specific configurations
  static bool get isProduction => const bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static bool get isDebug => !isProduction;
  
  // Helper methods
  static String get fullApiUrl => '$baseUrl/api/$apiVersion';
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $apiKey',
    'X-App-Version': appVersion,
  };
  
  static Duration get networkTimeout => const Duration(seconds: 30);
  
  static String getLevelDisplayName(String level) {
    switch (level) {
      case 'iniciante':
        return 'Iniciante';
      case 'explorador':
        return 'Explorador';
      case 'guardiaoVerde':
        return 'Guardião Verde';
      case 'ecoHeroi':
        return 'Eco Herói';
      default:
        return 'Usuário';
    }
  }
  
  static String getMarkerTypeDisplayName(String type) {
    switch (type) {
      case 'biodiversidade':
        return 'Biodiversidade';
      case 'recursos_hidricos':
        return 'Recursos Hídricos';
      case 'agricultura_urbana':
        return 'Agricultura Urbana';
      default:
        return 'Geral';
    }
  }
}