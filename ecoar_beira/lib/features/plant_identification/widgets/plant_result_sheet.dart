// lib/features/plant_identification/presentation/widgets/plant_result_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/features/plant_identification/data/services/plantnet_service.dart';
import 'package:ecoar_beira/features/plant_identification/data/repositories/local_plant_knowledge.dart';

class PlantResultSheet extends StatefulWidget {
  final PlantIdentificationResult result;
  final File imageFile;
  final LocalPlantKnowledge localKnowledge;
  final Function(int points) onPointsEarned;

  const PlantResultSheet({
    super.key,
    required this.result,
    required this.imageFile,
    required this.localKnowledge,
    required this.onPointsEarned,
  });

  @override
  State<PlantResultSheet> createState() => _PlantResultSheetState();
}

class _PlantResultSheetState extends State<PlantResultSheet>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _pointsController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pointsAnimation;
  
  bool _hasEarnedPoints = false;
  int _earnedPoints = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _calculatePointsAndShow();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pointsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.elasticOut),
    );

    _slideController.forward();
  }

  void _calculatePointsAndShow() {
    // Calcular pontos baseado na identificação
    if (widget.result.hasConfidentMatch) {
      final bestMatch = widget.result.bestMatch!;
      final localInfo = widget.localKnowledge.getPlantInfo(bestMatch.species.scientificName);
      
      if (localInfo != null) {
        _earnedPoints = localInfo.points;
      } else {
        // Pontos padrão para plantas não locais
        if (bestMatch.score > 0.7) {
          _earnedPoints = 40;
        } else if (bestMatch.score > 0.5) {
          _earnedPoints = 25;
        } else {
          _earnedPoints = 15;
        }
      }
    } else {
      // Pontos de consolação por tentar
      _earnedPoints = 10;
    }

    // Mostrar animação de pontos após um delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_hasEarnedPoints) {
        setState(() {
          _hasEarnedPoints = true;
        });
        _pointsController.forward();
        HapticFeedback.mediumImpact();
        widget.onPointsEarned(_earnedPoints);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!widget.result.hasConfidentMatch) {
      return _buildNoIdentificationContent();
    }

    final bestMatch = widget.result.bestMatch!;
    final localInfo = widget.localKnowledge.getPlantInfo(bestMatch.species.scientificName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with photo and basic info
        _buildHeader(bestMatch, localInfo),
        
        const SizedBox(height: 24),
        
        // Points earned animation
        if (_hasEarnedPoints) _buildPointsAnimation(),
        
        const SizedBox(height: 24),
        
        // Local information or PlantNet data
        if (localInfo != null)
          _buildLocalPlantInfo(localInfo)
        else
          _buildPlantNetInfo(bestMatch),
        
        const SizedBox(height: 24),
        
        // Additional matches
        if (widget.result.results.length > 1) _buildAlternativeMatches(),
        
        const SizedBox(height: 24),
        
        // Action buttons
        _buildActionButtons(bestMatch, localInfo),
      ],
    );
  }

  Widget _buildHeader(PlantMatch bestMatch, LocalPlantInfo? localInfo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Captured image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            widget.imageFile,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        
        // Plant info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant name
              Text(
                localInfo?.primaryName ?? bestMatch.species.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              // Scientific name
              if (localInfo != null && localInfo.localNames.length > 1)
                Text(
                  localInfo.localNames.skip(1).join(', '),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              
              Text(
                bestMatch.species.fullScientificName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Confidence
              Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: _getConfidenceColor(bestMatch.score),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${bestMatch.confidencePercent}% ${bestMatch.confidenceText}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getConfidenceColor(bestMatch.score),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              // Family
              if (bestMatch.species.family.isNotEmpty)
                Text(
                  'Família: ${bestMatch.species.family}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsAnimation() {
    return ScaleTransition(
      scale: _pointsAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.successGreen, AppTheme.primaryGreen],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.successGreen.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.stars,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '+$_earnedPoints pontos ganhos!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPlantInfo(LocalPlantInfo localInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Importance
        _buildInfoSection(
          '🌟 Importância',
          localInfo.importance,
          AppTheme.primaryGreen,
        ),
        
        const SizedBox(height: 16),
        
        // Ecological role
        _buildInfoSection(
          '🌍 Papel Ecológico',
          localInfo.ecologicalRole,
          AppTheme.primaryBlue,
        ),
        
        const SizedBox(height: 16),
        
        // Traditional uses
        if (localInfo.traditionalUses.isNotEmpty)
          _buildListSection(
            '🏛️ Usos Tradicionais',
            localInfo.traditionalUses,
            AppTheme.warningOrange,
          ),
        
        const SizedBox(height: 16),
        
        // Fun facts
        if (localInfo.funFacts.isNotEmpty)
          _buildListSection(
            '💡 Curiosidades',
            localInfo.funFacts,
            AppTheme.successGreen,
          ),
        
        const SizedBox(height: 16),
        
        // Seasonal info
        if (localInfo.seasonalInfo.isNotEmpty)
          _buildInfoSection(
            '📅 Informação Sazonal',
            localInfo.seasonalInfo,
            AppTheme.primaryGreen,
          ),
        
        const SizedBox(height: 16),
        
        // Cultural significance
        if (localInfo.culturalSignificance.isNotEmpty)
          _buildInfoSection(
            '🎭 Significado Cultural',
            localInfo.culturalSignificance,
            AppTheme.primaryBlue,
          ),
      ],
    );
  }

  Widget _buildPlantNetInfo(PlantMatch bestMatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection(
          '🔬 Informação Científica',
          'Esta planta foi identificada através da base de dados científica PlantNet. '
          'Para informações mais detalhadas sobre plantas locais da Beira, continue explorando!',
          AppTheme.primaryBlue,
        ),
        
        const SizedBox(height: 16),
        
        if (bestMatch.species.commonNames.isNotEmpty)
          _buildListSection(
            '🏷️ Nomes Comuns',
            bestMatch.species.commonNames,
            AppTheme.primaryGreen,
          ),
        
        const SizedBox(height: 16),
        
        // Reference images from PlantNet
        if (bestMatch.images.isNotEmpty) _buildReferenceImages(bestMatch.images),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color, fontSize: 16)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildReferenceImages(List<PlantImage> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📸 Imagens de Referência',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.take(5).length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    image.url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeMatches() {
    final alternatives = widget.result.results.skip(1).take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔄 Outras Possibilidades',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...alternatives.map((match) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.species.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      match.species.fullScientificName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${match.confidencePercent}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getConfidenceColor(match.score),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtons(PlantMatch bestMatch, LocalPlantInfo? localInfo) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareDiscovery(bestMatch, localInfo),
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _saveToCollection(bestMatch, localInfo),
                icon: const Icon(Icons.bookmark),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _exploreMore(),
            icon: const Icon(Icons.explore),
            label: const Text('Explorar Mais Plantas'),
          ),
        ),
      ],
    );
  }

  Widget _buildNoIdentificationContent() {
    final generalEducation = widget.localKnowledge.getGeneralPlantEducation();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.imageFile,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planta não identificada',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mas vamos aprender sobre plantas da Beira!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Points earned animation
        if (_hasEarnedPoints) _buildPointsAnimation(),
        
        const SizedBox(height: 24),
        
        // Educational content
        ...generalEducation.sections.map((section) => Column(
          children: [
            _buildInfoSection(section.title, section.content, AppTheme.primaryGreen),
            const SizedBox(height: 16),
          ],
        )),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tentar Novamente'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _exploreMore(),
                icon: const Icon(Icons.nature),
                label: const Text('Ver Plantas Locais'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getConfidenceColor(double score) {
    if (score > 0.7) return AppTheme.successGreen;
    if (score > 0.4) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  void _shareDiscovery(PlantMatch bestMatch, LocalPlantInfo? localInfo) {
    final plantName = localInfo?.primaryName ?? bestMatch.species.displayName;
    
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌱 Compartilhando descoberta de $plantName'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _saveToCollection(PlantMatch bestMatch, LocalPlantInfo? localInfo) {
    // TODO: Implement save to personal collection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💾 Planta salva na sua coleção!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _exploreMore() {
    Navigator.pop(context);
    // TODO: Navigate to plant exploration or local plants page
  }
}