import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/features/ar/utils/ar_compatibility_checker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ARCompatibilityPage extends StatefulWidget {
  const ARCompatibilityPage({super.key});

  @override
  State<ARCompatibilityPage> createState() => _ARCompatibilityPageState();
}

class _ARCompatibilityPageState extends State<ARCompatibilityPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  ARCompatibilityResult? _result;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkCompatibility();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  Future<void> _checkCompatibility() async {
    final result = await ARCompatibilityChecker.instance.checkCompatibility();
    setState(() {
      _result = result;
      _isChecking = false;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação AR'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _isChecking ? _buildLoadingScreen() : _buildResultScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
          SizedBox(height: 24),
          Text(
            'Verificando compatibilidade AR...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    if (_result == null) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _result!.isSupported 
                    ? AppTheme.successGreen 
                    : AppTheme.errorRed,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                _result!.isSupported ? Icons.check : Icons.close,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            Text(
              _result!.isSupported ? 'AR Suportado!' : 'AR Não Suportado',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Reason
            Text(
              _result!.reason,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Recommendations
            if (_result!.recommendations.isNotEmpty) ...[
              const Text(
                'Recomendações:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...(_result!.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ))),
              const SizedBox(height: 24),
            ],
            
            // Action Buttons
            if (_result!.isSupported)
              ElevatedButton(
                onPressed: () => context.go('/ar-tutorial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Começar Tutorial AR',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              )
            else if (_result!.canInstall && _result!.installUrl != null)
              ElevatedButton(
                onPressed: () => _installARCore(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Instalar ARCore',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Back Button
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  void _installARCore() {
    // Open Play Store to install ARCore
    // This would use url_launcher in a real implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecionando para Play Store...'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }
}