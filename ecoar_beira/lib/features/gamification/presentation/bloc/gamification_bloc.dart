import 'dart:math'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
// Gamification Events
abstract class GamificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GamificationLoadStats extends GamificationEvent {}

class GamificationAddPoints extends GamificationEvent {
  final int points;
  final String category;
  final String description;
  
  GamificationAddPoints({
    required this.points,
    required this.category,
    required this.description,
  });
  
  @override
  List<Object?> get props => [points, category, description];
}

class GamificationCheckBadges extends GamificationEvent {}

class GamificationLoadLeaderboard extends GamificationEvent {
  final String timeframe; // 'weekly', 'monthly', 'all'
  
  GamificationLoadLeaderboard({this.timeframe = 'weekly'});
  
  @override
  List<Object?> get props => [timeframe];
}

class GamificationCompleteChallenge extends GamificationEvent {
  final String challengeId;
  final int score;
  
  GamificationCompleteChallenge({
    required this.challengeId,
    required this.score,
  });
  
  @override
  List<Object?> get props => [challengeId, score];
}

// Gamification States
abstract class GamificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GamificationInitial extends GamificationState {}

class GamificationLoading extends GamificationState {}

class GamificationStatsLoaded extends GamificationState {
  final Map<String, dynamic> stats;
  
  GamificationStatsLoaded({required this.stats});
  
  @override
  List<Object?> get props => [stats];
}

class GamificationPointsAdded extends GamificationState {
  final int newTotal;
  final int pointsAdded;
  final String reason;
  
  GamificationPointsAdded({
    required this.newTotal,
    required this.pointsAdded,
    required this.reason,
  });
  
  @override
  List<Object?> get props => [newTotal, pointsAdded, reason];
}

class GamificationBadgeEarned extends GamificationState {
  final Map<String, dynamic> badge;
  
  GamificationBadgeEarned({required this.badge});
  
  @override
  List<Object?> get props => [badge];
}

class GamificationLevelUp extends GamificationState {
  final String newLevel;
  final String previousLevel;
  
  GamificationLevelUp({
    required this.newLevel,
    required this.previousLevel,
  });
  
  @override
  List<Object?> get props => [newLevel, previousLevel];
}

class GamificationLeaderboardLoaded extends GamificationState {
  final List<Map<String, dynamic>> leaderboard;
  final String timeframe;
  
  GamificationLeaderboardLoaded({
    required this.leaderboard,
    required this.timeframe,
  });
  
  @override
  List<Object?> get props => [leaderboard, timeframe];
}

class GamificationError extends GamificationState {
  final String message;
  
  GamificationError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Gamification BLoC
class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _availableBadges = [];
  
  GamificationBloc() : super(GamificationInitial()) {
    on<GamificationLoadStats>(_onLoadStats);
    on<GamificationAddPoints>(_onAddPoints);
    on<GamificationCheckBadges>(_onCheckBadges);
    on<GamificationLoadLeaderboard>(_onLoadLeaderboard);
    on<GamificationCompleteChallenge>(_onCompleteChallenge);
    
    _initializeBadges();
  }
  
  void _initializeBadges() {
    _availableBadges = [
      {
        'id': 'descobridor',
        'name': 'Descobridor',
        'description': 'Escaneie seu primeiro marcador QR',
        'icon': 'explore',
        'requirement': 'scan_first_marker',
        'points': 50,
      },
      {
        'id': 'cientista',
        'name': 'Pequeno Cientista',
        'description': 'Complete 10 quizzes corretamente',
        'icon': 'science',
        'requirement': 'complete_10_quizzes',
        'points': 200,
      },
      {
        'id': 'eco_warrior',
        'name': 'Eco Warrior',
        'description': 'Visite marcadores em todas as 3 bacias',
        'icon': 'eco',
        'requirement': 'visit_all_basins',
        'points': 300,
      },
      {
        'id': 'influencer',
        'name': 'Influencer Verde',
        'description': 'Compartilhe 5 experiências AR',
        'icon': 'share',
        'requirement': 'share_5_experiences',
        'points': 150,
      },
      {
        'id': 'mestre',
        'name': 'Mestre Ambiental',
        'description': 'Acumule 5000 pontos',
        'icon': 'school',
        'requirement': 'reach_5000_points',
        'points': 500,
      },
    ];
  }
  
