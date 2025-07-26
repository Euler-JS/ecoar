// lib/features/ar/presentation/pages/ar_real_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:camera/camera.dart';
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
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:path_provider/path_provider.dart';

// Import dos serviços de Plant ID
import 'package:ecoar_beira/features/plant_identification/data/services/plantnet_service.dart';
import 'package:ecoar_beira/features/plant_identification/data/repositories/local_plant_knowledge.dart';
import 'package:ecoar_beira/features/plant_identification/config/plant_id_config.dart';

class RealARPage extends StatefulWidget {
  const RealARPage({super.key});

  @override
  State<RealARPage> createState() => _RealARPageState();
}

class _RealARPageState extends State<RealARPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  // AR Controllers
  Map<String, ARModelInfo> _nodeToModelMap = {};
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = <ARNode>[];
  List<ARPlaneAnchor> anchors = <ARPlaneAnchor>[];
  String _info = 'Toque na tela para colocar objeto AR';
  bool _isObjectPlaced = false;

  // 🆕 SWITCH DE MODO: AR ↔ PLANTAS
  bool _isPlantMode = false; // false = AR, true = Plant ID
  
  PlantOrgan _selectedOrgan = PlantOrgan.leaf;
  // Plant ID Controllers
  CameraController? _plantCamera;
  bool _plantCameraInitialized = false;
  bool _isIdentifying = false;
  late PlantNetService _plantNetService;
  final LocalPlantKnowledge _localKnowledge = LocalPlantKnowledge.instance;
  
  // Animation Controllers
  late AnimationController _switchController;
  late Animation<double> _switchAnimation;
  
  // Lista de modelos disponíveis
  final List<ARModelInfo> _availableModels = [
    ARModelInfo(
      name: "Árvore",
      icon: "🌳",
      uri: "assets/ar_models/Bem_vindo_ao_EcoAR__0725105815_texture.glb",
      scale: Vector3(100.0, 100.0, 100.0),
      description: "Árvore nativa da região da Beira, essencial para o ecossistema local.",
      scientificName: "Acacia melanoxylon",
      benefits: [
        "Purifica o ar",
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
      description: "Flor tropical da região da Beira, importante para polinizadores.",
      scientificName: "Hibiscus rosa-sinensis",
      benefits: [
        "Atrai polinizadores",
        "Embeleza o ambiente",
        "Propriedades medicinais",
        "Resistente ao clima tropical"
      ],
      care: "Rega diária, sol parcial, fertilização mensal",
      points: 30,
      location: "Jardim Botânico da Beira",
    ),
  ];
  
  ARModelInfo? _selectedModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Setup animations
    _switchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _switchAnimation = CurvedAnimation(
      parent: _switchController,
      curve: Curves.easeInOut,
    );

    // Initialize Plant ID service
    _plantNetService = PlantNetService(
      apiKey: PlantIdConfig.plantNetApiKey,
      // project: PlantIdConfig.plantNetProject,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    _selectedModel = _availableModels[0];
    
    Future.delayed(const Duration(seconds: 2), () {
      _autoPlaceInitialModels();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    
    _switchController.dispose();
    _plantCamera?.dispose();
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_plantCamera == null || !_plantCamera!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      _plantCamera?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_isPlantMode) {
        _initPlantCamera();
      }
    }
  }

  // 🔄 SWITCH ENTRE MODOS
  Future<void> _switchMode() async {
    setState(() {
      _isPlantMode = !_isPlantMode;
    });

    if (_isPlantMode) {
      _switchController.forward();
      await _initPlantCamera();
      setState(() {
        _info = '📸 Modo Plantas - Capture uma foto para identificar';
      });
    } else {
      _switchController.reverse();
      _disposePlantCamera();
      setState(() {
        _info = '🌳 Modo AR - Interaja com objetos 3D';
      });
    }
    
    HapticFeedback.lightImpact();
  }

  // 📸 INICIALIZAR CÂMERA PARA PLANTAS
  Future<void> _initPlantCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Nenhuma câmera disponível');
      }

      _plantCamera = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _plantCamera!.initialize();
      
      if (mounted) {
        setState(() {
          _plantCameraInitialized = true;
        });
      }
    } catch (e) {
      AppLogger.e('Erro ao inicializar câmera para plantas', e);
      setState(() {
        _info = '❌ Erro ao acessar câmera: $e';
      });
    }
  }

  // 🗑️ LIMPAR CÂMERA DE PLANTAS
  void _disposePlantCamera() {
    _plantCamera?.dispose();
    _plantCamera = null;
    _plantCameraInitialized = false;
  }

  // 📸 CAPTURAR E IDENTIFICAR PLANTA
  Future<void> _captureAndIdentifyPlant() async {
    if (_plantCamera == null || !_plantCamera!.value.isInitialized) {
      setState(() {
        _info = '❌ Câmera não está pronta';
      });
      return;
    }

    if (_isIdentifying) return;

    setState(() {
      _isIdentifying = true;
      _info = '📸 Capturando foto...';
    });

    try {
      HapticFeedback.mediumImpact();
      
      final XFile imageFile = await _plantCamera!.takePicture();
      
      setState(() {
        _info = '🔍 Identificando planta...';
      });

      // Identificar planta
      final result = await _plantNetService.identifyPlant(
        imageFile: File(imageFile.path),
        organ: PlantOrgan.leaf, // Default to leaf
      );

      // Buscar informação local
      final localInfo = _localKnowledge.getPlantInfo(
        result.bestMatch?.species.scientificNameWithoutAuthor ?? '',
      );

      // Mostrar resultado
      _showPlantResult(result, File(imageFile.path), localInfo);

    } catch (e) {
      AppLogger.e('Erro na identificação de planta', e);
      setState(() {
        _info = '❌ Erro na identificação: $e';
      });
    } finally {
      setState(() {
        _isIdentifying = false;
      });
    }
  }

  // 📊 MOSTRAR RESULTADO DA IDENTIFICAÇÃO
  void _showPlantResult(PlantIdentificationResult result, File imageFile, LocalPlantInfo? localInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantResultModal(
        result: result,
        imageFile: imageFile,
        localInfo: localInfo,
        onClose: () {
          Navigator.pop(context);
          setState(() {
            _info = '📸 Modo Plantas - Capture outra foto para identificar';
          });
        },
      ),
    );
  }

  // AR METHODS (mantidos do código original)
  Future<void> _autoPlaceInitialModels() async {
    if (arSessionManager != null && arObjectManager != null) {
      setState(() {
        _info = '🔍 Detectando superfície automáticamente...';
      });
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (anchors.isEmpty) {
        var centerAnchor = ARPlaneAnchor(
          transformation: Matrix4.identity()
            ..setTranslation(Vector3(0.0, -0.5, -2.0)),
        );
        
        bool? didAddAnchor = await arAnchorManager!.addAnchor(centerAnchor);
        if (didAddAnchor!) {
          anchors.add(centerAnchor);
          
          var treeModel = _availableModels[0];
          var updatedTreeModel = ARModelInfo(
            name: treeModel.name,
            icon: treeModel.icon,
            uri: treeModel.uri,
            scale: Vector3(50, 50, 50),
            position: Vector3(0.0, 0.0, 0.0),
            rotation: treeModel.rotation,
            description: treeModel.description,
            scientificName: treeModel.scientificName,
            benefits: treeModel.benefits,
            care: treeModel.care,
            points: treeModel.points,
            location: treeModel.location,
          );
          await _addNode(centerAnchor, updatedTreeModel);

          var flowerModel = _availableModels[1];
          var updatedFlowerModel = ARModelInfo(
            name: flowerModel.name,
            icon: flowerModel.icon,
            uri: flowerModel.uri,
            scale: Vector3(50, 50, 50),
            position: Vector3(5, 0.0, 0.0),
            rotation: flowerModel.rotation,
            description: flowerModel.description,
            scientificName: flowerModel.scientificName,
            benefits: flowerModel.benefits,
            care: flowerModel.care,
            points: flowerModel.points,
            location: flowerModel.location,
          );
          await _addNode(centerAnchor, updatedFlowerModel);
          
          setState(() {
            _info = '✅ Bem-vindo ao EcoAR! Use o switch para alternar entre AR e identificação de plantas';
            _isObjectPlaced = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // AR View (sempre ativo em background)
            ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontal,
            ),

            _buildControls(),
            
            // 🆕 PLANT CAMERA OVERLAY
         if (_isPlantMode && _plantCameraInitialized)
  AnimatedBuilder(
    animation: _switchAnimation,
    builder: (context, child) {
      return Opacity(
        opacity: _switchAnimation.value,
        child: Stack(
          children: [
            // Camera preview
            CameraPreview(_plantCamera!),
            
            // Overlay com enquadramento
            _buildCameraOverlay(),
            
            // Controles
            _buildPlantControls(),
          ],
        ),
      );
    },
  ),
            // 📸 BOTÃO DE CAPTURA (só no modo plantas)
            // if (_isPlantMode)
            //   Positioned(
            //     bottom: MediaQuery.of(context).padding.bottom + 30,
            //     left: 0,
            //     right: 0,
            //     child: Center(
            //       child: _buildCaptureButton(),
            //     ),
            //   ),
            
            // ℹ️ INFO OVERLAY
            Positioned(
              bottom: _isPlantMode ? 120 : 30,
              left: 16,
              right: 16,
              child: _buildInfoOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOverlay() {
  return Center(
    child: Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.green,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ..._buildCornerIndicators(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Enquadre a ${_selectedOrgan.displayName.toLowerCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

List<Widget> _buildCornerIndicators() {
  return [
    Positioned(
      top: -3,
      left: -3,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.green, width: 6),
            left: BorderSide(color: Colors.green, width: 6),
          ),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
        ),
      ),
    ),
    // ... adicione os outros 3 cantos igual ao código original
  ];
}

Widget _buildPlantControls() {
  return Column(
    children: [
      // Seleção de órgão no topo
      Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 70,
          left: 16,
          right: 16,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Que parte da planta está fotografando?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: PlantOrgan.values.map((organ) {
                final isSelected = organ == _selectedOrgan;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOrgan = organ;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      organ.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      
      const Spacer(),
      
      // Botões de ação na parte inferior
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(Icons.collections, 'Galeria', () {}),
            _buildActionButton(Icons.lightbulb_outline, 'Dicas', _showTipsDialog),
            _buildActionButton(Icons.nature, 'Plantas Locais', () {}),
          ],
        ),
      ),
    ],
  );
}

Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    ),
  );
}

void _showTipsDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('🌱 Dicas para Melhor Identificação'),
      content: const Text('• Use boa iluminação natural\n• Enquadre apenas a parte selecionada\n• Mantenha câmera estável'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}

  Widget _buildControls() {
    return Column(
      children: [
        // Botão fechar
        FloatingActionButton(
          mini: true,
          backgroundColor: Colors.black54,
          onPressed: () => context.go('/scanner'),
          child: const Icon(Icons.close, color: Colors.white),
        ),
        
        const SizedBox(height: 8),
        
        // 🔄 SWITCH DE MODO
        FloatingActionButton.extended(
          onPressed: _switchMode,
          backgroundColor: _isPlantMode ? Colors.green : Colors.blue,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isPlantMode ? Icons.camera_alt : Icons.view_in_ar,
              key: ValueKey(_isPlantMode),
              color: Colors.white,
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isPlantMode ? 'Plantas' : 'AR',
              key: ValueKey(_isPlantMode),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isIdentifying ? null : _captureAndIdentifyPlant,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isIdentifying ? Colors.grey : Colors.white,
          border: Border.all(
            color: Colors.green,
            width: 4,
          ),
        ),
        child: _isIdentifying
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              )
            : const Icon(
                Icons.camera_alt,
                size: 40,
                color: Colors.green,
              ),
      ),
    );
  }

  Widget _buildInfoOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _info,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // AR METHODS (mantidos do código original)
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
    
    Future.delayed(const Duration(seconds: 2), () {
      _autoPlaceInitialModels();
    });
  }

  void _onObjectTapped(List<String> nodeNames) {
    if (_isPlantMode) return; // Não processar taps no modo plantas
    
    if (nodeNames.isNotEmpty) {
      String objectName = nodeNames.first;
      ARModelInfo? clickedModel = _findModelByNodeName(objectName);
      
      setState(() {
        _info = '👆 Clicou em ${clickedModel?.name ?? objectName}';
      });
      
      HapticFeedback.lightImpact();
      
      if (clickedModel != null) {
        _showObjectDetails(clickedModel);
      }
    }
  }

  void _showObjectDetails(ARModelInfo model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ObjectDetailsModal(model: model),
    );
  }

  ARModelInfo? _findModelByNodeName(String nodeName) {
    if (_nodeToModelMap.containsKey(nodeName)) {
      return _nodeToModelMap[nodeName];
    }
    
    for (var model in _availableModels) {
      if (nodeName.toLowerCase().contains(model.name.toLowerCase()) || 
          nodeName.contains(model.icon)) {
        return model; 
      }
    }
    
    return _availableModels.isNotEmpty ? _availableModels[0] : null;
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
    if (!_isPlantMode) {
      setState(() {
        _info = '🤏 Movendo objeto: $nodeName';
      });
    }
  }

  _onPanChanged(String nodeName) {}

  _onPanEnded(String nodeName, Matrix4 newTransform) {
    if (!_isPlantMode) {
      setState(() {
        _info = '✅ Objeto reposicionado: $nodeName';
      });
    }
  }

  _onRotationStarted(String nodeName) {
    if (!_isPlantMode) {
      setState(() {
        _info = '🔄 Rotacionando: $nodeName';
      });
    }
  }

  _onRotationChanged(String nodeName) {}

  _onRotationEnded(String nodeName, Matrix4 newTransform) {
    if (!_isPlantMode) {
      setState(() {
        _info = '✅ Objeto rotacionado: $nodeName';
      });
    }
  }
}

