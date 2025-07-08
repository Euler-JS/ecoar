import 'dart:math'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// User Events
abstract class UserEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserLoadProfile extends UserEvent {}

class UserUpdateProfile extends UserEvent {
  final Map<String, dynamic> profileData;
  
  UserUpdateProfile({required this.profileData});
  
  @override
  List<Object?> get props => [profileData];
}

class UserAddPoints extends UserEvent {
  final int points;
  final String reason;
  
  UserAddPoints({required this.points, required this.reason});
  
  @override
  List<Object?> get props => [points, reason];
}

class UserVisitMarker extends UserEvent {
  final String markerId;
  
  UserVisitMarker({required this.markerId});
  
  @override
  List<Object?> get props => [markerId];
}

class UserEarnBadge extends UserEvent {
  final String badgeId;
  
  UserEarnBadge({required this.badgeId});
  
  @override
  List<Object?> get props => [badgeId];
}

// User States
abstract class UserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final Map<String, dynamic> user;
  
  UserLoaded({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class UserUpdated extends UserState {
  final Map<String, dynamic> user;
  
  UserUpdated({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;
  
  UserError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// User BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  Map<String, dynamic> _currentUser = {};
  
  UserBloc() : super(UserInitial()) {
    on<UserLoadProfile>(_onLoadProfile);
    on<UserUpdateProfile>(_onUpdateProfile);
    on<UserAddPoints>(_onAddPoints);
    on<UserVisitMarker>(_onVisitMarker);
    on<UserEarnBadge>(_onEarnBadge);
  }
  
  Future<void> _onLoadProfile(
    UserLoadProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    
    try {
      // Simulate loading user profile
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser = {
        'id': 'user_123',
        'name': 'João Silva',
        'email': 'joao.silva@email.com',
        'level': 'Explorador',
        'points': 1250,
        'markersVisited': ['bacia1_001', 'bacia2_001'],
        'challengesCompleted': 15,
        'badgesEarned': ['descobridor', 'cientista', 'eco_warrior'],
        'joinDate': '15 de Janeiro, 2024',
        'avatar': null,
        'preferences': {
          'notifications': true,
          'soundEffects': true,
          'language': 'pt',
        },
      };
      
      emit(UserLoaded(user: _currentUser));
    } catch (e) {
      emit(UserError(message: 'Erro ao carregar perfil: ${e.toString()}'));
    }
  }
  
  Future<void> _onUpdateProfile(
    UserUpdateProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    
    try {
      // Simulate profile update
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser.addAll(event.profileData);
      
      emit(UserUpdated(user: _currentUser));
    } catch (e) {
      emit(UserError(message: 'Erro ao atualizar perfil: ${e.toString()}'));
    }
  }
  
  Future<void> _onAddPoints(
    UserAddPoints event,
    Emitter<UserState> emit,
  ) async {
    try {
      _currentUser['points'] = (_currentUser['points'] ?? 0) + event.points;
      
      // Check for level up
      final newLevel = _calculateLevel(_currentUser['points']);
      if (newLevel != _currentUser['level']) {
        _currentUser['level'] = newLevel;
      }
      
      emit(UserUpdated(user: _currentUser));
    } catch (e) {
      emit(UserError(message: 'Erro ao adicionar pontos: ${e.toString()}'));
    }
  }
  
  Future<void> _onVisitMarker(
    UserVisitMarker event,
    Emitter<UserState> emit,
  ) async {
    try {
      final visitedMarkers = List<String>.from(_currentUser['markersVisited'] ?? []);
      if (!visitedMarkers.contains(event.markerId)) {
        visitedMarkers.add(event.markerId);
        _currentUser['markersVisited'] = visitedMarkers;
        
        emit(UserUpdated(user: _currentUser));
      }
    } catch (e) {
      emit(UserError(message: 'Erro ao marcar visita: ${e.toString()}'));
    }
  }
  
  Future<void> _onEarnBadge(
    UserEarnBadge event,
    Emitter<UserState> emit,
  ) async {
    try {
      final earnedBadges = List<String>.from(_currentUser['badgesEarned'] ?? []);
      if (!earnedBadges.contains(event.badgeId)) {
        earnedBadges.add(event.badgeId);
        _currentUser['badgesEarned'] = earnedBadges;
        
        emit(UserUpdated(user: _currentUser));
      }
    } catch (e) {
      emit(UserError(message: 'Erro ao conquistar badge: ${e.toString()}'));
    }
  }
  
  String _calculateLevel(int points) {
    if (points >= 5000) return 'Eco Herói';
    if (points >= 2000) return 'Guardião Verde';
    if (points >= 500) return 'Explorador';
    return 'Iniciante';
  }
}