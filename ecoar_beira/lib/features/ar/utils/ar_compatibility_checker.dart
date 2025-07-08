import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart' as arcore;
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
          reason: 'Plataforma não suportada',
          recommendations: ['Use um dispositivo Android ou iOS'],
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
    
    // Check Android version (minimum API 24)
    if (androidInfo.version.sdkInt < 24) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'Android muito antigo (mínimo: Android 7.0)',
        recommendations: ['Atualize para Android 7.0 ou superior'],
      );
    }

    // Check ARCore availability
    final isAvailable = await arcore.ArCoreController.checkArCoreAvailability();
    if (!isAvailable) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'ARCore não é suportado neste dispositivo',
        recommendations: [
          'Verifique se seu dispositivo suporta ARCore',
          'Consulte a lista de dispositivos compatíveis no Google',
        ],
      );
    }

    // Check ARCore installation
    final isInstalled = await arcore.ArCoreController.checkIsArCoreInstalled();
    if (!isInstalled) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'ARCore não está instalado',
        recommendations: [
          'Instale o ARCore da Google Play Store',
          'O app irá redirecioná-lo automaticamente',
        ],
        canInstall: true,
        installUrl: 'https://play.google.com/store/apps/details?id=com.google.ar.core',
      );
    }

    // Check device specifications
    final deviceIssues = _checkDeviceSpecs(androidInfo);
    if (deviceIssues.isNotEmpty) {
      return ARCompatibilityResult(
        isSupported: true,
        reason: 'Dispositivo compatível com limitações',
        recommendations: deviceIssues,
        hasLimitations: true,
      );
    }

    return ARCompatibilityResult(
      isSupported: true,
      reason: 'Dispositivo totalmente compatível com AR',
      recommendations: [],
    );
  }

  Future<ARCompatibilityResult> _checkIOSCompatibility() async {
    final iosInfo = await _deviceInfo.iosInfo;
    
    // Check iOS version (minimum iOS 12.0 for ARKit 3)
    final version = iosInfo.systemVersion;
    final majorVersion = int.tryParse(version.split('.').first) ?? 0;
    
    if (majorVersion < 12) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'iOS muito antigo (mínimo: iOS 12.0)',
        recommendations: ['Atualize para iOS 12.0 ou superior'],
      );
    }

    // Check device model for ARKit support
    final model = iosInfo.model;
    final isARKitSupported = _isARKitSupportedDevice(model);
    
    if (!isARKitSupported) {
      return ARCompatibilityResult(
        isSupported: false,
        reason: 'Dispositivo não suporta ARKit',
        recommendations: [
          'ARKit requer iPhone 6s ou superior',
          'iPad Pro, iPad (5ª geração) ou superior',
        ],
      );
    }

    // Check for advanced ARKit features
    final limitations = _checkARKitLimitations(model, majorVersion);
    
    return ARCompatibilityResult(
      isSupported: true,
      reason: limitations.isEmpty 
          ? 'Dispositivo totalmente compatível com AR'
          : 'Dispositivo compatível com limitações',
      recommendations: limitations,
      hasLimitations: limitations.isNotEmpty,
    );
  }

  List<String> _checkDeviceSpecs(AndroidDeviceInfo androidInfo) {
    final issues = <String>[];
    
    // Check RAM (recommend 3GB+)
    // Note: Android doesn't provide RAM info directly, so this is simplified
    if (androidInfo.version.sdkInt < 28) {
      issues.add('Dispositivos mais antigos podem ter performance limitada');
    }

    // Check for known problematic devices
    final model = androidInfo.model.toLowerCase();
    if (model.contains('go') || model.contains('lite')) {
      issues.add('Dispositivos "Go" ou "Lite" podem ter limitações de performance');
    }

    return issues;
  }

  bool _isARKitSupportedDevice(String model) {
    final supportedModels = [
      'iPhone6s', 'iPhone7', 'iPhone8', 'iPhoneX', 'iPhone11', 'iPhone12', 'iPhone13', 'iPhone14', 'iPhone15',
      'iPad', 'iPadPro', 'iPadAir', 'iPadmini',
    ];
    
    return supportedModels.any((supported) => 
        model.toLowerCase().contains(supported.toLowerCase()));
  }

  List<String> _checkARKitLimitations(String model, int iosVersion) {
    final limitations = <String>[];
    
    // Check for LiDAR support (iPhone 12 Pro+, iPad Pro 2020+)
    if (!model.contains('Pro') || iosVersion < 14) {
      limitations.add('Funcionalidades avançadas de detecção de profundidade limitadas');
    }

    // Check for older devices
    if (model.contains('6s') || model.contains('SE')) {
      limitations.add('Performance de AR pode ser limitada em dispositivos mais antigos');
    }

    return limitations;
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
    return 'ARCompatibilityResult(isSupported: $isSupported, reason: $reason)';
  }
}