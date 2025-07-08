import 'dart:async';
import '../../../core/utils/logger.dart';

class ARPerformanceMonitor {
  static ARPerformanceMonitor? _instance;
  static ARPerformanceMonitor get instance => _instance ??= ARPerformanceMonitor._();
  ARPerformanceMonitor._();

  final StreamController<ARPerformanceMetrics> _metricsController = 
      StreamController<ARPerformanceMetrics>.broadcast();

  Stream<ARPerformanceMetrics> get metricsStream => _metricsController.stream;

  Timer? _monitoringTimer;
  DateTime? _sessionStartTime;
  int _frameCount = 0;
  double _currentFPS = 0.0;
  final List<double> _fpsHistory = [];
  
  void startMonitoring() {
    if (_monitoringTimer != null) return;
    
    AppLogger.i('Starting AR performance monitoring');
    _sessionStartTime = DateTime.now();
    _frameCount = 0;
    _fpsHistory.clear();
    
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateMetrics();
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      AppLogger.i('AR session ended. Duration: ${sessionDuration.inSeconds}s, Average FPS: ${_getAverageFPS().toStringAsFixed(1)}');
    }
  }

  void recordFrame() {
    _frameCount++;
  }

  void _updateMetrics() {
    _currentFPS = _frameCount.toDouble();
    _frameCount = 0;
    
    _fpsHistory.add(_currentFPS);
    if (_fpsHistory.length > 60) { // Keep last 60 seconds
      _fpsHistory.removeAt(0);
    }

    final metrics = ARPerformanceMetrics(
      currentFPS: _currentFPS,
      averageFPS: _getAverageFPS(),
      minFPS: _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce((a, b) => a < b ? a : b),
      maxFPS: _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce((a, b) => a > b ? a : b),
      sessionDuration: _sessionStartTime != null 
          ? DateTime.now().difference(_sessionStartTime!)
          : Duration.zero,
      performanceLevel: _getPerformanceLevel(),
    );

    _metricsController.add(metrics);

    // Log performance warnings
    if (_currentFPS < 20) {
      AppLogger.w('Low FPS detected: ${_currentFPS.toStringAsFixed(1)}');
    }
  }

  double _getAverageFPS() {
    if (_fpsHistory.isEmpty) return 0.0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }

  ARPerformanceLevel _getPerformanceLevel() {
    final avgFPS = _getAverageFPS();
    if (avgFPS >= 50) return ARPerformanceLevel.excellent;
    if (avgFPS >= 30) return ARPerformanceLevel.good;
    if (avgFPS >= 20) return ARPerformanceLevel.fair;
    return ARPerformanceLevel.poor;
  }

  void dispose() {
    stopMonitoring();
    _metricsController.close();
  }
}

class ARPerformanceMetrics {
  final double currentFPS;
  final double averageFPS;
  final double minFPS;
  final double maxFPS;
  final Duration sessionDuration;
  final ARPerformanceLevel performanceLevel;

  ARPerformanceMetrics({
    required this.currentFPS,
    required this.averageFPS,
    required this.minFPS,
    required this.maxFPS,
    required this.sessionDuration,
    required this.performanceLevel,
  });

  @override
  String toString() {
    return 'ARPerformanceMetrics(currentFPS: ${currentFPS.toStringAsFixed(1)}, '
           'averageFPS: ${averageFPS.toStringAsFixed(1)}, '
           'level: $performanceLevel)';
  }
}

enum ARPerformanceLevel {
  excellent,
  good,
  fair,
  poor,
}