  Future<void> _onLoadStats(
    GamificationLoadStats event,
    Emitter<GamificationState> emit,
  ) async {
    emit(GamificationLoading());
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _stats = {
        'totalPoints': 1250,
        'level': 'Explorador',
        'markersVisited': 8,
        'challengesCompleted': 15,
        'badgesEarned': ['descobridor', 'cientista', 'eco_warrior'],
        'streakDays': 7,
        'totalTimeSpent': 180, // minutes
        'favoriteCategory': 'biodiversidade',
        'achievements': {
          'markersScanned': 8,
          'quizzesCompleted': 15,
          'basinsVisited': 3,
          'experiencesShared': 3,
        },
      };
      
      emit(GamificationStatsLoaded(stats: _stats));
    } catch (e) {
      emit(GamificationError(message: 'Erro ao carregar estatísticas: ${e.toString()}'));
    }
  }
  
  Future<void> _onAddPoints(
    GamificationAddPoints event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final currentPoints = _stats['totalPoints'] ?? 0;
      final newTotal = currentPoints + event.points;
      final previousLevel = _stats['level'] ?? 'Iniciante';
      
      _stats['totalPoints'] = newTotal;
      
      // Check for level up
      final newLevel = _calculateLevel(newTotal);
      if (newLevel != previousLevel) {
        _stats['level'] = newLevel;
        emit(GamificationLevelUp(
          newLevel: newLevel,
          previousLevel: previousLevel,
        ));
      }
      
      emit(GamificationPointsAdded(
        newTotal: newTotal,
        pointsAdded: event.points,
        reason: event.description,
      ));
      
      // Check for new badges
      add(GamificationCheckBadges());
      
    } catch (e) {
      emit(GamificationError(message: 'Erro ao adicionar pontos: ${e.toString()}'));
    }
  }
  
  Future<void> _onCheckBadges(
    GamificationCheckBadges event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final earnedBadges = List<String>.from(_stats['badgesEarned'] ?? []);
      final achievements = _stats['achievements'] ?? {};
      
      for (final badge in _availableBadges) {
        if (!earnedBadges.contains(badge['id'])) {
          if (_checkBadgeRequirement(badge['requirement'], achievements)) {
            earnedBadges.add(badge['id']);
            _stats['badgesEarned'] = earnedBadges;
            
            emit(GamificationBadgeEarned(badge: badge));
            
            // Add badge points
            final badgePoints = badge['points'] as int;
            _stats['totalPoints'] = (_stats['totalPoints'] ?? 0) + badgePoints;
          }
        }
      }
    } catch (e) {
      emit(GamificationError(message: 'Erro ao verificar badges: ${e.toString()}'));
    }
  }
  
  Future<void> _onLoadLeaderboard(
    GamificationLoadLeaderboard event,
    Emitter<GamificationState> emit,
  ) async {
    emit(GamificationLoading());
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock leaderboard data
      final leaderboard = [
        {
          'rank': 1,
          'name': 'Maria Santos',
          'points': 2850,
          'level': 'Guardião Verde',
          'avatar': null,
          'badges': 7,
          'isCurrentUser': false,
        },
        {
          'rank': 2,
          'name': 'João Silva',
          'points': 1250,
          'level': 'Explorador',
          'avatar': null,
          'badges': 3,
          'isCurrentUser': true,
        },
        {
          'rank': 3,
          'name': 'Ana Costa',
          'points': 980,
          'level': 'Explorador',
          'avatar': null,
          'badges': 4,
          'isCurrentUser': false,
        },
        {
          'rank': 4,
          'name': 'Pedro Lima',
          'points': 720,
          'level': 'Explorador',
          'avatar': null,
          'badges': 2,
          'isCurrentUser': false,
        },
        {
          'rank': 5,
          'name': 'Sofia Oliveira',
          'points': 580,
          'level': 'Explorador',
          'avatar': null,
          'badges': 3,
          'isCurrentUser': false,
        },
      ];
      
      emit(GamificationLeaderboardLoaded(
        leaderboard: leaderboard,
        timeframe: event.timeframe,
      ));
    } catch (e) {
      emit(GamificationError(message: 'Erro ao carregar ranking: ${e.toString()}'));
    }
  }
  
  Future<void> _onCompleteChallenge(
    GamificationCompleteChallenge event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final achievements = Map<String, dynamic>.from(_stats['achievements'] ?? {});
      achievements['challengesCompleted'] = (achievements['challengesCompleted'] ?? 0) + 1;
      achievements['quizzesCompleted'] = (achievements['quizzesCompleted'] ?? 0) + 1;
      
      _stats['achievements'] = achievements;
      _stats['challengesCompleted'] = achievements['challengesCompleted'];
      
      // Calculate points based on score
      final basePoints = 100;
      final bonusPoints = (event.score * 0.5).round();
      final totalPoints = basePoints + bonusPoints;
      
      add(GamificationAddPoints(
        points: totalPoints,
        category: 'challenge',
        description: 'Desafio completado: ${event.challengeId}',
      ));
      
    } catch (e) {
      emit(GamificationError(message: 'Erro ao completar desafio: ${e.toString()}'));
    }
  }
  
  String _calculateLevel(int points) {
    if (points >= 5000) return 'Eco Herói';
    if (points >= 2000) return 'Guardião Verde';
    if (points >= 500) return 'Explorador';
    return 'Iniciante';
  }
  
  bool _checkBadgeRequirement(String requirement, Map<String, dynamic> achievements) {
    switch (requirement) {
      case 'scan_first_marker':
        return (achievements['markersScanned'] ?? 0) >= 1;
      case 'complete_10_quizzes':
        return (achievements['quizzesCompleted'] ?? 0) >= 10;
      case 'visit_all_basins':
        return (achievements['basinsVisited'] ?? 0) >= 3;
      case 'share_5_experiences':
        return (achievements['experiencesShared'] ?? 0) >= 5;
      case 'reach_5000_points':
        return (_stats['totalPoints'] ?? 0) >= 5000;
      default:
        return false;
    }
  }
}