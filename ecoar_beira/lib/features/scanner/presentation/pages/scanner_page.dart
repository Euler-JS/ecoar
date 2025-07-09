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
  
  bool isScanning = true;
  bool hasPermission = false;
  bool isFlashOn = false;
  bool isProcessingQR = false;
  bool _isInitialized = false;
  bool _forceCamera = false;  // Flag para forçar carregamento da câmera
  bool _qrViewWorking = false; // Flag para detectar se QR View está funcionando
  bool _permissionCheckDisabled = false; // Flag para parar verificações desnecessárias
  String? _errorMessage;
  int _permissionAttempts = 0;
  
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
      } else if (Platform.isIOS) {
        controller!.resumeCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.i('App lifecycle state changed: $state');
    
    if (state == AppLifecycleState.resumed) {
      // Quando volta do background, tenta forçar câmera
      AppLogger.i('App resumed, forcing camera check...');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_qrViewWorking) {
          _tryForceCamera();
        }
      });
    }
    
    if (controller == null) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (_qrViewWorking) {
          controller!.resumeCamera();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (_qrViewWorking) {
          controller!.pauseCamera();
        }
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

  Future<void> _initializeScanner() async {
    AppLogger.i('Inicializando scanner...');
    
    setState(() {
      _isInitialized = true;
    });
    
    // Primeira tentativa: verificar permissão normalmente
    await _checkPermissionOnce();
    
    // Se não conseguiu permissão, inicia fallback timer
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
      
      // Se negada e ainda não tentou solicitar
      if (status.isDenied && _permissionAttempts == 1) {
        AppLogger.i('Tentando solicitar permissão...');
        final result = await Permission.camera.request();
        AppLogger.i('Resultado da solicitação: $result');
        
        if (result.isGranted) {
          _setPermissionGranted();
          return;
        }
      }
      
      // Se chegou aqui, não conseguiu permissão
      AppLogger.w('Não conseguiu permissão. Tentativas: $_permissionAttempts');
      
      // Após 2 tentativas, para de verificar e usa fallback
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
    
    // Pequeno delay para UI atualizar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }
    
    // Se tem permissão ou está forçando câmera, mostra scanner
    if (hasPermission || _forceCamera) {
      return _buildMainScanner();
    }
    
    // Se não tem permissão e não está forçando, mostra tela de permissão
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
              
              // Botão para verificar permissão
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
              
              // Botão para forçar câmera
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
              
              // Botão para configurações
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
              
              // Botão para voltar
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Voltar para Início'),
              ),
              
              const SizedBox(height: 24),
              
              // Instruções
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Soluções:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Tente "Tentar Carregar Câmera" (mais eficaz)\n'
                      '2. Vá em Configurações > EcoAR Beira > Câmera\n'
                      '3. Ative a permissão e volte ao app',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tentativas de permissão: $_permissionAttempts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
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
        title: Text(_qrViewWorking ? 'Scanner QR' : 'Carregando Câmera...'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _qrViewWorking ? _toggleScanning : null,
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_off : Icons.flash_on),
            onPressed: _qrViewWorking ? _toggleFlash : null,
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
          
          // Scanning Overlay (só se QR View estiver funcionando)
          if (_qrViewWorking) _buildScanningOverlay(),
          
          // Instructions
          _buildInstructions(),
          
          // Processing Overlay
          if (isProcessingQR) _buildProcessingOverlay(),
          
          // Loading overlay se não estiver funcionando
          if (!_qrViewWorking) _buildCameraLoadingOverlay(),
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
            const Text(
              'Se a câmera não aparecer em alguns segundos,\ntente voltar e usar "Tentar Carregar Câmera"',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text(
                'Voltar e Tentar Novamente',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
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
    
    // Se chegou aqui, a câmera está funcionando!
    if (!_qrViewWorking) {
      AppLogger.i('QR View funcionando! Câmera detectada.');
      setState(() {
        _qrViewWorking = true;
        hasPermission = true;
        _errorMessage = null;
      });
      
      _fallbackTimer?.cancel();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Câmera carregada com sucesso! 🎉'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && isScanning && !isProcessingQR) {
        AppLogger.i('QR Code detectado: ${scanData.code}');
        _handleQRCode(scanData.code!);
      }
    });
  }

  void _onPermissionSet(QRViewController controller, bool p) {
    AppLogger.i('Permissão configurada pelo QR View: $p');
    
    if (p) {
      AppLogger.i('Permissão concedida pelo QR View!');
      if (!_qrViewWorking) {
        setState(() {
          _qrViewWorking = true;
          hasPermission = true;
          _errorMessage = null;
        });
        _fallbackTimer?.cancel();
      }
    } else {
      AppLogger.w('Permissão negada pelo QR View');
      // Não faz nada - deixa o timer de fallback lidar com isso
    }
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
                  Icon(
                    _qrViewWorking ? Icons.qr_code_scanner : Icons.camera_alt,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _qrViewWorking 
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
                    _qrViewWorking
                      ? 'Encontre os marcadores nos parques da Beira para começar experiências AR incríveis!'
                      : 'Se não funcionar, volte e tente "Tentar Carregar Câmera"',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_qrViewWorking) ...[
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