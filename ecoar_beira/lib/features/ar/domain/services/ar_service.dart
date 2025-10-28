import 'dart:async';
import 'package:ecoar_beira/core/models/ar_object_model.dart';
import 'package:ecoar_beira/core/models/ar_scene_model.dart';
import 'package:ecoar_beira/core/utils/logger.dart';

class ARService {
  static ARService? _instance;
  static ARService get instance => _instance ??= ARService._();

  ARService._();

  // Temporariamente desabilitado - funcionalidade AR indisponível
  Future<void> initializeAR() async {
    // Funcionalidade temporariamente indisponível
  }

  Future<void> dispose() async {
    // Funcionalidade temporariamente indisponível
  }

  Future<List<dynamic>> performHitTest() async {
    // Funcionalidade temporariamente indisponível
    return [];
  }

  Future<bool> addARObject(ARObjectModel object) async {
    // Funcionalidade temporariamente indisponível
    return false;
  }

  Future<bool> removeARObject(String objectId) async {
    // Funcionalidade temporariamente indisponível
    return false;
  }

  Future<void> clearAllObjects() async {
    // Funcionalidade temporariamente indisponível
  }

  Future<ARSceneModel?> loadScene(String sceneId) async {
    // Funcionalidade temporariamente indisponível
    return null;
  }

  Future<bool> saveScene(ARSceneModel scene) async {
    // Funcionalidade temporariamente indisponível
    return false;
  }

  Stream<dynamic> get onARSessionUpdate => const Stream.empty();
  Stream<dynamic> get onARObjectAdded => const Stream.empty();
  Stream<dynamic> get onARObjectRemoved => const Stream.empty();
}
