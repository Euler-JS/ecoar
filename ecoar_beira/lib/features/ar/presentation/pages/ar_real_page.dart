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

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌱 AR Real'),
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
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _info,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _onPlantTree,
                        child: const Text('🌳 Plantar'),
                      ),
                      ElevatedButton(
                        onPressed: _onPlaceFlower,
                        child: const Text('🌸 Flor'),
                      ),
                      ElevatedButton(
                        onPressed: _onLoadGLTF,
                        child: const Text('📦 GLTF'),
                      ),
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
      _info = '✅ AR Iniciado! Toque numa superfície';
    });
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstOrNull;
    if (singleHitTestResult != null) {
      var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await this.arAnchorManager!.addAnchor(newAnchor);
      
      if (didAddAnchor!) {
        this.anchors.add(newAnchor);
        // Por padrão, adiciona uma árvore
        await _addTreeNode(newAnchor);
        setState(() {
          _info = '🎯 Objeto colocado! Arraste ou rotacione';
          _isObjectPlaced = true;
        });
      }
    }
  }

  Future<void> _onPlantTree() async {
    if (anchors.isNotEmpty) {
      var lastAnchor = anchors.last;
      await _addTreeNode(lastAnchor);
    } else {
      setState(() {
        _info = '❌ Toque numa superfície primeiro';
      });
    }
  }

  Future<void> _onPlaceFlower() async {
    if (anchors.isNotEmpty) {
      var lastAnchor = anchors.last;
      await _addFlowerNode(lastAnchor);
    } else {
      setState(() {
        _info = '❌ Toque numa superfície primeiro';
      });
    }
  }

  Future<void> _onLoadGLTF() async {
    if (anchors.isNotEmpty) {
      var lastAnchor = anchors.last;
      await _addGLTFNode(lastAnchor);
    } else {
      setState(() {
        _info = '❌ Toque numa superfície primeiro';
      });
    }
  }

  Future<void> _addTreeNode(ARPlaneAnchor anchor) async {
    var newNode = ARNode(
      type: NodeType.webGLB,
      uri: "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb", // Você pode converter seu GLTF para GLB
      scale: Vector3(0.5, 0.5, 0.5),
      position: Vector3(0.0, 0.0, 0.0),
      rotation: Vector4(1.0, 0.0, 0.0, 0.0),
    );

    bool? didAddNodeToAnchor = await this.arObjectManager!.addNode(newNode, planeAnchor: anchor);
    if (didAddNodeToAnchor!) {
      this.nodes.add(newNode);
    }
  }

  Future<void> _addFlowerNode(ARPlaneAnchor anchor) async {
    var newNode = ARNode(
      type: NodeType.localGLTF2,
      uri: "assets/ar_models/scene.gltf",
      scale: Vector3(0.3, 0.3, 0.3),
      position: Vector3(0.2, 0.0, 0.2),
      rotation: Vector4(0.0, 1.0, 0.0, 0.0),
    );

    bool? didAddNodeToAnchor = await this.arObjectManager!.addNode(newNode, planeAnchor: anchor);
    if (didAddNodeToAnchor!) {
      this.nodes.add(newNode);
    }
  }

  Future<void> _addGLTFNode(ARPlaneAnchor anchor) async {
    // Carrega seu GLTF da URL
    var newNode = ARNode(
      type: NodeType.webGLB,
      uri: "https://euler-js.github.io/files_test/scene.gltf",
      scale: Vector3(0.1, 0.1, 0.1), // Ajuste a escala conforme necessário
      position: Vector3(0.0, 0.0, 0.0),
      rotation: Vector4(1.0, 0.0, 0.0, 0.0),
    );

    bool? didAddNodeToAnchor = await this.arObjectManager!.addNode(newNode, planeAnchor: anchor);
    if (didAddNodeToAnchor!) {
      this.nodes.add(newNode);
      setState(() {
        _info = '📦 Modelo GLTF carregado!';
      });
    } else {
      setState(() {
        _info = '❌ Erro ao carregar GLTF';
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
    /*nodes.forEach((node) {
      this.arObjectManager!.removeNode(node);
    });*/
    for (var anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();
    setState(() {
      _info = '🗑️ Tudo removido! Toque para recolocar';
      _isObjectPlaced = false;
    });
  }
}