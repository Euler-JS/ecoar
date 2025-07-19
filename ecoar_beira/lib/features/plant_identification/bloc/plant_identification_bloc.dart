// lib/features/plant_identification/presentation/bloc/plant_identification_bloc.dart
import 'dart:io';

import 'package:ecoar_beira/core/theme/app_theme.dart';
import 'package:ecoar_beira/features/plant_identification/config/plant_id_config.dart';
import 'package:ecoar_beira/features/plant_identification/pages/plant_identification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ecoar_beira/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:ecoar_beira/features/plant_identification/data/services/plantnet_service.dart';
import 'package:ecoar_beira/features/plant_identification/data/repositories/local_plant_knowledge.dart';

// Events
abstract class PlantIdentificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlantIdentifyRequested extends PlantIdentificationEvent {
  final String imagePath;
  final PlantOrgan organ;
  final List<PlantModifier> modifiers;

  PlantIdentifyRequested({
    required this.imagePath,
    required this.organ,
    required this.modifiers,
  });

  @override
  List<Object?> get props => [imagePath, organ, modifiers];
}

class PlantIdentificationCompleted extends PlantIdentificationEvent {
  final PlantIdentificationResult result;
  final LocalPlantInfo? localInfo;

  PlantIdentificationCompleted({
    required this.result,
    this.localInfo,
  });

  @override
  List<Object?> get props => [result, localInfo];
}

// States
abstract class PlantIdentificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlantIdentificationInitial extends PlantIdentificationState {}

class PlantIdentificationLoading extends PlantIdentificationState {}

class PlantIdentificationSuccess extends PlantIdentificationState {
  final PlantIdentificationResult result;
  final LocalPlantInfo? localInfo;
  final int pointsEarned;
  final List<String> achievementsUnlocked;

  PlantIdentificationSuccess({
    required this.result,
    this.localInfo,
    required this.pointsEarned,
    required this.achievementsUnlocked,
  });

  @override
  List<Object?> get props => [result, localInfo, pointsEarned, achievementsUnlocked];
}

class PlantIdentificationFailure extends PlantIdentificationState {
  final String error;
  final int consolationPoints;

  PlantIdentificationFailure({
    required this.error,
    required this.consolationPoints,
  });

  @override
  List<Object?> get props => [error, consolationPoints];
}

// BLoC
class PlantIdentificationBloc extends Bloc<PlantIdentificationEvent, PlantIdentificationState> {
  final PlantNetService _plantNetService;
  final LocalPlantKnowledge _localKnowledge;
  final GamificationBloc _gamificationBloc;
  
  // Statistics tracking
  int _totalIdentifications = 0;
  int _successfulIdentifications = 0;
  Set<String> _uniquePlantsIdentified = {};
  Set<String> _nativePlantsFound = {};

  PlantIdentificationBloc({
    required PlantNetService plantNetService,
    required LocalPlantKnowledge localKnowledge,
    required GamificationBloc gamificationBloc,
  })  : _plantNetService = plantNetService,
        _localKnowledge = localKnowledge,
        _gamificationBloc = gamificationBloc,
        super(PlantIdentificationInitial()) {
    
    on<PlantIdentifyRequested>(_onIdentifyRequested);
    on<PlantIdentificationCompleted>(_onIdentificationCompleted);
  }

  Future<void> _onIdentifyRequested(
    PlantIdentifyRequested event,
    Emitter<PlantIdentificationState> emit,
  ) async {
    emit(PlantIdentificationLoading());

    try {
      _totalIdentifications++;
      
      // Call PlantNet API
      final result = await _plantNetService.identifyPlant(
        imageFile: File(event.imagePath),
        organ: event.organ,
        modifiers: event.modifiers,
      );

      LocalPlantInfo? localInfo;
      if (result.hasConfidentMatch) {
        localInfo = _localKnowledge.getPlantInfo(
          result.bestMatch!.species.scientificName,
        );
      }

      add(PlantIdentificationCompleted(result: result, localInfo: localInfo));

    } catch (e) {
      emit(PlantIdentificationFailure(
        error: e.toString(),
        consolationPoints: 10,
      ));
      
      // Award consolation points
      _gamificationBloc.add(GamificationAddPoints(
        points: 10,
        category: 'plant_identification',
        description: 'Tentativa de identificação de planta',
      ));
    }
  }

  Future<void> _onIdentificationCompleted(
    PlantIdentificationCompleted event,
    Emitter<PlantIdentificationState> emit,
  ) async {
    final result = event.result;
    final localInfo = event.localInfo;
    
    int pointsEarned = 0;
    List<String> achievementsUnlocked = [];

    if (result.hasConfidentMatch) {
      _successfulIdentifications++;
      final bestMatch = result.bestMatch!;
      final scientificName = bestMatch.species.scientificName;
      
      // Add to unique plants set
      final isNewPlant = _uniquePlantsIdentified.add(scientificName);
      
      // Calculate points
      pointsEarned = _calculatePoints(bestMatch, localInfo, isNewPlant);
      
      // Check for native plants
      if (localInfo != null && localInfo.rarity == PlantRarity.iconic) {
        _nativePlantsFound.add(scientificName);
      }
      
      // Check achievements
      achievementsUnlocked = _checkAchievements();
      
      // Award points to gamification system
      _gamificationBloc.add(GamificationAddPoints(
        points: pointsEarned,
        category: 'plant_identification',
        description: 'Planta identificada: ${localInfo?.primaryName ?? bestMatch.species.displayName}',
      ));
      
      // Check and award badges
      for (final achievement in achievementsUnlocked) {
        _gamificationBloc.add(GamificationCheckBadges());
      }
    }

    emit(PlantIdentificationSuccess(
      result: result,
      localInfo: localInfo,
      pointsEarned: pointsEarned,
      achievementsUnlocked: achievementsUnlocked,
    ));
  }

