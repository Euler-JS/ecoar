// SUBSTITUA sua ar_experience_page.dart atual por este código
// Aproveitando que mobile_scanner JÁ FUNCIONA no seu projeto
import 'dart:async';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:flutter/material.dart' hide Colors;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';
class RealARExperiencePage extends StatefulWidget {
  final String? markerId;
  
  const RealARExperiencePage({super.key, this.markerId});

  @override
  State<RealARExperiencePage> createState() => _RealARExperiencePageState();
}

class _RealARExperiencePageState extends State<RealARExperiencePage>
    with TickerProviderStateMixin {
  
  // Controllers
  MobileScannerController? _scannerController;
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  
  // Animations
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  
  // State
  bool _useScanner = true;
  bool _arInitialized = false;
  bool _isLoading = true;
  String _scannedData = '';
  String _statusMessage = 'Inicializando...';
  
  // AR Objects
  List<ARNode> _arNodes = [];
  List<ARPlaneAnchor> _arAnchors = [];
  int _objectCount = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeScanner();
    
    // Se markerId foi passado, pular scanner
    if (widget.markerId != null) {
      _scannedData = widget.markerId!;
      _useScanner = false;
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _arSessionManager?.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    
    setState(() {
      _statusMessage = '📱 Scanner ativo - Posicione QR Code na tela';
      _isLoading = false;
    });
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_useScanner ? Icons.qr_code_scanner : Icons.view_in_ar),
            const SizedBox(width: 8),
            Text(_useScanner ? 'EcoAR Scanner' : 'EcoAR Experiência'),
          ],
        ),
        backgroundColor: _useScanner ? AppTheme.primaryBlue : AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          if (!_useScanner && _arInitialized)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllARObjects,
              tooltip: 'Limpar objetos',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _isLoading
                ? _buildLoadingScreen()
                : _useScanner
                    ? _buildScannerScreen()
                    : _buildARScreen(),
          ),
          
          // Status overlay
          _buildStatusOverlay(),
          
          // Mode controls
          if (!_isLoading) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      key: const ValueKey('loading'),
      color: AppTheme.accentGreen,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 20),
            Text(
              'Inicializando EcoAR...',
              style: TextStyle(color: AppTheme.primaryGreen, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        key: const ValueKey('scanner'),
        child: MobileScanner(
          controller: _scannerController!,
          onDetect: _onQRCodeDetected,
          overlay: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primaryGreen,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(50),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_strong, size: 80, color: AppTheme.backgroundLight),
                  SizedBox(height: 20),
                  Text(
                    'Posicione o QR Code aqui',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      backgroundColor: AppTheme.backgroundDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildARScreen() {
    return Container(
      key: const ValueKey('ar'),
      child: ARView(
        onARViewCreated: _onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontal,
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _useScanner ? AppTheme.primaryBlue : AppTheme.primaryGreen,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: AppTheme.backgroundLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (_scannedData.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Código: $_scannedData',
                    style: const TextStyle(
                      color: AppTheme.backgroundLight,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              if (!_useScanner && _arInitialized) ...[
                const SizedBox(height: 10),
                Text(
                  'Objetos AR: $_objectCount',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Mode switcher
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.surfaceDark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _useScanner ? AppTheme.primaryBlue : AppTheme.textSecondary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: AppTheme.backgroundLight,
                            size: _useScanner ? 20 : 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scanner',
                            style: TextStyle(
                              color: AppTheme.backgroundLight,
                              fontWeight: _useScanner ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: !_useScanner ? AppTheme.primaryGreen : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_in_ar,
                            color: AppTheme.backgroundLight,
                            size: !_useScanner ? 20 : 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AR',
                            style: TextStyle(
                              color: AppTheme.backgroundLight,
                              fontWeight: !_useScanner ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // AR specific controls
          if (!_useScanner && _arInitialized) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildARButton(
                  icon: Icons.park,
                  label: 'Árvore',
                  onTap: () => _addARObject('tree'),
                ),
                _buildARButton(
                  icon: Icons.local_florist,
                  label: 'Flor',
                  onTap: () => _addARObject('flower'),
                ),
                _buildARButton(
                  icon: Icons.eco,
                  label: 'Planta',
                  onTap: () => _addARObject('plant'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildARButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen  ,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryGreen),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.backgroundLight, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.backgroundLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code != _scannedData) {
        setState(() {
          _scannedData = code;
          _statusMessage = '✅ QR Code detectado! Mudando para AR...';
        });
        
        _bounceController.forward();
        
        // Auto switch to AR after successful scan
        Timer(const Duration(seconds: 2), () {
          _switchMode(false);
        });
        break;
      }
    }
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    _arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    _arObjectManager!.onInitialize();

    _arSessionManager!.onPlaneOrPointTap = _onPlaneTapped;

    setState(() {
      _arInitialized = true;
      _statusMessage = '🎯 AR ativo! Toque numa superfície para colocar objetos';
    });
    
    // Se já tem dados escaneados, carrega automaticamente
    if (_scannedData.isNotEmpty) {
      Timer(const Duration(seconds: 1), () {
        _addARObject('auto');
      });
    }
  }

  Future<void> _onPlaneTapped(List<ARHitTestResult> hitTestResults) async {
    final hitTestResult = hitTestResults.firstOrNull;
    if (hitTestResult != null) {
      final anchor = ARPlaneAnchor(transformation: hitTestResult.worldTransform);
      final didAddAnchor = await _arAnchorManager!.addAnchor(anchor);
      
      if (didAddAnchor!) {
        _arAnchors.add(anchor);
        await _addSceneObject(anchor);
      }
    }
  }

  Future<void> _addARObject(String type) async {
    if (_arAnchors.isEmpty) {
      setState(() {
        _statusMessage = '❌ Toque numa superfície primeiro para colocar objeto';
      });
      return;
    }

    final anchor = _arAnchors.last;
    await _addSceneObject(anchor, type: type);
  }

  Future<void> _addSceneObject(ARPlaneAnchor anchor, {String type = 'auto'}) async {
    try {
      ARNode? newNode;
      
      // Determinar que tipo de objeto carregar
      String objectType = type;
      // if (type == 'auto') {
      //   objectType = _determineObjectTypeFromScan();
      // }

      objectType = 'tree';

      newNode = ARNode(
            type: NodeType.webGLB,
            uri: "https://euler-js.github.io/files_test/sword_barbarian.glb",
            scale: Vector3(0.15, 0.15, 0.15),
            position: Vector3(0.0, 0.0, 0.0),
            rotation: Vector4(1.0, 0.0, 0.0, 0.0),
          );

      // Criar nó AR baseado no tipo
      switch (objectType) {
        case 'tree':
          newNode = ARNode(
            type: NodeType.webGLB,
            uri: "https://euler-js.github.io/files_test/sword_barbarian.glb",
            scale: Vector3(0.15, 0.15, 0.15),
            position: Vector3(0.0, 0.0, 0.0),
            rotation: Vector4(1.0, 0.0, 0.0, 0.0),
          );
          break;
          
        case 'flower':
          newNode = ARNode(
            type: NodeType.localGLTF2,
            uri: "assets/ar_models/scene.gltf",
            scale: Vector3(0.05, 0.05, 0.05),
            position: Vector3(0.2, 0.0, 0.2),
            rotation: Vector4(0.0, 1.0, 0.0, 1.57),
          );
          break;
          
        default:
          newNode = ARNode(
            type: NodeType.webGLB,
            uri: "https://euler-js.github.io/files_test/sword_barbarian.glb",
            scale: Vector3(0.1, 0.1, 0.1),
            position: Vector3(0.0, 0.0, 0.0),
            rotation: Vector4(1.0, 0.0, 0.0, 0.0),
          );
      }

      final didAddNode = await _arObjectManager!.addNode(newNode, planeAnchor: anchor);
      if (didAddNode!) {
        _arNodes.add(newNode);
        setState(() {
          _objectCount++;
          _statusMessage = '🌱 Objeto $objectType adicionado! ($_objectCount total)';
        });
        _bounceController.forward();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erro ao carregar objeto: $e';
      });
    }
  }

  String _determineObjectTypeFromScan() {
    final data = _scannedData.toLowerCase();
    if (data.contains('tree') || data.contains('arvore')) return 'tree';
    if (data.contains('flower') || data.contains('flor')) return 'flower';
    if (data.contains('plant') || data.contains('planta')) return 'plant';
    return 'plant'; // default
  }

  void _switchMode(bool useScanner) {
    setState(() {
      _useScanner = useScanner;
      if (_useScanner) {
        _statusMessage = '📱 Scanner ativo - Posicione QR Code na tela';
      } else {
        _statusMessage = _arInitialized 
          ? '🎯 AR ativo! Toque numa superfície'
          : '⏳ Inicializando AR...';
      }
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _clearAllARObjects() async {
    for (final anchor in _arAnchors) {
      await _arAnchorManager!.removeAnchor(anchor);
    }
    _arAnchors.clear();
    _arNodes.clear();
    setState(() {
      _objectCount = 0;
      _statusMessage = '🗑️ Objetos removidos! Toque para recolocar';
    });
  }
}