// ar_real_page.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
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
  Map<String, ARModelInfo> _nodeToModelMap = {};
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
  description: "1Árvore nativa da região da Beira, essencial para o ecossistema local.",
    scientificName: "1Acacia melanoxylon",
    benefits: [
      "1Purifica o ar",
      "Fornece sombra",
      "Habitat para pássaros",
      "Previne erosão do solo"
    ],
    care: "Rega moderada, sol direto, poda anual",
    points: 50,
    location: "Parque da Beira - Zona Norte",
    ),
    ARModelInfo(
      name: "Flor",
      icon: "🌸",
      uri: "assets/ar_models/diablo_iv_deckard_kanais_cube.glb",
      scale: Vector3(100.0, 100.0, 100.0),
      description: "2Árvore nativa da região da Beira, essencial para o ecossistema local.",
    scientificName: "2Acacia melanoxylon",
    benefits: [
      "2Purifica o ar",
      "Fornece sombra",
      "Habitat para pássaros",
      "Previne erosão do solo"
    ],
    care: "Rega moderada, sol direto, poda anual",
    points: 50,
    location: "Parque da Beira - Zona Norte",
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
          var updatedTreeModel = ARModelInfo(
  name: treeModel.name,
  icon: treeModel.icon,
  uri: treeModel.uri,
  scale: Vector3(50, 50, 50), // Nova escala
  position: Vector3(0.0, 0.0, 0.0),
  rotation: treeModel.rotation,
  // ✅ MANTER TODOS OS DADOS ORIGINAIS
  description: treeModel.description,
  scientificName: treeModel.scientificName,
  benefits: treeModel.benefits,
  care: treeModel.care,
  points: treeModel.points,
  location: treeModel.location,
);
await _addNode(centerAnchor, updatedTreeModel);

// Mesmo para a flor
var flowerModel = _availableModels[1];
var updatedFlowerModel = ARModelInfo(
  name: flowerModel.name,
  icon: flowerModel.icon,
  uri: flowerModel.uri,
  scale: Vector3(50, 50, 50),
  position: Vector3(5, 0.0, 0.0),
  rotation: flowerModel.rotation,
  // ✅ MANTER TODOS OS DADOS ORIGINAIS
  description: flowerModel.description,
  scientificName: flowerModel.scientificName,
  benefits: flowerModel.benefits,
  care: flowerModel.care,
  points: flowerModel.points,
  location: flowerModel.location,
);
await _addNode(centerAnchor, updatedFlowerModel);
          
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
                  // const SizedBox(height: 12),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //   children: [
                  //     _buildModelButton(_availableModels[0]), // Árvore
                  //     const SizedBox(width: 20),
                  //     _buildModelButton(_availableModels[1]), // Flor
                  //   ],
                  // ),
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

    // this.arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
    this.arObjectManager!.onPanStart = _onPanStarted;
    this.arObjectManager!.onPanChange = _onPanChanged;
    this.arObjectManager!.onPanEnd = _onPanEnded;
    this.arObjectManager!.onRotationStart = _onRotationStarted;
    this.arObjectManager!.onRotationChange = _onRotationChanged;
    this.arObjectManager!.onRotationEnd = _onRotationEnded;
    this.arObjectManager!.onNodeTap = _onObjectTapped;

    setState(() {
      _info = '✅ AR Iniciado! Os modelos aparecerão automaticamente';
    });
    
    // Inicia o processo de colocação automática após detectar planos
    Future.delayed(const Duration(seconds: 2), () {
      _autoPlaceInitialModels();
    });
  }

 void _onObjectTapped(List<String> nodeNames) {
  if (nodeNames.isNotEmpty) {
    String objectName = nodeNames.first;
    ARModelInfo? clickedModel = _findModelByNodeName(objectName);
    
    setState(() {
      _info = '👆 Clicou em ${clickedModel?.name ?? objectName}';
    });
    
    HapticFeedback.lightImpact();
    
    // 🆕 MOSTRAR DETALHES
    if (clickedModel != null) {
      AppLogger.i('Modelo detectado3: ${clickedModel.name } para o nó $objectName com ícone ${clickedModel.icon} e URI ${clickedModel.uri} e escala ${clickedModel.scale} e posição ${clickedModel.position} e rotação ${clickedModel.rotation}  e descrição ${clickedModel.description} e nome científico ${clickedModel.scientificName} e benefícios ${clickedModel.benefits} e cuidados ${clickedModel.care} e pontos ${clickedModel.points} e localização ${clickedModel.location}');
      _showObjectDetails(clickedModel);
    } else {
      setState(() {
        _info = '👆 Objeto desconhecido: $objectName';
      });
    }
  }
}

