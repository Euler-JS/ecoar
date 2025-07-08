import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ChallengeDetailPage extends StatefulWidget {
  final String challengeId;
  
  const ChallengeDetailPage({
    super.key,
    required this.challengeId,
  });

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isCompleted = false;
  List<int> _selectedAnswers = [];
  
  // Mock challenge data
  final Map<String, dynamic> _challengeData = {
    'id': 'biodiversity_quiz_1',
    'title': 'Quiz de Biodiversidade',
    'description': 'Teste seus conhecimentos sobre a flora e fauna da Bacia 1',
    'points': 100,
    'difficulty': 'Médio',
    'estimatedTime': '5-10 min',
    'questions': [
      {
        'question': 'Qual é a árvore nativa mais comum em Moçambique?',
        'options': ['Baobá', 'Eucalipto', 'Pinheiro', 'Carvalho'],
        'correctAnswer': 0,
        'explanation': 'O Baobá é uma árvore icônica e nativa de Moçambique, conhecida por sua longevidade e importância cultural.',
      },
      {
        'question': 'Quantas espécies de aves podem ser encontradas nos parques da Beira?',
        'options': ['Menos de 20', 'Entre 20-40', 'Entre 40-60', 'Mais de 60'],
        'correctAnswer': 2,
        'explanation': 'Os parques da Beira abrigam entre 40-60 espécies de aves, tornando-se um importante habitat para a avifauna local.',
      },
      {
        'question': 'O que é biodiversidade?',
        'options': [
          'Apenas plantas e animais',
          'Variedade de vida em um ecossistema',
          'Apenas animais marinhos',
          'Apenas plantas terrestres'
        ],
        'correctAnswer': 1,
        'explanation': 'Biodiversidade refere-se à variedade de todas as formas de vida em um ecossistema, incluindo plantas, animais, microorganismos e suas interações.',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _selectedAnswers = List.filled(_challengeData['questions'].length, -1);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionScreen();
    }

    final questions = _challengeData['questions'] as List;
    final currentQuestion = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_challengeData['title']),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHint,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _progressAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentQuestionIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Question
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: Text(
                  currentQuestion['question'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion['options'].length,
                  itemBuilder: (context, index) {
                    final option = currentQuestion['options'][index];
                    final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _selectAnswer(index),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppTheme.primaryGreen,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedAnswers[_currentQuestionIndex] != -1 ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentQuestionIndex == questions.length - 1 ? 'Finalizar' : 'Próxima',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final questions = _challengeData['questions'] as List;
    final correctAnswers = _calculateScore();
    final percentage = (correctAnswers / questions.length * 100).round();
    final earnedPoints = (percentage >= 70) ? _challengeData['points'] : (_challengeData['points'] * 0.5).round();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    percentage >= 70 ? Icons.check_circle : Icons.info,
                    size: 60,
                    color: percentage >= 70 ? AppTheme.successGreen : AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  percentage >= 70 ? 'Parabéns!' : 'Bom trabalho!',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Desafio concluído com sucesso!',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Results Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Seus Resultados',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResultItem(
                            'Acertos',
                            '$correctAnswers/${questions.length}',
                            Icons.check_circle,
                            AppTheme.successGreen,
                          ),
                          _buildResultItem(
                            'Pontuação',
                            '$percentage%',
                            Icons.percent,
                            AppTheme.primaryBlue,
                          ),
                          _buildResultItem(
                            'Pontos',
                            '+$earnedPoints',
                            Icons.star,
                            AppTheme.warningOrange,
                          ),
                        ],
                      ),
                      
                      if (percentage >= 70) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: AppTheme.successGreen,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Excelente! Você demonstrou bom conhecimento sobre biodiversidade.',
                                  style: TextStyle(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showAnswers(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Ver Respostas',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = index;
    });
  }

  void _nextQuestion() {
    final questions = _challengeData['questions'] as List;
    
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  int _calculateScore() {
    final questions = _challengeData['questions'] as List;
    int correct = 0;
    
    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i]['correctAnswer']) {
        correct++;
      }
    }
    
    return correct;
  }

  void _showHint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dica'),
        content: const Text(
          'Pense sobre as características únicas da flora e fauna de Moçambique. '
          'Lembre-se das informações que você aprendeu durante suas explorações no parque.',
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

  void _showAnswers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnswersReviewPage(
          challengeData: _challengeData,
          selectedAnswers: _selectedAnswers,
        ),
      ),
    );
  }
}

// Supporting pages
class AllBadgesPage extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const AllBadgesPage({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos os Badges')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final isEarned = badge['earned'] as bool;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEarned ? badge['color'].withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEarned ? badge['color'].withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  badge['icon'],
                  size: 48,
                  color: isEarned ? badge['color'] : Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  badge['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isEarned ? badge['color'] : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  badge['description'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isEarned && badge['date'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    badge['date'],
                    style: TextStyle(
                      fontSize: 10,
                      color: badge['color'],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnswersReviewPage extends StatelessWidget {
  final Map<String, dynamic> challengeData;
  final List<int> selectedAnswers;

  const AnswersReviewPage({
    super.key,
    required this.challengeData,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final questions = challengeData['questions'] as List;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Respostas do Quiz')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final selectedAnswer = selectedAnswers[index];
          final correctAnswer = question['correctAnswer'] as int;
          final isCorrect = selectedAnswer == correctAnswer;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number and status
                Row(
                  children: [
                    Text(
                      'Pergunta ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Question text
                Text(
                  question['question'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Options
                ...List.generate(question['options'].length, (optionIndex) {
                  final option = question['options'][optionIndex];
                  final isSelected = selectedAnswer == optionIndex;
                  final isCorrectOption = correctAnswer == optionIndex;
                  
                  Color backgroundColor = Colors.transparent;
                  Color textColor = AppTheme.textPrimary;
                  IconData? icon;
                  
                  if (isCorrectOption) {
                    backgroundColor = AppTheme.successGreen.withOpacity(0.1);
                    textColor = AppTheme.successGreen;
                    icon = Icons.check;
                  } else if (isSelected && !isCorrect) {
                    backgroundColor = AppTheme.errorRed.withOpacity(0.1);
                    textColor = AppTheme.errorRed;
                    icon = Icons.close;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isCorrectOption || (isSelected && !isCorrect))
                            ? (isCorrectOption ? AppTheme.successGreen : AppTheme.errorRed)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: (isCorrectOption || isSelected) 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (icon != null)
                          Icon(icon, color: textColor, size: 20),
                      ],
                    ),
                  );
                }),
                
                // Explanation
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Explicação:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question['explanation'],
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}