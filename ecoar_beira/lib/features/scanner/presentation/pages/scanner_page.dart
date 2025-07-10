import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Timer? _fallbackTimer;
  Timer? _cameraCheckTimer;
  
  bool isScanning = true;
  bool hasPermission = false;
  bool isFlashOn = false;
  bool isProcessingQR = false;
  bool _isInitialized = false;
  bool _forceCamera = false;
  bool _qrViewWorking = false;
  bool _permissionCheckDisabled = false;
  bool _cameraReady = false;
  String? _errorMessage;
  int _permissionAttempts = 0;
  int _cameraRetryCount = 0;
  
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
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
      }
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _cameraCheckTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.i('App lifecycle state changed: $state');
    
    if (controller == null) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeCameraAfterDelay();
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

  void _resumeCameraAfterDelay() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && controller != null) {
        controller!.resumeCamera();
        _startCameraCheck();
      }
    });
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
    AppLogger.i('Inicializando scanner...');
    
    setState(() {
      _isInitialized = true;
    });
    
    await _checkPermissionOnce();
    
    if (!hasPermission && !_permissionCheckDisabled) {
      _startFallbackTimer();
    }
  }

  Future<void> _checkPermissionOnce() async {
    if (_permissionCheckDisabled) return;
    
    AppLogger.i('Verificando permissão única vez...');
    _permissionAttempts++;
    
    try {
      final status = await Permission.camera.status;
      AppLogger.i('Status da permissão: $status');
      
      if (status.isGranted) {
        AppLogger.i('Permissão concedida!');
        _setPermissionGranted();
        return;
      }
      
      if (status.isDenied && _permissionAttempts == 1) {
        AppLogger.i('Tentando solicitar permissão...');
        final result = await Permission.camera.request();
        AppLogger.i('Resultado da solicitação: $result');
        
        if (result.isGranted) {
          _setPermissionGranted();
          return;
        }
      }
      
      AppLogger.w('Não conseguiu permissão. Tentativas: $_permissionAttempts');
      
      if (_permissionAttempts >= 2) {
        AppLogger.i('Muitas tentativas. Ativando fallback...');
        _permissionCheckDisabled = true;
        setState(() {
          _errorMessage = 'Tentando carregar câmera...';
        });
      }
      
    } catch (e, stackTrace) {
      AppLogger.e('Erro ao verificar permissão', e, stackTrace);
      _permissionCheckDisabled = true;
    }
  }

  void _setPermissionGranted() {
    AppLogger.i('Permissão configurada como concedida');
    setState(() {
      hasPermission = true;
      _errorMessage = null;
    });
    _fallbackTimer?.cancel();
    _permissionCheckDisabled = true;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de câmera concedida! 📸'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startFallbackTimer() {
    AppLogger.i('Iniciando timer de fallback...');
    
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !hasPermission && !_qrViewWorking) {
        AppLogger.i('Fallback timer ativado - forçando câmera');
        _tryForceCamera();
      }
    });
  }

  void _tryForceCamera() {
    AppLogger.i('Tentando forçar carregamento da câmera...');
    
    setState(() {
      _forceCamera = true;
      _errorMessage = 'Forçando carregamento da câmera...';
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _startCameraCheck() {
    _cameraCheckTimer?.cancel();
    _cameraCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Se a câmera não estiver pronta após 10 segundos, tenta reinicializar
      if (!_cameraReady && timer.tick > 5) {
        AppLogger.w('Câmera não está pronta, tentando reinicializar...');
        _reinitializeCamera();
        timer.cancel();
      }
    });
  }

  void _reinitializeCamera() {
    _cameraRetryCount++;
    if (_cameraRetryCount > 3) {
      AppLogger.e('Muitas tentativas de reinicialização da câmera');
      return;
    }
    
    AppLogger.i('Reinicializando câmera (tentativa $_cameraRetryCount)...');
    
    controller?.dispose();
    controller = null;
    
    setState(() {
      _cameraReady = false;
      _qrViewWorking = false;
    });
    
    // Pequeno delay antes de recriar
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          // Força rebuild do QRView
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }
    
    if (hasPermission || _forceCamera) {
      return _buildMainScanner();
    }
    
    return _buildPermissionScreen();
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
              'Inicializando scanner...',
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
                'Permissão de Câmera',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Parece que a câmera não está acessível. Vamos tentar algumas opções:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _permissionCheckDisabled ? null : () {
                  _checkPermissionOnce();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _permissionCheckDisabled ? 'Verificação Desabilitada' : 'Verificar Permissão',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: _tryForceCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Tentar Carregar Câmera',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () async {
                  await openAppSettings();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Abrir Configurações',
                  style: TextStyle(
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
        title: Text(_cameraReady ? 'Scanner QR' : 'Carregando Câmera...'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _cameraReady ? _toggleScanning : null,
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_off : Icons.flash_on),
            onPressed: _cameraReady ? _toggleFlash : null,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reinitializeCamera,
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
          if (_cameraReady) _buildScanningOverlay(),
          
          // Instructions
          _buildInstructions(),
          
          // Processing Overlay
          if (isProcessingQR) _buildProcessingOverlay(),
          
          // Camera Loading/Error Overlay
          if (!_cameraReady) _buildCameraLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraLoadingOverlay() {
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
            const Text(
              'Carregando câmera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tentativa $_cameraRetryCount de 3',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reinitializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text(
                'Tentar Novamente',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text(
                'Voltar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRView() {
    // Força rebuild com nova key quando reinicializa
    final key = GlobalKey(debugLabel: 'QR_${DateTime.now().millisecondsSinceEpoch}');
    
    return QRView(
      key: key,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.transparent,
        borderRadius: 12,
        borderLength: 0,
        borderWidth: 0,
        cutOutSize: 280,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(ctrl, p),
      // Adiciona configurações específicas
      cameraFacing: CameraFacing.back,
      formatsAllowed: const [BarcodeFormat.qrcode],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    AppLogger.i('QR View criada com sucesso');
    
    // Configura a câmera imediatamente
    _configureCameraSettings();
    
    // Inicia verificação de câmera
    _startCameraCheck();
    
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && isScanning && !isProcessingQR) {
        AppLogger.i('QR Code detectado: ${scanData.code}');
        _handleQRCode(scanData.code!);
      }
    });
  }

  void _configureCameraSettings() async {
    if (controller == null) return;
    
    try {
      // Aguarda um pouco para a câmera inicializar
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Tenta resumir a câmera
      await controller!.resumeCamera();
      
      // Verifica se a câmera está funcionando
      setState(() {
        _cameraReady = true;
        _qrViewWorking = true;
        hasPermission = true;
        _errorMessage = null;
      });
      
      _cameraCheckTimer?.cancel();
      
      AppLogger.i('Câmera configurada e funcionando!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Câmera carregada com sucesso! 🎉'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Erro ao configurar câmera: $e');
      if (mounted) {
        setState(() {
          _cameraReady = false;
          _errorMessage = 'Erro ao configurar câmera';
        });
      }
    }
  }

  void _onPermissionSet(QRViewController controller, bool p) {
    AppLogger.i('Permissão configurada pelo QR View: $p');
    
    if (p) {
      AppLogger.i('Permissão concedida pelo QR View!');
      _configureCameraSettings();
    } else {
      AppLogger.w('Permissão negada pelo QR View');
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
                  Icon(
                    _cameraReady ? Icons.qr_code_scanner : Icons.camera_alt,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _cameraReady 
                      ? 'Posicione o código QR dentro da área de escaneamento'
                      : 'Aguarde enquanto carregamos a câmera...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _cameraReady
                      ? 'Encontre os marcadores nos parques da Beira para começar experiências AR incríveis!'
                      : 'Se não funcionar, toque no botão de refresh ou volte',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_cameraReady) ...[
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
              SizedBox(height: 16),
              Text('🔧 Problemas com a câmera:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Volte e use "Tentar Carregar Câmera"'),
              Text('• Verifique permissões nas configurações'),
              Text('• Reinicie o app se necessário'),
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