void _showObjectDetails(ARModelInfo model) {
  AppLogger.i('Modelo detectado: ${model.name } para  com ícone ${model.icon} e URI ${model.uri} e escala ${model.scale} e posição ${model.position} e rotação ${model.rotation}  e descrição ${model.description} e nome científico ${model.scientificName} e benefícios ${model.benefits} e cuidados ${model.care} e pontos ${model.points} e localização ${model.location}');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ObjectDetailsModal(model: model),
  );
}

// Função auxiliar para encontrar o modelo
ARModelInfo? _findModelByNodeName(String nodeName) {
  // Primeiro, tentar encontrar no mapa
  if (_nodeToModelMap.containsKey(nodeName)) {
    return _nodeToModelMap[nodeName];
  }
  
  // Fallback: verificar por conteúdo do nome
  for (var model in _availableModels) {
    if (nodeName.toLowerCase().contains(model.name.toLowerCase()) || 
        nodeName.contains(model.icon)) {
      AppLogger.i('Modelo detectado: ${model.name } para o nó $nodeName com ícone ${model.icon} e URI ${model.uri} e escala ${model.scale} e posição ${model.position} e rotação ${model.rotation}  e descrição ${model.description} e nome científico ${model.scientificName} e benefícios ${model.benefits} e cuidados ${model.care} e pontos ${model.points} e localização ${model.location}');
      return model; 
    }
  }
  
  // Se nada funcionou, retornar primeiro modelo
  return _availableModels.isNotEmpty ? _availableModels[0] : null;
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
      
      // 🆕 MAPEAR O NÓ AO MODELO
      _nodeToModelMap[newNode.name ?? ''] = modelInfo;
      
      setState(() {
        _info = '✅ ${modelInfo.icon} ${modelInfo.name} adicionado!';
      });
    }
  } catch (e) {
    print("Erro ao adicionar nó: $e");
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
  
  // 🆕 NOVOS CAMPOS PARA DETALHES
  final String description;
  final String scientificName;
  final List<String> benefits;
  final String care;
  final int points;
  final String location;
  
  ARModelInfo({
    required this.name,
    required this.icon,
    required this.uri,
    required this.scale,
    this.position,
    this.rotation,
    this.description = '',
    this.scientificName = '',
    this.benefits = const [],
    this.care = '',
    this.points = 0,
    this.location = '',
  });
}

class ObjectDetailsModal extends StatelessWidget {
  final ARModelInfo model;
  
  const ObjectDetailsModal({required this.model, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Conteúdo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    children: [
                      Text(model.icon, style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (model.scientificName.isNotEmpty)
                              Text(
                                model.scientificName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Pontos
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${model.points} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Descrição
                  if (model.description.isNotEmpty) ...[
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(model.description),
                    const SizedBox(height: 20),
                  ],
                  
                  // Benefícios
                  if (model.benefits.isNotEmpty) ...[
                    const Text(
                      'Benefícios Ambientais',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...model.benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, 
                            color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(benefit)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],
                  
                  // Cuidados
                  if (model.care.isNotEmpty) ...[
                    const Text(
                      'Cuidados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(model.care),
                    const SizedBox(height: 20),
                  ],
                  
                  // Localização
                  if (model.location.isNotEmpty) ...[
                    const Text(
                      'Localização',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(model.location)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Botão de fechar
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}