import 'dart:io';
import 'dart:async';
import 'package:ecoar_beira/core/models/ar_scene_model.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:ecoar_beira/features/ar/data/repositories/ar_scene_repository.dart';
import 'package:ecoar_beira/features/ar/domain/services/ar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart' as arcore;
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart' as ar_plugin;
import 'package:audioplayers/audioplayers.dart';


class RealARExperiencePage extends StatefulWidget {
  final String markerId;
  
  const RealARExperiencePage({
    super.key,
    required this.markerId,
  });

  @override
  State<RealARExperiencePage> createState() => _RealARExperiencePageState();
}

class _RealARExperiencePageState extends State<RealARExperiencePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // AR Service
  final ARService _arService = ARService.instance;
  final ARSceneRepository _sceneRepository = ARSceneRepository();
  
  // Controllers
  late AnimationController _loadingController;
  late AnimationController _uiController;
  StreamSubscription<AREvent>? _arEventSubscription;
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // State
  bool _isLoading = true;
  bool _isARReady = false;
  bool _showInstructions = true;
  bool _hasError = false;
  String _errorMessage = '';
  ARSceneModel? _currentScene;
  int _pointsEarned = 0;
  
  // UI State
  bool _showUI = true;
  Timer? _uiHideTimer;

  @override
  void initState() {
    super.initState();
   WidgetsBinding.instance.addObserver(this);
    
    // Lock orientation for AR
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _setupAnimations();
    _initializeAR();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _arService.pauseSession();
        break;
      case AppLifecycleState.resumed:
        _arService.resumeSession();
        break;
      default:
        break;
    }
  }

  void _setupAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _uiController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initializeAR() async {
    try {
      AppLogger.i('Initializing AR experience for marker: ${widget.markerId}');
      
      // Initialize AR Service
      final initialized = await _arService.initialize();
      if (!initialized) {
        _showError('Falha ao inicializar AR');
        return;
      }

      // Start AR session
      final sessionStarted = await _arService.startSession(
        enablePlaneDetection: true,
        enableLightEstimation: true,
        enableImageTracking: false,
      );
      
      if (!sessionStarted) {
        _showError('Falha ao iniciar sessão AR');
        return;
      }

      // Load scene for this marker
      await _loadScene();

      // Subscribe to AR events
      _subscribeToAREvents();

      setState(() {
        _isLoading = false;
        _isARReady = true;
      });

      _uiController.forward();
      _startInstructionTimer();

    } catch (e, stackTrace) {
      AppLogger.e('Error initializing AR', e, stackTrace);
      _showError('Erro ao carregar experiência AR');
    }
  }

  Future<void> _loadScene() async {
    try {
      final scene = await _sceneRepository.getSceneByMarkerId(widget.markerId);
      if (scene == null) {
        throw Exception('Scene not found for marker: ${widget.markerId}');
      }

      _currentScene = scene;
      await _arService.loadScene(scene);

      AppLogger.i('Scene loaded: ${scene.name}');

    } catch (e, stackTrace) {
      AppLogger.e('Error loading scene', e, stackTrace);
      throw Exception('Falha ao carregar cena AR');
    }
  }

  void _subscribeToAREvents() {
    _arEventSubscription = _arService.eventStream.listen((event) {
      _handleAREvent(event);
    });
  }

  void _handleAREvent(AREvent event) {
    switch (event.runtimeType) {
      case ARObjectTappedEvent:
        final e = event as ARObjectTappedEvent;
        _onObjectTapped(e.objectId);
        break;
      case ARPointsEarnedEvent:
        final e = event as ARPointsEarnedEvent;
        _onPointsEarned(e.points);
        break;
      case ARDialogRequestedEvent:
        final e = event as ARDialogRequestedEvent;
        _showInfoDialog(e.title, e.message);
        break;
      case ARSoundPlayedEvent:
        final e = event as ARSoundPlayedEvent;
        _playSound(e.soundId);
        break;
      case ARErrorEvent:
        final e = event as ARErrorEvent;
        _showError(e.message);
        break;
    }
  }

  void _onObjectTapped(String objectId) {
    AppLogger.d('AR object tapped: $objectId');
    _showTapFeedback();
    _resetUITimer();
  }

  void _onPointsEarned(int points) {
    setState(() {
      _pointsEarned += points;
    });
    _showPointsAnimation(points);
  }

  void _showTapFeedback() {
    // Show visual feedback for tap
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Objeto descoberto!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPointsAnimation(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PointsEarnedDialog(points: points),
    ).then((_) {
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  void _playSound(String soundId) async {
    try {
      // Play sound based on soundId
      // This would map to actual audio files
      await _audioPlayer.play(AssetSource('audio/$soundId.mp3'));
    } catch (e) {
      AppLogger.e('Error playing sound: $soundId', e);
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _startInstructionTimer() {
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showInstructions = false;
        });
      }
    });
  }

  void _resetUITimer() {
    _uiHideTimer?.cancel();
    if (!_showUI) {
      setState(() {
        _showUI = true;
      });
      _uiController.forward();
    }
    
    _uiHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showUI = false;
        });
        _uiController.reverse();
      }
    });
  }

  void _cleanup() async {
    try {
      _loadingController.dispose();
      _uiController.dispose();
      _arEventSubscription?.cancel();
      _uiHideTimer?.cancel();
      await _audioPlayer.dispose();
      await _arService.stopSession();
    } catch (e) {
      AppLogger.e('Error during cleanup', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // AR View
          _buildARView(),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
          
          // Error overlay
          if (_hasError) _buildErrorOverlay(),
          
          // UI overlay
          if (_isARReady && !_hasError) _buildUIOverlay(),
          
          // Exit button
          _buildExitButton(),
        ],
      ),
    );
  }

  Widget _buildARView() {
    if (Platform.isAndroid) {
      return _buildARCoreView();
    } else if (Platform.isIOS) {
      return _buildARKitView();
    } else {
      return _buildUnsupportedPlatform();
    }
  }

  Widget _buildARCoreView() {
    return GestureDetector(
    onTap: () {
      // Handle tap events here
      _handleARCoreTap([]);
    },
    child: arcore.ArCoreView(
      onArCoreViewCreated: (arcore.ArCoreController controller) {
        _arService.setArCoreController(controller);
        AppLogger.d('ARCore view created');
      },
      enableTapRecognizer: true,
      enablePlaneRenderer: true,
      enableUpdateListener: true,
    ),
  );
    // return arcore.ArCoreView(
    //   onArCoreViewCreated: (arcore.ArCoreController controller) {
    //     _arService.setArCoreController(controller);
    //     AppLogger.d('ARCore view created');
    //   },
    //   enableTapRecognizer: true,
    //   enablePlaneRenderer: true,
    //   enableUpdateListener: true,
    //   // onTap: (hits) {
    //   //   _handleARCoreTap(hits);
    //   // },
    //   // onPlaneDetected: (plane) {
    //   //   AppLogger.d('Plane detected in ARCore');
    //   // },
    // );
  }

  Widget _buildARKitView() {
    return ar_plugin.ARView(
      onARViewCreated: (ar_plugin.ARSessionManager arSessionManager) {
        // Handle ARKit session creation
        AppLogger.d('ARKit view created');
      },
    );
  }

  Widget _buildUnsupportedPlatform() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'AR não suportado nesta plataforma',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  void _handleARCoreTap(List<arcore.ArCoreHitTestResult> hits) {
    if (hits.isNotEmpty) {
      final hit = hits.first;
      
      // Find which object was tapped
      final objectId = _findObjectAtPosition(hit.pose.translation);
      if (objectId != null) {
        _arService.onObjectTapped(objectId);
      }
    }
    
    _resetUITimer();
  }

  String? _findObjectAtPosition(arcore.Vector3 position) {
    // This would implement collision detection logic
    // For now, return a mock object ID
    return 'tree_001';
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _loadingController,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Carregando Experiência AR...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Marker: ${widget.markerId}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              backgroundColor: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 24),
              const Text(
                'Erro na Experiência AR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                    ),
                    child: const Text('Voltar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                      });
                      _initializeAR();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUIOverlay() {
    return FadeTransition(
      opacity: _uiController,
      child: Column(
        children: [
          // Top info bar
          _buildTopInfoBar(),
          
          const Spacer(),
          
          // Instructions
          if (_showInstructions) _buildInstructions(),
          
          // Bottom action bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildTopInfoBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentScene?.name ?? 'Experiência AR',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Marker: ${widget.markerId}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_pointsEarned > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$_pointsEarned pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Aponte a câmera para superfícies planas e toque nos objetos 3D para interagir!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            Icons.camera_alt,
            'Foto',
            () => _takeARPhoto(),
          ),
          _buildActionButton(
            Icons.info_outline,
            'Info',
            () => _showSceneInfo(),
          ),
          _buildActionButton(
            Icons.quiz,
            'Quiz',
            () => _startQuiz(),
          ),
          _buildActionButton(
            Icons.refresh,
            'Reset',
            () => _resetScene(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExitButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _exitAR(),
        ),
      ),
    );
  }

  void _takeARPhoto() async {
    try {
      AppLogger.d('Taking AR photo');
      HapticFeedback.mediumImpact();
      
      // Implement AR photo capture
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto AR capturada!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      
      _resetUITimer();
    } catch (e) {
      AppLogger.e('Error taking AR photo', e);
    }
  }

  void _showSceneInfo() {
    if (_currentScene == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ARSceneInfoBottomSheet(scene: _currentScene!),
    );
  }

  void _startQuiz() {
    context.go('/challenge/ar_quiz_${widget.markerId}');
  }

  void _resetScene() async {
    try {
      setState(() {
        _pointsEarned = 0;
      });
      
      await _arService.clearScene();
      await _loadScene();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cena reiniciada!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } catch (e) {
      AppLogger.e('Error resetting scene', e);
    }
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exitAR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Experiência AR?'),
        content: const Text('Seu progresso será salvo automaticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

// Supporting widgets
class PointsEarnedDialog extends StatefulWidget {
  final int points;
  
  const PointsEarnedDialog({super.key, required this.points});

  @override
  State<PointsEarnedDialog> createState() => _PointsEarnedDialogState();
}

class _PointsEarnedDialogState extends State<PointsEarnedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 0.1,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '+${widget.points}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'pontos!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ARSceneInfoBottomSheet extends StatelessWidget {
  final ARSceneModel scene;
  
  const ARSceneInfoBottomSheet({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              scene.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              scene.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // Objects count
            Row(
              children: [
                const Icon(Icons.view_in_ar, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text('${scene.objects.length} objetos AR'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Duration
            Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('Duração: ${scene.maxDuration.inMinutes} min'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
