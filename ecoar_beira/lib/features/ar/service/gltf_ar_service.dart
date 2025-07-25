// gltf_ar_service.dart - Serviço especializado para carregar modelos GLTF em AR
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class GLTFARService {
  static final GLTFARService _instance = GLTFARService._internal();
  factory GLTFARService() => _instance;
  GLTFARService._internal();

  final Dio _dio = Dio();
  final Map<String, String> _cachedModels = {};

  /// Carrega seu modelo GLTF específico
  Future<ARNode?> loadSceneGLTF({
    Vector3? position,
    Vector3? scale,
    Vector4? rotation,
  }) async {
    try {
      const String sceneUrl = "https://euler-js.github.io/files_test/scene.gltf";
      
      // Cache local do modelo
      String? localPath = await _cacheGLTFModel(sceneUrl, 'scene.gltf');
      
      if (localPath != null) {
        return ARNode(
          type: NodeType.localGLTF2,
          uri: localPath,
          scale: scale ?? Vector3(0.1, 0.1, 0.1), // Escala pequena inicialmente
          position: position ?? Vector3(0.0, 0.0, 0.0),
          rotation: rotation ?? Vector4(1.0, 0.0, 0.0, 0.0),
        );
      } else {
        // Fallback para carregamento direto da web
        return ARNode(
          type: NodeType.webGLB,
          uri: sceneUrl,
          scale: scale ?? Vector3(0.1, 0.1, 0.1),
          position: position ?? Vector3(0.0, 0.0, 0.0),
          rotation: rotation ?? Vector4(1.0, 0.0, 0.0, 0.0),
        );
      }
    } catch (e) {
      print('Erro ao carregar scene.gltf: $e');
      return null;
    }
  }

  /// Cache modelo GLTF localmente para melhor performance
  Future<String?> _cacheGLTFModel(String url, String filename) async {
    try {
      if (_cachedModels.containsKey(filename)) {
        return _cachedModels[filename];
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');

      if (await file.exists()) {
        _cachedModels[filename] = file.path;
        return file.path;
      }

      // Baixar modelo
      final response = await _dio.download(url, file.path);
      if (response.statusCode == 200) {
        _cachedModels[filename] = file.path;
        return file.path;
      }
    } catch (e) {
      print('Erro ao cachear modelo GLTF: $e');
    }
    return null;
  }

  /// Cria diferentes variações do modelo baseado no contexto
  ARNode createPlantNode({
    required String plantType,
    Vector3? position,
    Vector3? scale,
  }) {
    switch (plantType.toLowerCase()) {
      case 'arvore':
      case 'tree':
        return ARNode(
          type: NodeType.webGLB,
          uri: "https://euler-js.github.io/files_test/scene.gltf",
          scale: scale ?? Vector3(0.15, 0.15, 0.15), // Maior para árvore
          position: position ?? Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
        );
      
      case 'flor':
      case 'flower':
        return ARNode(
          type: NodeType.webGLB,
          uri: "https://euler-js.github.io/files_test/scene.gltf",
          scale: scale ?? Vector3(0.05, 0.05, 0.05), // Menor para flor
          position: position ?? Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(0.0, 1.0, 0.0, 1.57), // Rotação diferente
        );
      
      case 'arbusto':
      case 'bush':
        return ARNode(
          type: NodeType.webGLB,
          uri: "https://euler-js.github.io/files_test/scene.gltf",
          scale: scale ?? Vector3(0.08, 0.08, 0.08),
          position: position ?? Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
        );
      
      default:
        return ARNode(
          type: NodeType.webGLB,
          uri: "https://euler-js.github.io/files_test/scene.gltf",
          scale: scale ?? Vector3(0.1, 0.1, 0.1),
          position: position ?? Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
        );
    }
  }

  /// Carrega modelos alternativos se o principal falhar
  Future<ARNode?> loadFallbackModel({
    Vector3? position,
    Vector3? scale,
    Vector4? rotation,
  }) async {
    try {
      // Modelo simples de fallback - cubo verde representando planta
      return ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/ar_models/simple_plant.gltf", // Você pode criar um modelo simples
        scale: scale ?? Vector3(0.2, 0.2, 0.2),
        position: position ?? Vector3(0.0, 0.0, 0.0),
        rotation: rotation ?? Vector4(1.0, 0.0, 0.0, 0.0),
      );
    } catch (e) {
      print('Erro ao carregar modelo fallback: $e');
      return null;
    }
  }

  /// Valida se o modelo pode ser carregado
  Future<bool> validateGLTFModel(String uri) async {
    try {
      if (uri.startsWith('http')) {
        final response = await _dio.head(uri);
        return response.statusCode == 200;
      } else {
        final file = File(uri);
        return await file.exists();
      }
    } catch (e) {
      return false;
    }
  }

  /// Limpa cache de modelos
  Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      for (var file in files) {
        if (file.path.endsWith('.gltf') || file.path.endsWith('.glb')) {
          await file.delete();
        }
      }
      
      _cachedModels.clear();
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }

  /// Otimiza configuração AR baseada no dispositivo
  Map<String, dynamic> getOptimalARSettings() {
    return {
      'showFeaturePoints': false, // Melhor performance
      'showPlanes': true, // Necessário para colocação
      'showWorldOrigin': false, // Melhor performance
      'handlePans': true, // Permite movimento
      'handleRotation': true, // Permite rotação
      'handleScale': false, // Desabilita escala para evitar problemas
    };
  }

  /// Configurações de rendering otimizadas
  Map<String, dynamic> getRenderingSettings() {
    return {
      'lightEstimationEnabled': true, // Melhor integração visual
      'planeDetection': 'horizontal', // Apenas planos horizontais
      'maxPlanes': 5, // Limita planos detectados
      'updateFrameRate': 30, // 30 FPS para economia de bateria
    };
  }
}

// Uso da classe:
// 
// final gltfService = GLTFARService();
// 
// // Carregar modelo principal
// ARNode? node = await gltfService.loadSceneGLTF(
//   scale: Vector3(0.1, 0.1, 0.1),
//   position: Vector3(0.0, 0.0, 0.0),
// );
// 
// // Carregar baseado em tipo de planta
// ARNode plantNode = gltfService.createPlantNode(
//   plantType: 'arvore',
//   scale: Vector3(0.15, 0.15, 0.15),
// );
// 
// // Validar antes de usar
// bool isValid = await gltfService.validateGLTFModel(url);
// 
// // Configurar AR otimizado
// Map<String, dynamic> settings = gltfService.getOptimalARSettings();