// ARModelInfo class (mantida do original)
class ARModelInfo {
  final String name;
  final String icon;
  final String uri;
  final Vector3 scale;
  final Vector3? position;
  final Vector4? rotation;
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

// Modal para resultado de planta
class PlantResultModal extends StatelessWidget {
  final PlantIdentificationResult result;
  final File imageFile;
  final LocalPlantInfo? localInfo;
  final VoidCallback onClose;

  const PlantResultModal({
    super.key,
    required this.result,
    required this.imageFile,
    required this.localInfo,
    required this.onClose,
  });

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
                  // Imagem capturada
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        imageFile,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Resultado da identificação
                  if (result.hasConfidentMatch) ...[
                    Text(
                      result.bestMatch!.species.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Confiança: ${(result.bestMatch!.score * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (localInfo != null) ...[
                      Text(
                        'Informações Locais',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(localInfo!.importance),
                    ] else ...[
                      const Text(
                        'Planta identificada através da base científica PlantNet. '
                        'Continue explorando para descobrir mais plantas locais!',
                      ),
                    ],
                  ] else ...[
                    const Text(
                      'Não foi possível identificar esta planta com confiança.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tente capturar uma foto mais nítida da folha ou flor da planta.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Botões
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continuar Identificando',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ObjectDetailsModal (mantido do original)
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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