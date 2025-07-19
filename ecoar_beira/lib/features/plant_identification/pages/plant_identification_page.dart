// lib/features/plant_identification/presentation/pages/plant_identification_page.dart
import 'dart:io';
import 'package:ecoar_beira/features/plant_identification/widgets/plant_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:ecoar_beira/features/plant_identification/data/services/plantnet_service.dart';
import 'package:ecoar_beira/features/plant_identification/data/repositories/local_plant_knowledge.dart';

class PlantIdentificationPage extends StatefulWidget {
  const PlantIdentificationPage({super.key});

  @override
  State<PlantIdentificationPage> createState() => _PlantIdentificationPageState();
}

class _PlantIdentificationPageState extends State<PlantIdentificationPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // Serviços
  late PlantNetService _plantNetService;
  final LocalPlantKnowledge _localKnowledge = LocalPlantKnowledge.instance;
  
  // Camera
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  
  // Controles de estado
  bool _isCameraInitialized = false;
  bool _isIdentifying = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Seleções do usuário
  PlantOrgan _selectedOrgan = PlantOrgan.leaf;
  List<PlantModifier> _selectedModifiers = [PlantModifier.planted];
  
  // Animações
  late AnimationController _cameraAnimationController;
  late AnimationController _resultAnimationController;
  late Animation<double> _cameraFadeAnimation;
  late Animation<Offset> _resultSlideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // TODO: Adicionar sua API key aqui
    _plantNetService = PlantNetService(apiKey: 'YOUR_PLANTNET_API_KEY');
    
    _setupAnimations();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraAnimationController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _cameraAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cameraFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cameraAnimationController, curve: Curves.easeIn),
    );

    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultAnimationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('Nenhuma câmera disponível');
      }

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _cameraAnimationController.forward();
      }
      
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing camera', e, stackTrace);
      setState(() {
        _hasError = true;
        _errorMessage = 'Erro ao inicializar câmera: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('🌱 Identificar Planta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _hasError ? _buildErrorScreen() : _buildCameraScreen(),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
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
              'Erro na Câmera',
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
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                });
                _initializeCamera();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        FadeTransition(
          opacity: _cameraFadeAnimation,
          child: SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),
        ),
        
        // Camera Overlay
        _buildCameraOverlay(),
        
        // Controls
        _buildControls(),
        
        // Loading overlay
        if (_isIdentifying) _buildIdentifyingOverlay(),
      ],
    );
  }

  Widget _buildCameraOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryGreen,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corner indicators
            ..._buildCornerIndicators(),
            
            // Center instruction
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
              top: BorderSide(color: AppTheme.primaryGreen, width: 6),
              left: BorderSide(color: AppTheme.primaryGreen, width: 6),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
      Positioned(
        top: -3,
        right: -3,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.primaryGreen, width: 6),
              right: BorderSide(color: AppTheme.primaryGreen, width: 6),
            ),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
          ),
        ),
      ),
      Positioned(
        bottom: -3,
        left: -3,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.primaryGreen, width: 6),
              left: BorderSide(color: AppTheme.primaryGreen, width: 6),
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
          ),
        ),
      ),
      Positioned(
        bottom: -3,
        right: -3,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.primaryGreen, width: 6),
              right: BorderSide(color: AppTheme.primaryGreen, width: 6),
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
          ),
        ),
      ),
    ];
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Top controls - organ selection
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            right: 16,
          ),
          child: Container(
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
                          color: isSelected ? AppTheme.primaryGreen : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGreen : Colors.white.withOpacity(0.3),
                          ),
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
        ),
        
        const Spacer(),
        
        // Bottom controls
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
          child: Column(
            children: [
              // Capture button
              GestureDetector(
                onTap: _isIdentifying ? null : _captureAndIdentify,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isIdentifying ? Colors.grey : AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isIdentifying ? Icons.hourglass_empty : Icons.camera_alt,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isIdentifying ? 'Identificando...' : 'Tocar para Identificar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.collections,
                    'Galeria',
                    _pickFromGallery,
                  ),
                  _buildActionButton(
                    Icons.lightbulb_outline,
                    'Dicas',
                    _showTipsDialog,
                  ),
                  _buildActionButton(
                    Icons.nature,
                    'Plantas Locais',
                    _showLocalPlantsDialog,
                  ),
                ],
              ),
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifyingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            SizedBox(height: 24),
            Text(
              'Analisando planta...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Comparando com base de dados científica',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndIdentify() async {
    if (_isIdentifying || _cameraController == null) return;

    try {
      setState(() {
        _isIdentifying = true;
      });

      HapticFeedback.mediumImpact();
      
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      
      // Identify plant
      final result = await _plantNetService.identifyPlant(
        imageFile: File(imageFile.path),
        organ: _selectedOrgan,
        modifiers: _selectedModifiers,
      );

      if (mounted) {
        setState(() {
          _isIdentifying = false;
        });
        
        _showResultDialog(result, File(imageFile.path));
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error during plant identification', e, stackTrace);
      
      if (mounted) {
        setState(() {
          _isIdentifying = false;
        });
        
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showResultDialog(PlantIdentificationResult result, File imageFile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlantResultSheet(
        result: result,
        imageFile: imageFile,
        localKnowledge: _localKnowledge,
        onPointsEarned: (points) {
          // TODO: Integrate with gamification system
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🌱 +$points pontos ganhos!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        },
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro na Identificação'),
        content: Text('Não foi possível identificar a planta:\n\n$error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tentar Novamente'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showLocalPlantsDialog();
            },
            child: const Text('Ver Plantas Locais'),
          ),
        ],
      ),
    );
  }

  void _pickFromGallery() {
    // TODO: Implement image picker from gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleção da galeria em desenvolvimento'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _showTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌱 Dicas para Melhor Identificação'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📸 Fotografia:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Use boa iluminação natural'),
              Text('• Mantenha câmera estável'),
              Text('• Enquadre apenas a parte selecionada'),
              SizedBox(height: 16),
              Text('🍃 Folhas:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Fotografe folha inteira'),
              Text('• Mostre formato e bordas claramente'),
              Text('• Evite folhas danificadas'),
              SizedBox(height: 16),
              Text('🌸 Flores:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Capture cor e formato'),
              Text('• Inclua centro da flor se possível'),
              Text('• Evite flores murchas'),
              SizedBox(height: 16),
              Text('🌳 Melhor época:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Manhã: melhor luz natural'),
              Text('• Evite meio-dia (sombras duras)'),
              Text('• Estação de chuva: plantas mais viçosas'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _showLocalPlantsDialog() {
    final commonPlants = _localKnowledge.getCommonLocalPlants();
    final iconicPlants = _localKnowledge.getIconicLocalPlants();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌿 Plantas Comuns da Beira'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plantas Icônicas:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...iconicPlants.map((plant) => ListTile(
                  dense: true,
                  title: Text(plant.primaryName),
                  subtitle: Text(plant.importance),
                  leading: const Icon(Icons.star, color: AppTheme.warningOrange),
                )),
                const SizedBox(height: 16),
                const Text('Plantas Comuns:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...commonPlants.take(5).map((plant) => ListTile(
                  dense: true,
                  title: Text(plant.primaryName),
                  subtitle: Text(plant.importance),
                  leading: const Icon(Icons.nature, color: AppTheme.primaryGreen),
                )),
                const SizedBox(height: 16),
                const Text(
                  'Dica: Procure estas plantas nos parques da Beira para ganhar pontos extras!',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como Funciona'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔬 Tecnologia:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Usamos inteligência artificial e base de dados científica do PlantNet para identificar plantas.'),
              SizedBox(height: 16),
              Text('🌍 Cobertura:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Milhões de plantas catalogadas incluindo flora tropical e africana.'),
              SizedBox(height: 16),
              Text('🎯 Precisão:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Melhor precisão com fotos nítidas de folhas ou flores.'),
              SizedBox(height: 16),
              Text('🏆 Pontos:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Ganhe pontos identificando plantas e aprendendo sobre biodiversidade local!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}