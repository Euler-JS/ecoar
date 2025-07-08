class AppConstants {
  // Routes
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String mapRoute = '/map';
  static const String scannerRoute = '/scanner';
  static const String profileRoute = '/profile';
  static const String leaderboardRoute = '/leaderboard';
  static const String arExperienceRoute = '/ar';
  static const String challengeDetailRoute = '/challenge';
  
  // Marker Types
  static const String biodiversidadeType = 'biodiversidade';
  static const String recursosHidricosType = 'recursos_hidricos';
  static const String agriculturaUrbanaType = 'agricultura_urbana';
  
  // User Levels
  static const String inicianteLevel = 'iniciante';
  static const String exploradorLevel = 'explorador';
  static const String guardiaoVerdeLevel = 'guardiaoVerde';
  static const String ecoHeroiLevel = 'ecoHeroi';
  
  // Badge IDs
  static const String descobridorBadge = 'descobridor';
  static const String cientistaBadge = 'cientista';
  static const String ecoWarriorBadge = 'eco_warrior';
  static const String influencerBadge = 'influencer';
  static const String mestreBadge = 'mestre';
  
  // Challenge Types
  static const String quizChallenge = 'quiz';
  static const String identificationChallenge = 'identification';
  static const String simulationChallenge = 'simulation';
  static const String treasureHuntChallenge = 'treasure_hunt';
  
  // Shared Preferences Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String selectedLanguageKey = 'selected_language';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String soundEffectsEnabledKey = 'sound_effects_enabled';
  static const String lastLocationKey = 'last_location';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String userProfileEndpoint = '/user/profile';
  static const String markersEndpoint = '/markers';
  static const String challengesEndpoint = '/challenges';
  static const String leaderboardEndpoint = '/leaderboard';
  static const String badgesEndpoint = '/badges';
  
  // Error Messages
  static const String networkErrorMessage = 'Erro de conexão. Verifique sua internet';
  static const String unknownErrorMessage = 'Erro desconhecido. Tente novamente';
  static const String authErrorMessage = 'Erro de autenticação. Faça login novamente';
  static const String permissionDeniedMessage = 'Permissão negada';
  static const String locationDisabledMessage = 'Serviços de localização desabilitados';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login realizado com sucesso!';
  static const String registerSuccessMessage = 'Conta criada com sucesso!';
  static const String profileUpdatedMessage = 'Perfil atualizado com sucesso!';
  static const String markerScannedMessage = 'Marcador escaneado com sucesso!';
  static const String challengeCompletedMessage = 'Desafio completado!';
  static const String badgeEarnedMessage = 'Badge conquistado!';
  
  // Time Constants
  static const int splashDuration = 3; // seconds
  static const int animationDuration = 300; // milliseconds
  static const int debounceTime = 500; // milliseconds
  static const int cacheExpiration = 24; // hours
  
  // File Types
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedVideoTypes = ['mp4', 'mov', 'avi'];
  
  // Limits
  static const int maxFileUploadSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageUploadSize = 5 * 1024 * 1024; // 5MB
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 150;
  static const int maxCommentLength = 500;
  
  // URLs
  static const String privacyPolicyUrl = 'https://ecoar-beira.app/privacy';
  static const String termsOfUseUrl = 'https://ecoar-beira.app/terms';
  static const String supportEmailUrl = 'mailto:support@ecoar-beira.app';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.ecoar.beira';
  static const String appStoreUrl = 'https://apps.apple.com/app/ecoar-beira/id123456789';
}