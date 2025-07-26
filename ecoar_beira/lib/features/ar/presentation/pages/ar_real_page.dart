// ar_real_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class RealARPage extends StatefulWidget {
  const RealARPage({super.key});

  @override
  State<RealARPage> createState() => _RealARPageState();
}

class _RealARPageState extends State<RealARPage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = <ARNode>[];
  List<ARPlaneAnchor> anchors = <ARPlaneAnchor>[];
  String _info = 'Toque na tela para colocar objeto AR';
  bool _isObjectPlaced = false;
  
  // Lista de modelos disponíveis
  final List<ARModelInfo> _availableModels = [
    ARModelInfo(
      name: "Árvore",
      icon: "🌳",
      uri: "assets/ar_models/Bem_vindo_ao_EcoAR__0725105815_texture.glb",
     scale: Vector3(100.0, 100.0, 100.0), // Aumentando a escala para um tamanho médio
    //  position: Vector3(0.0, 0.0, 0.0),
  // rotation: treeModel.rotation,
    ),
    ARModelInfo(
      name: "Flor",
      icon: "🌸",
      uri: "assets/ar_models/Distinguished_Gentlem_0725173157_texture.glb",
      scale: Vector3(100.0, 100.0, 100.0),
      // position: Vector3(0.2, 0.0, 0.2),
    ),
    // ARModelInfo(
    //   name: "Irrigação",
    //   icon: "💧",
    //   uri: "assets/ar_models/Irrigation_Symphony_07251107_texture.glb",
    //   scale: Vector3(0.8, 0.8, 0.8),
    // ),
    // ARModelInfo(
    //   name: "Cultivador",
    //   icon: "🍄",
    //   uri: "assets/ar_models/Mushroom_grower_machine.usdz",
    //   scale: Vector3(0.7, 0.7, 0.7),
    // ),
    // ARModelInfo(
    //   name: "Ambiente",
    //   icon: "🌿",
    //   uri: "assets/ar_models/Vertical_Farm_Abundan_07251150_texture.glb",
    //   scale: Vector3(0.9, 0.9, 0.9),
    // ),
  ];
  
  // Modelo selecionado atualmente
  ARModelInfo? _selectedModel;

  @override
  void initState() {
    super.initState();
    // Define o modelo padrão
    _selectedModel = _availableModels[0];
    
    // Inicia um timer para colocar os modelos automaticamente após inicialização da câmera AR
    Future.delayed(const Duration(seconds: 2), () {
      _autoPlaceInitialModels();
    });
  }

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }
  
  // Coloca os dois primeiros modelos automaticamente quando a tela abre
  Future<void> _autoPlaceInitialModels() async {
    if (arSessionManager != null && arObjectManager != null) {
      setState(() {
        _info = '🔍 Detectando superfície automáticamente...';
      });
      
      // Espera por planos detectados
      await Future.delayed(const Duration(seconds: 2));
      
      // Se não temos âncoras, criamos uma virtual
      if (anchors.isEmpty) {
        // Cria uma âncora no centro da visualização
        var centerAnchor = ARPlaneAnchor(
          transformation: Matrix4.identity()
            ..setTranslation(Vector3(0.0, -0.5, -2.0)), // Posiciona à frente da câmera
        );
        
        bool? didAddAnchor = await arAnchorManager!.addAnchor(centerAnchor);
        if (didAddAnchor!) {
          anchors.add(centerAnchor);
          
          // Coloca a árvore com escala maior para garantir visibilidade
          var treeModel = _availableModels[0];
          _availableModels[0] = ARModelInfo(
            name: treeModel.name,
            icon: treeModel.icon,
            uri: treeModel.uri,
            scale: Vector3(50, 50, 50), // Aumenta escala para visibilidade
            position: Vector3(0.0, 0.0, 0.0),
            rotation: treeModel.rotation,
          );
          await _addNode(centerAnchor, _availableModels[0]);
          
          // Coloca a flor ao lado
          var flowerModel = _availableModels[1];
          _availableModels[1] = ARModelInfo(
            name: flowerModel.name,
            icon: flowerModel.icon,
            uri: flowerModel.uri,
            scale: Vector3(50, 50, 50), // Aumenta escala para visibilidade
            position: Vector3(5, 0.0, 0.0), // Posiciona ao lado da árvore
            rotation: flowerModel.rotation,
          );
          await _addNode(centerAnchor, _availableModels[1]);
          
          setState(() {
            _info = '✅ Bem-vindo ao EcoAR! Toque nos botões para adicionar mais modelos';
            _isObjectPlaced = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌱 EcoAR'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _onRemoveEverything();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _info,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildModelButton(_availableModels[0]), // Árvore
                      const SizedBox(width: 20),
                      _buildModelButton(_availableModels[1]), // Flor
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Cria um botão destacado para um modelo
  Widget _buildModelButton(ARModelInfo model) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _selectedModel = model;
        });
        _onPlaceSelectedModel();
      },
      icon: Text(
        model.icon, 
        style: const TextStyle(fontSize: 24),
      ),
      label: Text(
        model.name,
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
    this.arObjectManager!.onPanStart = _onPanStarted;
    this.arObjectManager!.onPanChange = _onPanChanged;
    this.arObjectManager!.onPanEnd = _onPanEnded;
    this.arObjectManager!.onRotationStart = _onRotationStarted;
    this.arObjectManager!.onRotationChange = _onRotationChanged;
    this.arObjectManager!.onRotationEnd = _onRotationEnded;

    setState(() {
      _info = '✅ AR Iniciado! Os modelos aparecerão automaticamente';
    });
    
    // Inicia o processo de colocação automática após detectar planos
    Future.delayed(const Duration(seconds: 2), () {
      _autoPlaceInitialModels();
    });
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstOrNull;
    if (singleHitTestResult != null) {
      var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await this.arAnchorManager!.addAnchor(newAnchor);
      
      if (didAddAnchor!) {
        this.anchors.add(newAnchor);
        // Coloca o modelo selecionado
        if (_selectedModel != null) {
          await _addNode(newAnchor, _selectedModel!);
          setState(() {
            _info = '🎯 Objeto colocado! Arraste ou rotacione';
            _isObjectPlaced = true;
          });
        }
      }
    }
  }

  Future<void> _onPlaceSelectedModel() async {
    if (_selectedModel == null) {
      setState(() {
        _info = '❌ Selecione um modelo primeiro';
      });
      return;
    }
    
    if (anchors.isEmpty) {
      setState(() {
        _info = '❌ Toque numa superfície primeiro';
      });
    } else {
      var lastAnchor = anchors.last;
      await _addNode(lastAnchor, _selectedModel!);
      setState(() {
        _info = '✅ ${_selectedModel!.icon} ${_selectedModel!.name} colocado!';
      });
    }
  }

  Future<void> _addNode(ARPlaneAnchor anchor, ARModelInfo modelInfo) async {
    try {
      // Cria o nó AR com o modelo selecionado
      var newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: modelInfo.uri,
        scale: modelInfo.scale,
        position: modelInfo.position ?? Vector3(0.0, 0.0, 0.0),
        rotation: modelInfo.rotation ?? Vector4(1.0, 0.0, 0.0, 0.0),
      );

      bool? didAddNodeToAnchor = await this.arObjectManager!.addNode(newNode, planeAnchor: anchor);
      if (didAddNodeToAnchor!) {
        this.nodes.add(newNode);
        setState(() {
          _info = '✅ ${modelInfo.icon} ${modelInfo.name} adicionado!';
        });
      } else {
        setState(() {
          _info = '❌ Erro ao carregar modelo';
        });
      }
    } catch (e) {
      print("Erro ao adicionar nó: $e");
      setState(() {
        _info = '❌ Erro ao carregar modelo: $e';
      });
    }
  }

  _onPanStarted(String nodeName) {
    setState(() {
      _info = '🤏 Movendo objeto: $nodeName';
    });
  }

  _onPanChanged(String nodeName) {
    // Feedback em tempo real se necessário
  }

  _onPanEnded(String nodeName, Matrix4 newTransform) {
    setState(() {
      _info = '✅ Objeto reposicionado: $nodeName';
    });
  }

  _onRotationStarted(String nodeName) {
    setState(() {
      _info = '🔄 Rotacionando: $nodeName';
    });
  }

  _onRotationChanged(String nodeName) {
    // Feedback de rotação
  }

  _onRotationEnded(String nodeName, Matrix4 newTransform) {
    setState(() {
      _info = '✅ Objeto rotacionado: $nodeName';
    });
  }

  _onRemoveEverything() async {
    // Remove todos os nós e âncoras
    for (var anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();
    nodes.clear();
    setState(() {
      _info = '🗑️ Tudo removido! Toque para recolocar';
      _isObjectPlaced = false;
    });
  }
}

// Classe para armazenar informações dos modelos AR
class ARModelInfo {
  final String name;
  final String icon;
  final String uri;
  final Vector3 scale;
  final Vector3? position;
  final Vector4? rotation;
  
  ARModelInfo({
    required this.name,
    required this.icon,
    required this.uri,
    required this.scale,
    this.position,
    this.rotation,
  });
}