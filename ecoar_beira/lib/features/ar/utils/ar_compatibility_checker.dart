import 'dart:io';
import '../../../core/utils/logger.dart';

class ARCompatibilityChecker {
  static ARCompatibilityChecker? _instance;
  static ARCompatibilityChecker get instance => _instance ??= ARCompatibilityChecker._();
  ARCompatibilityChecker._();

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
    // Simplified check without device_info_plus
    return ARCompatibilityResult(
      isSupported: true,
      reason: 'Dispositivo Android compatível com AR básico',
      recommendations: [
        'Use boa iluminação para melhor experiência',
        'Certifique-se de que a câmera está funcionando'
      ],
    );
  }

  Future<ARCompatibilityResult> _checkIOSCompatibility() async {
    // Simplified check without device_info_plus
    return ARCompatibilityResult(
      isSupported: true,
      reason: 'Dispositivo iOS compatível com AR básico',
      recommendations: [
        'Use boa iluminação para melhor experiência',
        'Certifique-se de que a câmera está funcionando'
      ],
    );
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