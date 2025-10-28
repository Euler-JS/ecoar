import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';

class SimpleARPage extends StatefulWidget {
  final String? qrCode;

  const SimpleARPage({super.key, this.qrCode});

  @override
  State<SimpleARPage> createState() => _SimpleARPageState();
}

class _SimpleARPageState extends State<SimpleARPage> with TickerProviderStateMixin {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  // 3D Controller
  Flutter3DController _controller3D = Flutter3DController();

  // State
  bool _isLoading = true;
  bool _show3DModel = false;
  String _currentInfo = 'Inicializando câmera...';
  double _modelScale = 1.0;
  double _modelRotation = 0.0;

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAR();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeAR() async {
    try {
      // Initialize cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _currentInfo = 'Nenhuma câmera encontrada';
          _isLoading = false;
        });
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium, // Lower resolution for better performance
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _currentInfo = 'Câmera pronta! Toque no botão AR para ver o modelo Albano';
          _isLoading = false;
        });
        _fadeController.forward();
      }

    } catch (e) {
      AppLogger.e('Erro ao inicializar AR', e);
      setState(() {
        _currentInfo = 'Erro ao inicializar câmera: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AR - Modelo Albano'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAR,
            color: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(color: Colors.black),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),

          // 3D Model overlay
          if (_show3DModel) _build3DOverlay(),

          // Controls
          _buildControls(),

          // Info text
          _buildInfoText(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            Text(
              _currentInfo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _hide3DModel,
        onScaleUpdate: _onScaleUpdate,
        onPanUpdate: _onPanUpdate,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Transform.scale(
              scale: _modelScale,
              child: Transform.rotate(
                angle: _modelRotation,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Flutter3DViewer(
                      controller: _controller3D,
                      src: 'assets/ar_models/albano.glb',
                      onLoad: (String modelAddress) {
                        AppLogger.i('Modelo 3D Albano carregado: $modelAddress');
                        _controller3D.setCameraOrbit(0, 0, 2);
                        _controller3D.setCameraTarget(0, 0, 0);
                      },
                      onError: (String error) {
                        AppLogger.e('Erro ao carregar modelo Albano: $error');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _toggle3DModel,
            backgroundColor: AppTheme.primaryGreen,
            child: Icon(_show3DModel ? Icons.visibility_off : Icons.view_in_ar),
          ),
          FloatingActionButton(
            onPressed: _playAnimation,
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.play_arrow),
          ),
          FloatingActionButton(
            onPressed: _takeScreenshot,
            backgroundColor: AppTheme.accentGreen,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText() {
    return Positioned(
      top: 100,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.5),
            ),
          ),
          child: Text(
            _currentInfo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _toggle3DModel() {
    setState(() {
      _show3DModel = !_show3DModel;
      if (_show3DModel) {
        _currentInfo = 'Modelo Albano ativo! Toque para ocultar, arraste para mover';
      } else {
        _currentInfo = 'Câmera pronta! Toque no botão AR para ver o modelo Albano';
      }
    });
  }

  void _hide3DModel() {
    setState(() {
      _show3DModel = false;
      _currentInfo = 'Câmera pronta! Toque no botão AR para ver o modelo Albano';
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_show3DModel) {
      setState(() {
        _modelScale = (_modelScale * details.scale).clamp(0.5, 3.0);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_show3DModel) {
      setState(() {
        _modelRotation += details.delta.dx * 0.01;
      });
    }
  }

  void _playAnimation() {
    if (_show3DModel) {
      _controller3D.playAnimation();
      setState(() {
        _currentInfo = 'Animação do Albano reproduzindo...';
      });
    }
  }

  void _takeScreenshot() {
    // Implementar captura de tela
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Captura de tela não implementada ainda'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _resetAR() {
    setState(() {
      _show3DModel = false;
      _modelScale = 1.0;
      _modelRotation = 0.0;
      _currentInfo = 'AR resetado! Toque no botão para ver o modelo Albano';
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text(
          'Experiência AR - Albano',
          style: TextStyle(color: AppTheme.primaryGreen),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Esta experiência mostra o modelo 3D "Albano" sobreposto à câmera ao vivo:',
                style: TextStyle(color: AppTheme.backgroundLight),
              ),
              SizedBox(height: 12),
              Text(
                '• Câmera ao vivo como fundo',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '• Modelo 3D Albano sobreposto',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '• Interação por toque e gestos',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '• Animações disponíveis',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              SizedBox(height: 16),
              Text(
                'Como usar:',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '1. Toque no botão AR para mostrar Albano',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                '2. Use gestos para interagir (pinch para zoom, arrastar para rotacionar)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                '3. Toque no play para animações',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                '4. Toque no modelo para ocultá-lo',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Entendi',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}