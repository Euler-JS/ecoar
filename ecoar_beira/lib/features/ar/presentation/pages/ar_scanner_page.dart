// ar_scanner_page.dart - Integração AR + Scanner
// Temporariamente apenas scanner - AR indisponível
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';

class ARScannerPage extends StatefulWidget {
  const ARScannerPage({super.key});

  @override
  State<ARScannerPage> createState() => _ARScannerPageState();
}

class _ARScannerPageState extends State<ARScannerPage>
    with TickerProviderStateMixin {

  // Controllers
  MobileScannerController? _scannerController;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  // State
  bool _isLoading = true;
  String _scannedData = '';
  String _info = 'Scanner ativo - Posicione QR Code na tela';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeScanner();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    setState(() {
      _info = 'Scanner ativo - Posicione QR Code na tela';
      _isLoading = false;
    });
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner),
            SizedBox(width: 8),
            Text('EcoAR Scanner'),
          ],
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _isLoading
                ? _buildLoadingScreen()
                : _buildScannerScreen(),
          ),

          // Status overlay
          _buildStatusOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      key: const ValueKey('loading'),
      color: AppTheme.accentGreen,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 20),
            Text(
              'Inicializando EcoAR...',
              style: TextStyle(color: AppTheme.primaryGreen, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        key: const ValueKey('scanner'),
        child: MobileScanner(
          controller: _scannerController!,
          onDetect: _onQRCodeDetected,
          overlay: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primaryBlue,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(50),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_strong, size: 80, color: AppTheme.backgroundLight),
                  SizedBox(height: 20),
                  Text(
                    'Posicione o QR Code aqui',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      backgroundColor: AppTheme.backgroundDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppTheme.primaryBlue,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                _info,
                style: const TextStyle(
                  color: AppTheme.backgroundLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (_scannedData.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Código: $_scannedData',
                    style: const TextStyle(
                      color: AppTheme.backgroundLight,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code != _scannedData) {
        setState(() {
          _scannedData = code;
          _info = '✅ QR Code detectado! Código: $code';
        });

        _bounceController.forward();

        // Mostrar dialog com resultado
        Timer(const Duration(seconds: 2), () {
          _showResultDialog(code);
        });
        break;
      }
    }
  }

  void _showResultDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text(
          'QR Code Detectado!',
          style: TextStyle(color: AppTheme.primaryGreen),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.primaryGreen,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Código: $code',
              style: const TextStyle(
                color: AppTheme.backgroundLight,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Funcionalidade AR temporariamente indisponível.\nO scanner QR está funcionando corretamente!',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _scannedData = '';
                _info = 'Scanner ativo - Posicione QR Code na tela';
              });
            },
            child: const Text(
              'Escanear Outro',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
