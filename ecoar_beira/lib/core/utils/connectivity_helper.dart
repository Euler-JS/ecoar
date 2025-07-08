import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger.dart';

class ConnectivityHelper {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static bool _isOnline = true;
  
  static bool get isOnline => _isOnline;
  
  static Stream<bool> get onConnectivityChanged => 
      _connectivity.onConnectivityChanged.map(_mapConnectivityResult);
  
  static Future<void> initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _mapConnectivityResult(result);
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (ConnectivityResult result) {
          final wasOnline = _isOnline;
          _isOnline = _mapConnectivityResult(result);
          
          if (wasOnline != _isOnline) {
            AppLogger.i('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
          }
        },
      );
      
      AppLogger.i('Connectivity helper initialized. Status: ${_isOnline ? 'Online' : 'Offline'}');
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing connectivity helper', e, stackTrace);
    }
  }
  
  static bool _mapConnectivityResult(ConnectivityResult result) {
    return result == ConnectivityResult.mobile || 
           result == ConnectivityResult.wifi ||
           result == ConnectivityResult.ethernet;
  }
  
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _mapConnectivityResult(result);
    } catch (e, stackTrace) {
      AppLogger.e('Error checking internet connection', e, stackTrace);
      return false;
    }
  }
  
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}