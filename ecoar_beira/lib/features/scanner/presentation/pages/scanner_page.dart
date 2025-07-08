// lib/features/scanner/presentation/pages/scanner_page.dart
import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:ecoar_beira/features/ar/utils/ar_compatibility_checker.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  
  bool isScanning = true;
  bool hasPermission = false;
  bool isFlashOn = false;
  bool isProcessingQR = false;
  
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkCameraPermission();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Theme.of(context).platform == TargetPlatform.android) {
      controller?.pauseCamera();
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    controller?.dispose();
    super.dispose();
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

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final result = await Permission.camera.request();
      setState(() {
        hasPermission = result.isGranted;
      });
    } else {
      setState(() {
        hasPermission = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return _buildPermissionScreen();
    }

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
          // QR Camera View
          _buildQRView(),
          
          // Scanning Overlay
          _buildScanningOverlay(),
          
          // Instructions
          _buildInstructions(),
          
          // Processing Overlay
          if (isProcessingQR) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPermissionScreen() {
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
                Icons.camera_alt,
                size: 80,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 24),
              const Text(
                'Permissão de Câmera Necessária',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Para escanear códigos QR e usar experiências AR, precisamos acessar sua câmera.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _checkCameraPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Permitir Acesso à Câmera',
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

  Widget _buildQRView() {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.transparent,
        borderRadius: 12,
        borderLength: 0,
        borderWidth: 0,
        cutOutSize: 280,
      ),
      onPermissionSet: (ctrl, hasPermission) {
        setState(() {
          this.hasPermission = hasPermission;
        });
      },
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
            // Corner indicators
            ..._buildCornerIndicators(),
            
            // Scanning line
            if (isScanning) _buildScanLine(),
            
            // Pulse effect
            _buildPulseEffect(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerIndicators() {
    return [
      // Top-left
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
      // Top-right
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
      // Bottom-left
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
      // Bottom-right
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
                    'Posicione o código QR dentro da área de escaneamento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Encontre os marcadores nos parques da Beira para começar experiências AR incríveis!',
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
                      _buildActionButton(
                        Icons.view_in_ar,
                        'Sobre AR',
                        () => context.go('/ar-compatibility'),
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
              'Verificando compatibilidade AR...',
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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && isScanning && !isProcessingQR) {
        _handleQRCode(scanData.code!);
      }
    });
  }

  Future<void> _handleQRCode(String qrCode) async {
    if (isProcessingQR) return;

    // Pause scanning to prevent multiple scans
    setState(() {
      isScanning = false;
      isProcessingQR = true;
    });
    controller?.pauseCamera();

    AppLogger.i('QR Code scanned: $qrCode');

    try {
      // Check AR compatibility before proceeding
      final compatibilityResult = await ARCompatibilityChecker.instance.checkCompatibility();
      
      setState(() {
        isProcessingQR = false;
      });

      if (!compatibilityResult.isSupported) {
        _showARCompatibilityDialog(compatibilityResult);
        return;
      }

      // Validate QR code format
      if (!_isValidQRCode(qrCode)) {
        _showInvalidQRDialog(qrCode);
        return;
      }

      // Show success dialog
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
    // Check if QR code matches expected patterns
    final validPatterns = [
      RegExp(r'^bacia[1-3]_\d{3}$'),           // bacia1_001, bacia2_002, etc.
      RegExp(r'^https://ecoar-beira\.app/'),   // Web URLs
      RegExp(r'^ecoar://'),                    // Deep links
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
            Text('Marcador Encontrado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.view_in_ar,
                    color: AppTheme.successGreen,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Código: $qrCode',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preparando experiência AR educativa...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/ar/$qrCode');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar AR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showARCompatibilityDialog(ARCompatibilityResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningOrange, size: 28),
            SizedBox(width: 12),
            Text('AR Não Disponível'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.reason,
              style: const TextStyle(fontSize: 16),
            ),
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recomendações:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...result.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: [
          if (result.canInstall)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/ar-compatibility');
              },
              child: const Text('Verificar Compatibilidade'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeScanning();
            },
            child: const Text('Continuar Escaneando'),
          ),
        ],
      ),
    );
  }

  void _showInvalidQRDialog(String qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppTheme.primaryBlue, size: 28),
            SizedBox(width: 12),
            Text('Código QR Inválido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Código escaneado: $qrCode'),
            const SizedBox(height: 12),
            const Text(
              'Este não é um marcador válido do EcoAR Beira. Procure por marcadores oficiais nos parques da cidade.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/map'),
            child: const Text('Ver Mapa'),
          ),
          ElevatedButton(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error, color: AppTheme.errorRed, size: 28),
            SizedBox(width: 12),
            Text('Erro'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help, color: AppTheme.primaryBlue, size: 28),
            SizedBox(width: 12),
            Text('Como Usar o Scanner'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📱 Como escanear:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Posicione o código QR dentro da área verde'),
              Text('• Mantenha a câmera estável'),
              Text('• Certifique-se de ter boa iluminação'),
              SizedBox(height: 16),
              Text(
                '🗺️ Onde encontrar marcadores:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Bacia 1: Biodiversidade'),
              Text('• Bacia 2: Recursos Hídricos'),
              Text('• Bacia 3: Agricultura Urbana'),
              SizedBox(height: 16),
              Text(
                '🎯 O que você pode fazer:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Explorar objetos 3D em AR'),
              Text('• Ganhar pontos e badges'),
              Text('• Aprender sobre sustentabilidade'),
              Text('• Completar desafios educativos'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/map'),
            child: const Text('Ver Mapa'),
          ),
          ElevatedButton(
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
        controller?.resumeCamera();
        _animationController.repeat();
      } else {
        controller?.pauseCamera();
        _animationController.stop();
      }
    });
  }

  void _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() {
        isFlashOn = !isFlashOn;
      });
    }
  }

  void _resumeScanning() {
    setState(() {
      isScanning = true;
      isProcessingQR = false;
    });
    controller?.resumeCamera();
    _animationController.repeat();
  }
}