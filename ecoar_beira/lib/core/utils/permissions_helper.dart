import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'logger.dart';

class PermissionsHelper {
  
  /// Verifica permissão de câmera (mobile_scanner gerencia automaticamente)
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      AppLogger.i('Camera permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e, stackTrace) {
      AppLogger.e('Error checking camera permission', e, stackTrace);
      return false;
    }
  }
  
  /// Para casos onde precisa solicitar explicitamente (rare com mobile_scanner)
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      AppLogger.i('Camera permission requested: $status');
      return status == PermissionStatus.granted;
    } catch (e, stackTrace) {
      AppLogger.e('Error requesting camera permission', e, stackTrace);
      return false;
    }
  }
  
  static Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.w('Location permissions are denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        AppLogger.w('Location permissions are permanently denied');
        return false;
      }

      AppLogger.i('Location permission granted');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Error requesting location permission', e, stackTrace);
      return false;
    }
  }
  
  static Future<bool> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      AppLogger.i('Storage permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e, stackTrace) {
      AppLogger.e('Error requesting storage permission', e, stackTrace);
      return false;
    }
  }
  
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      AppLogger.i('Notification permission status: $status');
      return status == PermissionStatus.granted;
    } catch (e, stackTrace) {
      AppLogger.e('Error requesting notification permission', e, stackTrace);
      return false;
    }
  }
  
  /// Para AR e localização (câmera é gerenciada pelo mobile_scanner)
  static Future<Map<String, bool>> requestEssentialPermissions() async {
    AppLogger.i('Requesting essential permissions...');
    
    final results = await Future.wait([
      requestLocationPermission(),
      requestStoragePermission(),
      requestNotificationPermission(),
    ]);
    
    final permissionMap = {
      'location': results[0],
      'storage': results[1],
      'notification': results[2],
    };
    
    AppLogger.i('Permission results: $permissionMap');
    return permissionMap;
  }
  
  static Future<bool> hasEssentialPermissions() async {
    try {
      final location = await Geolocator.checkPermission();
      
      return location == LocationPermission.always || 
             location == LocationPermission.whileInUse;
    } catch (e, stackTrace) {
      AppLogger.e('Error checking permissions', e, stackTrace);
      return false;
    }
  }
  
  /// Para debug - verifica status de todas as permissões
  static Future<Map<String, PermissionStatus>> getAllPermissionStatus() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.location,
        Permission.storage,
        Permission.notification,
      ].request();
      
      final statusMap = {
        'camera': statuses[Permission.camera]!,
        'location': statuses[Permission.location]!,
        'storage': statuses[Permission.storage]!,
        'notification': statuses[Permission.notification]!,
      };
      
      AppLogger.i('All permission statuses: $statusMap');
      return statusMap;
    } catch (e, stackTrace) {
      AppLogger.e('Error getting all permission statuses', e, stackTrace);
      return {};
    }
  }
}