  int _calculatePoints(PlantMatch match, LocalPlantInfo? localInfo, bool isNewPlant) {
    int basePoints = 0;
    
    // Points based on confidence
    if (match.score > 0.7) {
      basePoints = 50;
    } else if (match.score > 0.5) {
      basePoints = 30;
    } else if (match.score > 0.3) {
      basePoints = 20;
    } else {
      basePoints = 10;
    }
    
    // Bonus for local plants
    if (localInfo != null) {
      basePoints += localInfo.points;
      
      // Extra bonus for iconic plants
      if (localInfo.rarity == PlantRarity.iconic) {
        basePoints += 50;
      }
    }
    
    // Bonus for new discovery
    if (isNewPlant) {
      basePoints += 25;
    }
    
    // Streak bonus (example: consecutive days)
    // TODO: Implement streak tracking
    
    return basePoints;
  }

  List<String> _checkAchievements() {
    List<String> newAchievements = [];
    
    // First plant identified
    if (_successfulIdentifications == 1) {
      newAchievements.add('botanist_beginner');
    }
    
    // 10 plants identified
    if (_successfulIdentifications == 10) {
      newAchievements.add('plant_explorer');
    }
    
    // 5 unique plants
    if (_uniquePlantsIdentified.length == 5) {
      newAchievements.add('diversity_seeker');
    }
    
    // First native plant
    if (_nativePlantsFound.length == 1) {
      newAchievements.add('local_expert_bronze');
    }
    
    // 3 native plants
    if (_nativePlantsFound.length == 3) {
      newAchievements.add('local_expert_silver');
    }
    
    // All major plant types (if we track organ types)
    // TODO: Track organs identified (leaf, flower, fruit, bark)
    
    return newAchievements;
  }

  // Getters for statistics
  double get successRate => _totalIdentifications > 0 
      ? _successfulIdentifications / _totalIdentifications 
      : 0.0;
  
  int get uniquePlantsCount => _uniquePlantsIdentified.length;
  int get nativePlantsCount => _nativePlantsFound.length;
  int get totalAttempts => _totalIdentifications;
}

// Integration with existing gamification system
extension PlantIdentificationGamification on GamificationBloc {
  void addPlantIdentificationBadges() {
    // Add plant-specific badges to the existing badge system
    final plantBadges = [
      {
        'id': 'botanist_beginner',
        'name': 'Botânico Iniciante',
        'description': 'Identificou sua primeira planta',
        'icon': 'nature',
        'requirement': 'identify_first_plant',
        'points': 100,
      },
      {
        'id': 'plant_explorer',
        'name': 'Explorador de Plantas',
        'description': 'Identificou 10 plantas diferentes',
        'icon': 'explore',
        'requirement': 'identify_10_plants',
        'points': 300,
      },
      {
        'id': 'diversity_seeker',
        'name': 'Buscador da Diversidade',
        'description': 'Encontrou 5 espécies únicas',
        'icon': 'diversity_3',
        'requirement': 'find_5_unique_species',
        'points': 400,
      },
      {
        'id': 'local_expert_bronze',
        'name': 'Especialista Local - Bronze',
        'description': 'Identificou primeira planta nativa',
        'icon': 'local_florist',
        'requirement': 'find_first_native',
        'points': 200,
      },
      {
        'id': 'local_expert_silver',
        'name': 'Especialista Local - Prata',
        'description': 'Identificou 3 plantas nativas da Beira',
        'icon': 'local_florist',
        'requirement': 'find_3_natives',
        'points': 500,
      },
      {
        'id': 'plant_photographer',
        'name': 'Fotógrafo Botânico',
        'description': 'Capturou fotos de plantas em alta qualidade',
        'icon': 'camera_alt',
        'requirement': 'high_quality_photos',
        'points': 150,
      },
      {
        'id': 'seasonal_observer',
        'name': 'Observador Sazonal',
        'description': 'Identificou plantas em diferentes estações',
        'icon': 'calendar_today',
        'requirement': 'identify_across_seasons',
        'points': 350,
      },
    ];
    
    // TODO: Integrate these badges into the existing gamification system
  }
}

// Usage example in the UI
class PlantIdentificationPageWithBloC extends StatelessWidget {
  const PlantIdentificationPageWithBloC({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlantIdentificationBloc(
        plantNetService: PlantNetService(apiKey: PlantIdConfig.plantNetApiKey),
        localKnowledge: LocalPlantKnowledge.instance,
        gamificationBloc: context.read<GamificationBloc>(),
      ),
      child: BlocListener<PlantIdentificationBloc, PlantIdentificationState>(
        listener: (context, state) {
          if (state is PlantIdentificationSuccess) {
            // Show success with points and achievements
            _showSuccessSnackBar(context, state.pointsEarned, state.achievementsUnlocked);
          } else if (state is PlantIdentificationFailure) {
            // Show consolation message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Não foi possível identificar, mas você ganhou ${state.consolationPoints} pontos por tentar!'),
                backgroundColor: AppTheme.warningOrange,
              ),
            );
          }
        },
        child: const PlantIdentificationPage(),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, int points, List<String> achievements) {
    String message = '🌱 +$points pontos ganhos!';
    
    if (achievements.isNotEmpty) {
      message += '\n🏆 Novo achievement desbloqueado!';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}