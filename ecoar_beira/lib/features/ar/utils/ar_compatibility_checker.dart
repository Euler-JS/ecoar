import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../core/utils/logger.dart';

class ARCompatibilityChecker {
  static ARCompatibilityChecker? _instance;
  static ARCompatibilityChecker get instance => _instance ??= ARCompatibilityChecker._();
  ARCompatibilityChecker._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<ARCompatibilityResult> checkCompatibility() async {
    try {
      AppLogger.i('Checking AR compatibility...');

      if (Platform.isAndroid) {
        return await _checkAndroidCompatibility();
      } else if (Platform.isIOS) {
        return await _checkIOSCompatibility();
      } else {
        return ARCompatibilityResult(
          isSupported: false,
          reason: 'Plataforma não suportada para AR',
          recommendations: [
            'Use um dispositivo Android (API 24+) ou iOS (12.0+)',
            'Verifique se seu dispositivo suporta ARCore ou ARKit'
          ],
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error checking AR compatibility', e, stackTrace);
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'Erro ao verificar compatibilidade: ${e.toString()}',
        recommendations: ['Tente novamente mais tarde'],
      );
    }
  }

  Future<ARCompatibilityResult> _checkAndroidCompatibility() async {
    final androidInfo = await _deviceInfo.androidInfo;
    
    // Check Android version (minimum API 24 for ARCore)
    if (androidInfo.version.sdkInt < 24) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'Android muito antigo (mínimo: Android 7.0 - API 24)',
        recommendations: [
          'Atualize para Android 7.0 ou superior',
          'ARCore requer no mínimo Android 7.0'
        ],
      );
    }

    // Check for OpenGL ES support
    if (androidInfo.version.sdkInt < 26) {
      return ARCompatibilityResult(
        isSupported: true,
        reason: 'Dispositivo compatível com limitações de performance',
        recommendations: [
          'Dispositivos Android 7.0-7.1 podem ter performance limitada',
          'Para melhor experiência, use Android 8.0 ou superior'
        ],
        hasLimitations: true,
      );
    }

    // Check device specifications and known compatibility issues
    final deviceIssues = _checkAndroidDeviceSpecs(androidInfo);
    if (deviceIssues.isNotEmpty) {
      return ARCompatibilityResult(
        isSupported: true,
        reason: 'Dispositivo compatível com algumas limitações',
        recommendations: deviceIssues,
        hasLimitations: true,
      );
    }

    // Check for devices known to have AR issues
    final knownIssues = _checkKnownAndroidIssues(androidInfo);
    if (knownIssues.isNotEmpty) {
      return ARCompatibilityResult(
        isSupported: true,
        reason: 'Dispositivo compatível mas pode ter limitações específicas',
        recommendations: knownIssues,
        hasLimitations: true,
      );
    }

