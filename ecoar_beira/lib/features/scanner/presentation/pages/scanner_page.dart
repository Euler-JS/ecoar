import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:ecoar_beira/features/ar/utils/ar_compatibility_checker.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  
  bool isScanning = true;
  bool hasPermission = false;
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
    _initializeCamera();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
      } else if (Platform.isIOS) {
        controller!.resumeCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pulseController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (hasPermission) {
          controller!.resumeCamera();
        } else {
          _checkCameraPermission();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        controller!.pauseCamera();
        break;
      case AppLifecycleState.detached:
        controller!.dispose();
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

  Future<void> _initializeCamera() async {
    AppLogger.i('Inicializando câmera...');
    
    try {
      await _checkCameraPermission();
      
      if (hasPermission) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
        AppLogger.i('Câmera inicializada com sucesso');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Erro ao inicializar câmera', e, stackTrace);
      setState(() {
        _errorMessage = 'Erro ao inicializar câmera: $e';
        hasPermission = false;
      });
    }
  }

  Future<void> _checkCameraPermission() async {
    AppLogger.i('Verificando permissões da câmera...');
    
    try {
      final status = await Permission.camera.status;
      AppLogger.i('Status atual da permissão: $status');
      
      if (status.isGranted) {
        setState(() {
          hasPermission = true;
          _errorMessage = null;
        });
        return;
      }
      
      if (status.isDenied) {
        AppLogger.i('Solicitando permissão de câmera...');
        final result = await Permission.camera.request();
        AppLogger.i('Resultado da solicitação: $result');
        
        setState(() {
          hasPermission = result.isGranted;
          if (!result.isGranted) {
            _errorMessage = 'Permissão de câmera negada';
          }
        });
        
        if (result.isGranted) {
          // Pequeno delay para garantir que a permissão foi aplicada
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {});
          }
        }
      } else if (status.isPermanentlyDenied) {
        AppLogger.w('Permissão de câmera permanentemente negada');
        setState(() {
          hasPermission = false;
          _errorMessage = 'Permissão de câmera permanentemente negada';
        });
        _showPermissionDeniedDialog();
      }
    } catch (e, stackTrace) {
      AppLogger.e('Erro ao verificar permissão de câmera', e, stackTrace);
      setState(() {
        hasPermission = false;
        _errorMessage = 'Erro ao verificar permissões: $e';
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningOrange, size: 28),
            SizedBox(width: 12),
            Text('Permissão Necessária'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para usar o scanner QR, você precisa permitir o acesso à câmera.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Passos para ativar:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Toque em "Abrir Configurações"'),
            Text('2. Encontre "EcoAR Beira" na lista'),
            Text('3. Ative a permissão de "Câmera"'),
            Text('4. Volte ao aplicativo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }
    
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Inicializando câmera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ],
        ),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
      onPermissionSet: (ctrl, p) => _onPermissionSet(ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    AppLogger.i('QR View criada com sucesso');
    
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && isScanning && !isProcessingQR) {
        AppLogger.i('QR Code detectado: ${scanData.code}');
        _handleQRCode(scanData.code!);
      }
    });
  }

  void _onPermissionSet(QRViewController controller, bool p) {
    AppLogger.i('Permissão configurada: $p');
    if (!p) {
      AppLogger.e('Permissão negada pelo QR View');
      setState(() {
        hasPermission = false;
        _errorMessage = 'Permissão de câmera negada';
      });
    }
  }

  // Resto dos métodos permanecem iguais...
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
    controller?.pauseCamera();

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      
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
      try {
        await controller!.toggleFlash();
        setState(() {
          isFlashOn = !isFlashOn;
        });
      } catch (e) {
        AppLogger.e('Erro ao alternar flash', e);
      }
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