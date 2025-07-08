import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/utils/logger.dart';

class ARAssetManager {
  static ARAssetManager? _instance;
  static ARAssetManager get instance => _instance ??= ARAssetManager._();
  ARAssetManager._();

  static const String _cacheDirectory = 'ar_assets';
  final Map<String, String> _cachedAssets = {};

  Future<String?> loadARModel(String assetPath) async {
    try {
      AppLogger.d('Loading AR model: $assetPath');

      // Check if already cached
      if (_cachedAssets.containsKey(assetPath)) {
        final cachedPath = _cachedAssets[assetPath]!;
        if (await File(cachedPath).exists()) {
          return cachedPath;
        }
      }

      // Load from assets and cache
      final cacheDir = await _getCacheDirectory();
      final fileName = path.basename(assetPath);
      final cachedFilePath = path.join(cacheDir.path, fileName);

      // Copy from assets to cache
      final byteData = await rootBundle.load(assetPath);
      final file = File(cachedFilePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      _cachedAssets[assetPath] = cachedFilePath;
      AppLogger.d('AR model cached: $cachedFilePath');

      return cachedFilePath;
    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR model: $assetPath', e, stackTrace);
      return null;
    }
  }

  Future<Uint8List?> loadTexture(String assetPath) async {
    try {
      AppLogger.d('Loading texture: $assetPath');
      
      if (assetPath.startsWith('assets/')) {
        final byteData = await rootBundle.load(assetPath);
        return byteData.buffer.asUint8List();
      } else {
        final file = File(assetPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('Error loading texture: $assetPath', e, stackTrace);
      return null;
    }
  }

  Future<String?> downloadAndCacheModel(String url, String fileName) async {
    try {
      AppLogger.d('Downloading AR model: $url');

      final cacheDir = await _getCacheDirectory();
      final cachedFilePath = path.join(cacheDir.path, fileName);

      // Check if already exists
      if (await File(cachedFilePath).exists()) {
        return cachedFilePath;
      }

      // Download and cache
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final file = File(cachedFilePath);
        await response.pipe(file.openWrite());
        
        _cachedAssets[url] = cachedFilePath;
        AppLogger.d('AR model downloaded and cached: $cachedFilePath');
        
        return cachedFilePath;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error downloading AR model: $url', e, stackTrace);
      return null;
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationCacheDirectory();
    final cacheDir = Directory(path.join(appDir.path, _cacheDirectory));
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      _cachedAssets.clear();
      AppLogger.d('AR asset cache cleared');
    } catch (e, stackTrace) {
      AppLogger.e('Error clearing AR cache', e, stackTrace);
    }
  }

  Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      AppLogger.e('Error calculating cache size', e);
      return 0;
    }
  }

  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}