    return ARCompatibilityResult(
      isSupported: true,
      reason: 'Dispositivo totalmente compatível com AR',
      recommendations: [
        'Seu dispositivo suporta todas as funcionalidades AR',
        'Para melhor experiência, use boa iluminação'
      ],
    );
  }

  Future<ARCompatibilityResult> _checkIOSCompatibility() async {
    final iosInfo = await _deviceInfo.iosInfo;
    
    // Check iOS version (minimum iOS 12.0 for ARKit 3)
    final version = iosInfo.systemVersion;
    final versionParts = version.split('.').map(int.tryParse).toList();
    final majorVersion = versionParts.isNotEmpty ? (versionParts[0] ?? 0) : 0;
    final minorVersion = versionParts.length > 1 ? (versionParts[1] ?? 0) : 0;
    
    if (majorVersion < 12) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'iOS muito antigo (mínimo: iOS 12.0)',
        recommendations: [
          'Atualize para iOS 12.0 ou superior',
          'ARKit requer no mínimo iOS 12.0'
        ],
      );
    }

    // Check device model for ARKit support
    final model = iosInfo.model;
    final deviceSupport = _checkIOSDeviceSupport(model);
    
    if (!deviceSupport.isSupported) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'Dispositivo não suporta ARKit',
        recommendations: [
          'ARKit requer iPhone 6s ou superior',
          'iPad Pro, iPad (5ª geração) ou iPad Air (3ª geração) ou superior'
        ],
      );
    }

    // Check for advanced features and limitations
    final limitations = _checkARKitLimitations(model, majorVersion, minorVersion);
    final recommendations = _getIOSRecommendations(model, majorVersion);

    return ARCompatibilityResult(
      isSupported: true,
      reason: limitations.isEmpty 
          ? 'Dispositivo totalmente compatível com AR'
          : 'Dispositivo compatível com algumas limitações',
      recommendations: [...limitations, ...recommendations],
      hasLimitations: limitations.isNotEmpty,
    );
  }

  List<String> _checkAndroidDeviceSpecs(AndroidDeviceInfo androidInfo) {
    final issues = <String>[];
    
    // Check for low-end device indicators
    final model = androidInfo.model.toLowerCase();
    final manufacturer = androidInfo.manufacturer.toLowerCase();
    
    // Check for "Go" edition devices
    if (model.contains('go') || model.contains('lite') || model.contains('mini')) {
      issues.add('Dispositivos "Go", "Lite" ou "Mini" podem ter performance limitada');
    }

    // Check for devices with limited RAM (inferred from model names)
    if (model.contains('1gb') || model.contains('2gb')) {
      issues.add('Dispositivos com pouca RAM podem ter dificuldade com AR');
    }

    // Check Android version for performance optimization
    if (androidInfo.version.sdkInt < 28) {
      issues.add('Android mais antigo pode ter performance de AR reduzida');
    }

    // Check for specific problematic manufacturers/models
    if (manufacturer == 'amazon' && model.contains('fire')) {
      issues.add('Tablets Amazon Fire podem não ter suporte completo a ARCore');
    }

    return issues;
  }

  List<String> _checkKnownAndroidIssues(AndroidDeviceInfo androidInfo) {
    final issues = <String>[];
    final model = androidInfo.model.toLowerCase();
    final manufacturer = androidInfo.manufacturer.toLowerCase();

    // Specific device issues
    if (manufacturer == 'samsung' && model.contains('j')) {
      issues.add('Série Samsung Galaxy J pode ter limitações de performance');
    }

    if (manufacturer == 'huawei' && androidInfo.version.sdkInt < 28) {
      issues.add('Dispositivos Huawei mais antigos podem ter problemas com câmera AR');
    }

    if (manufacturer == 'xiaomi' && model.contains('redmi')) {
      issues.add('Alguns dispositivos Redmi podem precisar ajustar configurações de câmera');
    }

    return issues;
  }

  IOSDeviceSupport _checkIOSDeviceSupport(String model) {
    final modelLower = model.toLowerCase();
    
    // Supported iPhone models (iPhone 6s and newer)
    final supportedPhones = [
      'iphone6s', 'iphone7', 'iphone8', 'iphonex', 'iphone11', 
      'iphone12', 'iphone13', 'iphone14', 'iphone15', 'iphonese'
    ];
    
    // Supported iPad models
    final supportedTablets = [
      'ipadpro', 'ipadair', 'ipadmini'
    ];

    // Check iPhone support
    for (final phone in supportedPhones) {
      if (modelLower.contains(phone)) {
        return IOSDeviceSupport(isSupported: true, deviceType: 'iPhone');
      }
    }

    // Check iPad support (more restrictive)
    if (modelLower.contains('ipadpro')) {
      return IOSDeviceSupport(isSupported: true, deviceType: 'iPad Pro');
    }
    
    if (modelLower.contains('ipadair')) {
      return IOSDeviceSupport(isSupported: true, deviceType: 'iPad Air');
    }
    
    if (modelLower.contains('ipadmini') && !modelLower.contains('mini1') && !modelLower.contains('mini2')) {
      return IOSDeviceSupport(isSupported: true, deviceType: 'iPad Mini');
    }
    
    if (modelLower.contains('ipad') && !modelLower.contains('ipad1') && !modelLower.contains('ipad2') && !modelLower.contains('ipad3') && !modelLower.contains('ipad4')) {
      return IOSDeviceSupport(isSupported: true, deviceType: 'iPad');
    }

    return IOSDeviceSupport(isSupported: false, deviceType: 'Unsupported');
  }

  List<String> _checkARKitLimitations(String model, int majorVersion, int minorVersion) {
    final limitations = <String>[];
    final modelLower = model.toLowerCase();
    
    // Check for LiDAR support (iPhone 12 Pro+, iPad Pro 2020+)
    if (!modelLower.contains('pro') || majorVersion < 14) {
      limitations.add('Funcionalidades avançadas de detecção de profundidade limitadas (sem LiDAR)');
    }

    // Check for older devices with performance limitations
    if (modelLower.contains('6s') || modelLower.contains('se')) {
      limitations.add('Performance de AR pode ser limitada em dispositivos mais antigos');
    }

    // Check for specific iPad limitations
    if (modelLower.contains('ipadmini') && majorVersion < 14) {
      limitations.add('iPad Mini mais antigos podem ter limitações de performance AR');
    }

    // iOS version specific limitations
    if (majorVersion == 12 || (majorVersion == 13 && minorVersion < 3)) {
      limitations.add('Versões mais antigas do iOS podem ter funcionalidades AR limitadas');
    }

    return limitations;
  }

  List<String> _getIOSRecommendations(String model, int majorVersion) {
    final recommendations = <String>[];
    
    // General recommendations
    recommendations.add('Use boa iluminação para melhor tracking AR');
    
    if (majorVersion >= 14) {
      recommendations.add('Seu dispositivo suporta as funcionalidades AR mais recentes');
    }
    
    if (model.toLowerCase().contains('pro')) {
      recommendations.add('Dispositivo Pro oferece a melhor experiência AR disponível');
    }

    return recommendations;
  }
}

class ARCompatibilityResult {
  final bool isSupported;
  final String reason;
  final List<String> recommendations;
  final bool hasLimitations;
  final bool canInstall;
  final String? installUrl;

  ARCompatibilityResult({
    required this.isSupported,
    required this.reason,
    required this.recommendations,
    this.hasLimitations = false,
    this.canInstall = false,
    this.installUrl,
  });

  @override
  String toString() {
    return 'ARCompatibilityResult(isSupported: $isSupported, reason: $reason, hasLimitations: $hasLimitations)';
  }
}

class IOSDeviceSupport {
  final bool isSupported;
  final String deviceType;

  IOSDeviceSupport({
    required this.isSupported,
    required this.deviceType,
  });
}