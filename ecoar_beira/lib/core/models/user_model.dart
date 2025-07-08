// lib/core/models/user_model.dart
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final int points;
  
  @HiveField(4)
  final UserLevel level;
  
  @HiveField(5)
  final List<String> visitedMarkers;
  
  @HiveField(6)
  final List<String> earnedBadges;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    required this.level,
    required this.visitedMarkers,
    required this.earnedBadges,
    required this.createdAt,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? points,
    UserLevel? level,
    List<String>? visitedMarkers,
    List<String>? earnedBadges,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      points: points ?? this.points,
      level: level ?? this.level,
      visitedMarkers: visitedMarkers ?? this.visitedMarkers,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        points,
        level,
        visitedMarkers,
        earnedBadges,
        createdAt,
        avatarUrl,
      ];
}

@HiveType(typeId: 1)
enum UserLevel {
  @HiveField(0)
  iniciante, // 0-500 pontos
  
  @HiveField(1)
  explorador, // 500-2000 pontos
  
  @HiveField(2)
  guardiaoVerde, // 2000-5000 pontos
  
  @HiveField(3)
  ecoHeroi, // 5000+ pontos
}

// lib/core/models/marker_model.dart
@HiveType(typeId: 2)
class MarkerModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final MarkerLocation location;
  
  @HiveField(4)
  final MarkerType type;
  
  @HiveField(5)
  final List<ChallengeModel> challenges;
  
  @HiveField(6)
  final int points;
  
  @HiveField(7)
  final String qrCode;
  
  @HiveField(8)
  final String arSceneId;
  
  @HiveField(9)
  final bool isActive;
  
  @HiveField(10)
  final List<String> imageUrls;

  const MarkerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.challenges,
    required this.points,
    required this.qrCode,
    required this.arSceneId,
    required this.isActive,
    required this.imageUrls,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        type,
        challenges,
        points,
        qrCode,
        arSceneId,
        isActive,
        imageUrls,
      ];
}

@HiveType(typeId: 3)
class MarkerLocation extends Equatable {
  @HiveField(0)
  final double latitude;
  
  @HiveField(1)
  final double longitude;
  
  @HiveField(2)
  final String address;

  const MarkerLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

@HiveType(typeId: 4)
enum MarkerType {
  @HiveField(0)
  biodiversidade, // Bacia 1
  
  @HiveField(1)
  recursosHidricos, // Bacia 2
  
  @HiveField(2)
  agriculturaUrbana, // Bacia 3
}

// lib/core/models/challenge_model.dart
@HiveType(typeId: 5)
class ChallengeModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final ChallengeType type;
  
  @HiveField(4)
  final List<QuestionModel> questions;
  
  @HiveField(5)
  final int points;
  
  @HiveField(6)
  final Duration estimatedDuration;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.questions,
    required this.points,
    required this.estimatedDuration,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        questions,
        points,
        estimatedDuration,
      ];
}

@HiveType(typeId: 6)
enum ChallengeType {
  @HiveField(0)
  quiz,
  
  @HiveField(1)
  identificacao,
  
  @HiveField(2)
  simulacao,
  
  @HiveField(3)
  cacaoTesouro,
}

@HiveType(typeId: 7)
class QuestionModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String question;
  
  @HiveField(2)
  final List<String> options;
  
  @HiveField(3)
  final int correctAnswerIndex;
  
  @HiveField(4)
  final String explanation;
  
  @HiveField(5)
  final String? imageUrl;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        question,
        options,
        correctAnswerIndex,
        explanation,
        imageUrl,
      ];
}

// lib/core/models/badge_model.dart
@HiveType(typeId: 8)
class BadgeModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String iconUrl;
  
  @HiveField(4)
  final BadgeCategory category;
  
  @HiveField(5)
  final DateTime? earnedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    this.earnedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        category,
        earnedAt,
      ];
}

@HiveType(typeId: 9)
enum BadgeCategory {
  @HiveField(0)
  descobridor,
  
  @HiveField(1)
  cientista,
  
  @HiveField(2)
  aventureiro,
  
  @HiveField(3)
  influencer,
  
  @HiveField(4)
  especial,
}