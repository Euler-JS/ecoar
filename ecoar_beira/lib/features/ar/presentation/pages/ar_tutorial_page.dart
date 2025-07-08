import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class ARTutorialPage extends StatefulWidget {
  const ARTutorialPage({super.key});

  @override
  State<ARTutorialPage> createState() => _ARTutorialPageState();
}

class _ARTutorialPageState extends State<ARTutorialPage> {
  int _currentStep = 0;
  
  final List<ARTutorialStep> _steps = [
    ARTutorialStep(
      title: 'Bem-vindo ao AR!',
      description: 'A Realidade Aumentada permite sobrepor objetos digitais no mundo real através da sua câmera.',
      icon: Icons.view_in_ar,
      tips: [
        'Use um dispositivo com boa iluminação',
        'Mantenha a câmera estável',
        'Procure por superfícies planas',
      ],
    ),
    ARTutorialStep(
      title: 'Detecção de Superfícies',
      description: 'O AR precisa detectar superfícies para posicionar objetos. Mova lentamente a câmera sobre mesas, chão ou paredes.',
      icon: Icons.scanner,
      tips: [
        'Mova a câmera lentamente',
        'Procure superfícies com textura',
        'Evite superfícies muito reflexivas',
      ],
    ),
    ARTutorialStep(
      title: 'Interagindo com Objetos',
      description: 'Toque nos objetos AR para interagir. Você pode ver informações, ganhar pontos e desbloquear conteúdo.',
      icon: Icons.touch_app,
      tips: [
        'Toque diretamente no objeto',
        'Use gestos de pinça para redimensionar',
        'Mantenha pressionado para mais opções',
      ],
    ),
    ARTutorialStep(
      title: 'Pronto para Explorar!',
      description: 'Agora você está pronto para explorar os parques da Beira com AR. Encontre marcadores QR e comece sua aventura!',
      icon: Icons.explore,
      tips: [
        'Procure por marcadores QR nos parques',
        'Complete desafios para ganhar pontos',
        'Compartilhe suas descobertas',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial AR'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_steps.length, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep 
                          ? AppTheme.primaryGreen 
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Tutorial Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStep(),
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    child: const Text('Anterior'),
                  )
                else
                  const SizedBox(),
                
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep < _steps.length - 1) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      context.go('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                  child: Text(
                    _currentStep < _steps.length - 1 ? 'Próximo' : 'Começar!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    final step = _steps[_currentStep];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(
            step.icon,
            size: 60,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 32),
        
        // Title
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Description
        Text(
          step.description,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dicas:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...step.tips.map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.blue)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class ARTutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final List<String> tips;

  ARTutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.tips,
  });
}
