import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecoar_beira/core/models/ar_scene_model.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:ecoar_beira/features/ar/data/repositories/ar_scene_repository.dart';

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
  
  // Repositories
  final ARSceneRepository _sceneRepository = ARSceneRepository();
  
  // Mobile Scanner (mesma tecnologia que funciona no QR)
  MobileScannerController? _mobileScannerController;
  
  // Controllers
  late AnimationController _loadingController;
  late AnimationController _uiController;
  
  // State
  bool _isLoading = true;
  bool _isReady = false;
  bool _showInstructions = true;
  bool _hasError = false;
  String _errorMessage = '';
  ARSceneModel? _currentScene;
  int _pointsEarned = 0;
  
  // AR Objects simulados
  List<MockARObject> _mockObjects = [];
  Timer? _objectSpawnTimer;
  
  // UI State
  bool _showUI = true;
  Timer? _uiHideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _setupAnimations();
    _initializeExperience();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    
    _cleanup();
    super.dispose();
  }

  void _setupAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _uiController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initializeExperience() async {
    try {
      AppLogger.i('Initializing Mobile Scanner AR experience for marker: ${widget.markerId}');
      
      // Load scene
      await _loadScene();
      
      // Initialize mobile scanner (tecnologia comprovada)
      await _initializeMobileScanner();
      
      setState(() {
        _isLoading = false;
        _isReady = true;
      });

      _uiController.forward();
      _startInstructionTimer();
      _startMockARObjects();

    } catch (e, stackTrace) {
      AppLogger.e('Error initializing experience', e, stackTrace);
      _showError('Erro ao carregar experiência AR: $e');
    }
  }

  Future<void> _initializeMobileScanner() async {
    try {
      AppLogger.i('Initializing mobile_scanner (same as working QR scanner)...');
      
      await Future.delayed(const Duration(milliseconds: 1500));

      // Configuração EXATA do scanner QR que funciona
      _mobileScannerController = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        formats: [BarcodeFormat.qrCode],
      );
      
      await _mobileScannerController!.start();
      
      AppLogger.i('Mobile scanner initialized successfully for AR!');

      if (!mounted) return;
      
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing mobile scanner', e, stackTrace);
      throw Exception('Falha ao inicializar câmera: $e');
    }
  }

  Future<void> _loadScene() async {
    try {
      final scene = await _sceneRepository.getSceneByMarkerId(widget.markerId);
      if (scene == null) {
        throw Exception('Scene not found for marker: ${widget.markerId}');
      }

      _currentScene = scene;
      AppLogger.i('Scene loaded: ${scene.name}');

    } catch (e, stackTrace) {
      AppLogger.e('Error loading scene', e, stackTrace);
      throw Exception('Falha ao carregar cena AR');
    }
  }

  void _startMockARObjects() {
    _objectSpawnTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_mockObjects.length < 6) {
        _spawnMockObject();
      }
    });
  }

  void _spawnMockObject() {
    final random = Random();
    final sceneObjects = _getSceneObjects();
    
    final index = random.nextInt(sceneObjects.length);
    final objectData = sceneObjects[index];
    
    final mockObject = MockARObject(
      id: 'object_${DateTime.now().millisecondsSinceEpoch}',
      emoji: objectData['emoji']!,
      name: objectData['name']!,
      description: objectData['description']!,
      position: Offset(
        random.nextDouble() * 280 + 50,
        random.nextDouble() * 500 + 150,
      ),
      scale: 0.7 + random.nextDouble() * 0.6,
      points: objectData['points'] as int,
    );
    
    setState(() {
      _mockObjects.add(mockObject);
    });
    
    // Auto-remove após 12 segundos
    Timer(const Duration(seconds: 12), () {
      if (mounted) {
        setState(() {
          _mockObjects.removeWhere((obj) => obj.id == mockObject.id);
        });
      }
    });
  }

  List<Map<String, dynamic>> _getSceneObjects() {
    switch (widget.markerId) {
      case 'bacia1_001':
        return [
          {'emoji': '🌳', 'name': 'Baobá', 'description': 'Árvore da vida com mais de 1000 anos', 'points': 75},
          {'emoji': '🐦', 'name': 'Bem-te-vi', 'description': 'Ave símbolo da biodiversidade local', 'points': 50},
          {'emoji': '🌱', 'name': 'Strelitzia', 'description': 'Planta tropical endêmica', 'points': 40},
          {'emoji': '🦋', 'name': 'Borboleta', 'description': 'Polinizador essencial do ecossistema', 'points': 30},
        ];
      case 'bacia2_001':
        return [
          {'emoji': '💧', 'name': 'Água Limpa', 'description': 'Recurso vital para a vida', 'points': 60},
          {'emoji': '🌊', 'name': 'Ciclo da Água', 'description': 'Processo natural de renovação', 'points': 80},
          {'emoji': '🐟', 'name': 'Peixe Nativo', 'description': 'Indicador de qualidade da água', 'points': 45},
          {'emoji': '🪴', 'name': 'Aguapé', 'description': 'Planta aquática purificadora', 'points': 35},
        ];
      case 'bacia3_001':
        return [
          {'emoji': '🌾', 'name': 'Horta Urbana', 'description': 'Agricultura sustentável na cidade', 'points': 70},
          {'emoji': '🥬', 'name': 'Vegetais', 'description': 'Alimentos frescos locais', 'points': 40},
          {'emoji': '🏗️', 'name': 'Compostor', 'description': 'Sistema de reciclagem orgânica', 'points': 55},
          {'emoji': '🌿', 'name': 'Ervas', 'description': 'Plantas medicinais tradicionais', 'points': 30},
        ];
      default:
        return [
          {'emoji': '🌍', 'name': 'Planeta', 'description': 'Nossa casa comum', 'points': 100},
          {'emoji': '♻️', 'name': 'Reciclagem', 'description': 'Economia circular', 'points': 50},
        ];
    }
  }

  void _startInstructionTimer() {
    Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showInstructions = false;
        });
      }
    });
  }

  void _cleanup() async {
    try {
      _loadingController.dispose();
      _uiController.dispose();
      _uiHideTimer?.cancel();
      _objectSpawnTimer?.cancel();
      
      if (_mobileScannerController != null) {
        _mobileScannerController!.dispose();
        _mobileScannerController = null;
      }
      
      AppLogger.i('AR Experience cleanup completed successfully.');
    } catch (e) {
      AppLogger.e('Error during cleanup', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera background (mobile_scanner)
          _buildCameraBackground(),
          
          // AR Objects overlay
          if (_isReady) _buildMockARObjects(),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
          
          // Error overlay
          if (_hasError) _buildErrorOverlay(),
          
          // UI overlay
          if (_isReady && !_hasError) _buildUIOverlay(),
          
          // Exit button
          _buildExitButton(),
        ],
      ),
    );
  }

  Widget _buildCameraBackground() {
    if (_mobileScannerController == null) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      ),
    );
  }

    return SizedBox.expand(
      child: MobileScanner(
        controller: _mobileScannerController!,
        onDetect: (capture) {
          // Camera rodando mas não detectando QR codes 
          // Apenas fornecendo fundo da câmera para objetos AR
        },
        overlay: Container(), // Overlay transparente para objetos AR
      ),
    );
  }

  Widget _buildMockARObjects() {
    return Stack(
      children: _mockObjects.map((obj) => _buildMockObject(obj)).toList(),
    );
  }

  Widget _buildMockObject(MockARObject obj) {
    return Positioned(
      left: obj.position.dx,
      top: obj.position.dy,
      child: GestureDetector(
        onTap: () => _onMockObjectTapped(obj),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: obj.scale * value,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.6),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      obj.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    Text(
                      obj.name,
                      style: const TextStyle(
                        fontSize: 8, 
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onMockObjectTapped(MockARObject obj) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _pointsEarned += obj.points;
      _mockObjects.removeWhere((o) => o.id == obj.id);
    });
    
    _showPointsAnimation(obj.points);
    _showObjectInfoDialog(obj);
  }

  void _showPointsAnimation(int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 56),
                    const SizedBox(height: 20),
                    Text(
                      '+$points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'pontos!',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _showObjectInfoDialog(MockARObject obj) {
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Text(obj.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    obj.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obj.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Você ganhou ${obj.points} pontos!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuar Explorando'),
              ),
            ],
          ),
        );
      }
    });
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
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inicializando Experiência AR...',
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
            const SizedBox(height: 8),
            const Text(
              'Usando tecnologia Mobile Scanner',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
                      _initializeExperience();
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
          _buildTopInfoBar(),
          const Spacer(),
          if (_showInstructions) _buildInstructions(),
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
              Row(
                children: [
                  Text(
                    'Marker: ${widget.markerId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Mobile Scanner AR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
        'Objetos educativos aparecerão automaticamente na tela - toque neles para aprender e ganhar pontos!',
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
          _buildActionButton(Icons.camera_alt, 'Foto', () => _takePhoto()),
          _buildActionButton(Icons.info_outline, 'Info', () => _showSceneInfo()),
          _buildActionButton(Icons.quiz, 'Quiz', () => _startQuiz()),
          _buildActionButton(Icons.refresh, 'Reset', () => _resetScene()),
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
          onPressed: () => _exitExperience(),
        ),
      ),
    );
  }

  void _takePhoto() async {
    try {
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Foto Mobile Scanner AR capturada!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      
    } catch (e) {
      AppLogger.e('Error taking photo', e);
    }
  }

  void _showSceneInfo() {
    if (_currentScene == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              Text(
                _currentScene!.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _currentScene!.description,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  const Text('Mobile Scanner AR Ativo'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timeline, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Text('${_mockObjects.length} objetos na tela'),
                ],
              ),
              const SizedBox(height: 20),
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
      ),
    );
  }

  void _startQuiz() {
    context.go('/challenge/ar_quiz_${widget.markerId}');
  }

  void _resetScene() async {
    try {
      setState(() {
        _pointsEarned = 0;
        _mockObjects.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Experiência reiniciada!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } catch (e) {
      AppLogger.e('Error resetting scene', e);
    }
  }

  void _exitExperience() {
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
            Navigator.of(context).pop(); // Remove o diálogo
            // Verificar se pode fazer pop, senão vai para home
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home'); // Vai para home se não pode fazer pop
            }
          },
          child: const Text('Sair'),
        ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });
  }
}

class MockARObject {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final Offset position;
  final double scale;
  final int points;

  MockARObject({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.position,
    required this.scale,
    required this.points,
  });
}