import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'logger.dart';

class PermissionsHelper {
  
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      AppLogger.i('Camera permission status: $status');
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
  
  static Future<Map<String, bool>> requestAllPermissions() async {
    AppLogger.i('Requesting all necessary permissions...');
    
    final results = await Future.wait([
      requestCameraPermission(),
      requestLocationPermission(),
      requestStoragePermission(),
      requestNotificationPermission(),
    ]);
    
    final permissionMap = {
      'camera': results[0],
      'location': results[1],
      'storage': results[2],
      'notification': results[3],
    };
    
    AppLogger.i('Permission results: $permissionMap');
    return permissionMap;
  }
  
  static Future<bool> hasAllCriticalPermissions() async {
    try {
      final camera = await Permission.camera.isGranted;
      final location = await Geolocator.checkPermission();
      
      return camera && 
             (location == LocationPermission.always || 
              location == LocationPermission.whileInUse);
    } catch (e, stackTrace) {
      AppLogger.e('Error checking permissions', e, stackTrace);
      return false;
    }
  }
}