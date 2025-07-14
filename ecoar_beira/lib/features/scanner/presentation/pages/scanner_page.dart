import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late MobileScannerController scannerController;
  StreamSubscription<Object?>? _subscription;
  
  bool isScanning = true;
  bool isFlashOn = false;
  bool isProcessingQR = false;
  bool _isInitialized = false;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    _initializeScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeScanning();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _pauseScanning();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeScanner() async {
    try {
      AppLogger.i('Inicializando mobile scanner...');
      
      scannerController = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        formats: [BarcodeFormat.qrCode],
      );

      if (!scannerController.isStarting) {
        await scannerController.start();
      } else {
        AppLogger.i('Mobile scanner já estava iniciado');
      }
      
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
      
      AppLogger.i('Mobile scanner inicializado com sucesso!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanner carregado! 📱'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e, stackTrace) {
      AppLogger.e('Erro ao inicializar scanner', e, stackTrace);
      setState(() {
        _errorMessage = 'Erro ao carregar câmera: $e';
      });
    }
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (!isScanning || isProcessingQR) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        AppLogger.i('QR Code detectado: ${barcode.rawValue}');
        _handleQRCode(barcode.rawValue!);
        break; // Processa apenas o primeiro código válido
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }
    
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }
    
    return _buildMainScanner();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            SizedBox(height: 24),
            Text(
              'Carregando scanner...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Erro no Scanner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Erro desconhecido',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isInitialized = false;
                  });
                  _initializeScanner();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Tentar Novamente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Voltar para Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScanner() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleScanning,
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_off : Icons.flash_on),
            onPressed: _toggleFlash,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            color: Colors.white,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mobile Scanner Camera View
          MobileScanner(
            controller: scannerController,
            onDetect: _onBarcodeDetect,
            overlay: Container(), // Overlay transparente
          ),
          
          // Scanning Overlay
          if (isScanning) _buildScanningOverlay(),
          
          // Instructions
          _buildInstructions(),
          
          // Processing Overlay
          if (isProcessingQR) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
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
            ..._buildCornerIndicators(),
            if (isScanning) _buildScanLine(),
            _buildPulseEffect(),
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

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return Positioned(
          top: _scanLineAnimation.value * 260,
          left: 10,
          right: 10,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryGreen,
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseEffect() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Center(
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: AppTheme.primaryGreen,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Posicione o código QR dentro da área verde',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Encontre os marcadores nos parques da Beira para experiências AR!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.map,
                        'Ver Mapa',
                        () => context.go('/map'),
                      ),
                      _buildActionButton(
                        Icons.help,
                        'Ajuda',
                        _showHelpDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.5),
          ),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
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
              'Processando código QR...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (isProcessingQR) return;

    setState(() {
      isScanning = false;
      isProcessingQR = true;
    });
    
    _pauseScanning();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        isProcessingQR = false;
      });

      if (!_isValidQRCode(qrCode)) {
        _showInvalidQRDialog(qrCode);
        return;
      }

      _showSuccessDialog(qrCode);

    } catch (e, stackTrace) {
      AppLogger.e('Error processing QR code', e, stackTrace);
      setState(() {
        isProcessingQR = false;
      });
      _showErrorDialog('Erro ao processar código QR');
    }
  }

  bool _isValidQRCode(String qrCode) {
    final validPatterns = [
      RegExp(r'^bacia[1-3]_\d{3}$'),
      RegExp(r'^https://ecoar-beira\.app/'),
      RegExp(r'^ecoar://'),
    ];
    return validPatterns.any((pattern) => pattern.hasMatch(qrCode));
  }

  void _showSuccessDialog(String qrCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
            SizedBox(width: 12),
            Text('Código QR Encontrado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Código: $qrCode'),
            const SizedBox(height: 16),
            const Text('Preparando experiência AR...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeScanning();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/ar/$qrCode');
            },
            child: const Text('Iniciar AR'),
          ),
        ],
      ),
    );
  }

  void _showInvalidQRDialog(String qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código QR Inválido'),
        content: Text('Código: $qrCode\n\nEste não é um marcador válido do EcoAR Beira.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeScanning();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeScanning();
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como Usar o Scanner'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📱 Como escanear:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Posicione o código QR dentro da área verde'),
              Text('• Mantenha a câmera estável'),
              Text('• Certifique-se de ter boa iluminação'),
              SizedBox(height: 16),
              Text('🗺️ Onde encontrar marcadores:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Bacia 1: Biodiversidade'),
              Text('• Bacia 2: Recursos Hídricos'),
              Text('• Bacia 3: Agricultura Urbana'),
              SizedBox(height: 16),
              Text('✨ Dicas:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Use a lanterna se estiver escuro'),
              Text('• Mantenha distância de ~30cm do QR'),
              Text('• O código será detectado automaticamente'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _toggleScanning() {
    setState(() {
      isScanning = !isScanning;
      if (isScanning) {
        _resumeScanning();
      } else {
        _pauseScanning();
      }
    });
  }

  void _toggleFlash() async {
    try {
      await scannerController.toggleTorch();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      AppLogger.e('Erro ao alternar flash', e);
    }
  }

  void _resumeScanning() {
    setState(() {
      isScanning = true;
      isProcessingQR = false;
    });
    scannerController.start();
    _animationController.repeat();
  }

  void _pauseScanning() {
    scannerController.stop();
    _animationController.stop();
  }
}