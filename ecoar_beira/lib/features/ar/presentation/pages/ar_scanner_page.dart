// ar_scanner_page.dart - Integração AR + Scanner
import 'dart:async';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:flutter/material.dart';
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
import 'package:vector_math/vector_math_64.dart' hide Colors;

class ARScannerPage extends StatefulWidget {
  const ARScannerPage({super.key});

  @override
  State<ARScannerPage> createState() => _ARScannerPageState();
}

class _ARScannerPageState extends State<ARScannerPage> {
  // Scanner (que já funciona)
  MobileScannerController? scannerController;
  
  // AR Controllers  
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  
  // State
  bool _useScanner = true; // Alternar entre Scanner e AR
  bool _arInitialized = false;
  String _lastScannedCode = '';
  String _info = 'Scanner ativo - Escaneie QR Code';
  
  // AR Objects
  List<ARNode> nodes = <ARNode>[];
  List<ARAnchor> anchors = <ARAnchor>[];

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    scannerController?.dispose();
    arSessionManager?.dispose();
    super.dispose();
  }

  void _initializeScanner() {
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_useScanner ? '📱 Scanner Mode' : '🌱 AR Mode'),
        backgroundColor: _useScanner ? Colors.blue : Colors.green,
        actions: [
          IconButton(
            icon: Icon(_useScanner ? Icons.view_in_ar : Icons.qr_code_scanner),
            onPressed: _toggleMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Base camera/AR view
          _useScanner ? _buildScannerView() : _buildARView(),
          
          // Info overlay
          _buildInfoOverlay(),
          
          // Mode toggle button
          _buildModeToggle(),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return MobileScanner(
      controller: scannerController!,
      onDetect: _onQRCodeDetected,
      overlay: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: const Center(
          child: Text(
            'Posicione o QR Code aqui',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildARView() {
    if (!_arInitialized) {
      return ARView(
        onARViewCreated: _onARViewCreated,
        planeDetectionConfig: PlaneDetectionConfig.horizontal,
      );
    }
    
    return ARView(
      onARViewCreated: _onARViewCreated,
      planeDetectionConfig: PlaneDetectionConfig.horizontal,
    );
  }

  Widget _buildInfoOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              _info,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (_lastScannedCode.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Último código: $_lastScannedCode',
                style: const TextStyle(color: Colors.yellow, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            if (!_useScanner && _arInitialized) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _loadScannedContent,
                    child: const Text('📦 Carregar'),
                  ),
                  ElevatedButton(
                    onPressed: _clearAR,
                    child: const Text('🗑️ Limpar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _setMode(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _useScanner ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    '📱 Scanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _setMode(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_useScanner ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    '🌱 AR',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code != _lastScannedCode) {
        setState(() {
          _lastScannedCode = code;
          _info = '✅ QR Code detectado! Alterne para AR para visualizar';
        });
        
        // Automatically switch to AR after scanning
        Future.delayed(const Duration(seconds: 2), () {
          _setMode(false);
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

    setState(() {
      _arInitialized = true;
      _info = '✅ AR Iniciado! Toque numa superfície para colocar objeto';
    });
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstOrNull;
    if (singleHitTestResult != null) {
      var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);
      
      if (didAddAnchor!) {
        anchors.add(newAnchor);
        await _loadScannedContent();
      }
    }
  }

  Future<void> _loadScannedContent() async {
    if (anchors.isEmpty) {
      setState(() {
        _info = '❌ Toque numa superfície primeiro';
      });
      return;
    }

    var anchor = anchors.last;
    ARNode? newNode;

    // Diferentes conteúdos baseados no QR Code escaneado
    if (_lastScannedCode.contains('tree') || _lastScannedCode.contains('arvore')) {
      newNode = ARNode(
        type: NodeType.webGLB,
        uri: "https://euler-js.github.io/files_test/scene.gltf",
        scale: Vector3(0.1, 0.1, 0.1),
        position: Vector3(0.0, 0.0, 0.0),
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );
    } else if (_lastScannedCode.contains('flower') || _lastScannedCode.contains('flor')) {
      newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/ar_models/flower.gltf",
        scale: Vector3(0.3, 0.3, 0.3),
        position: Vector3(0.0, 0.0, 0.0),
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );
    } else {
      // Conteúdo genérico para qualquer QR Code
      newNode = ARNode(
        type: NodeType.webGLB,
        uri: "https://euler-js.github.io/files_test/scene.gltf",
        scale: Vector3(0.1, 0.1, 0.1),
        position: Vector3(0.0, 0.0, 0.0),
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );
    }

    bool? didAddNodeToAnchor = await arObjectManager!.addNode(newNode, planeAnchor: anchor);
    if (didAddNodeToAnchor!) {
      nodes.add(newNode);
      setState(() {
        _info = '🎯 Conteúdo AR carregado baseado no QR Code!';
      });
    } else {
      setState(() {
        _info = '❌ Erro ao carregar conteúdo AR';
      });
    }
  }

  void _toggleMode() {
    _setMode(!_useScanner);
  }

  void _setMode(bool useScanner) {
    setState(() {
      _useScanner = useScanner;
      if (_useScanner) {
        _info = 'Scanner ativo - Escaneie QR Code';
      } else {
        _info = _arInitialized 
          ? 'AR ativo - Toque numa superfície' 
          : 'Inicializando AR...';
      }
    });
  }

  void _clearAR() async {
    for (var anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();
    nodes.clear();
    setState(() {
      _info = '🗑️ AR limpo! Toque para recolocar';
    });
  }
}