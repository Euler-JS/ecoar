import 'package:equatable/equatable.dart';

class ARObjectModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final ARObjectType type;
  final String modelPath;
  final String texturePath;
  final ARPosition position;
  final ARRotation rotation;
  final ARScale scale;
  final List<ARAnimation> animations;
  final Map<String, dynamic> interactionData;
  final bool isInteractable;
  final int points;

  const ARObjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.modelPath,
    required this.texturePath,
    required this.position,
    required this.rotation,
    required this.scale,
    required this.animations,
    required this.interactionData,
    required this.isInteractable,
    required this.points,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        modelPath,
        texturePath,
        position,
        rotation,
        scale,
        animations,
        interactionData,
        isInteractable,
        points,
      ];

  factory ARObjectModel.fromJson(Map<String, dynamic> json) {
    return ARObjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ARObjectType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      modelPath: json['modelPath'] as String,
      texturePath: json['texturePath'] as String,
      position: ARPosition.fromJson(json['position']),
      rotation: ARRotation.fromJson(json['rotation']),
      scale: ARScale.fromJson(json['scale']),
      animations: (json['animations'] as List)
          .map((a) => ARAnimation.fromJson(a))
          .toList(),
      interactionData: json['interactionData'] as Map<String, dynamic>,
      isInteractable: json['isInteractable'] as bool,
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'modelPath': modelPath,
      'texturePath': texturePath,
      'position': position.toJson(),
      'rotation': rotation.toJson(),
      'scale': scale.toJson(),
      'animations': animations.map((a) => a.toJson()).toList(),
      'interactionData': interactionData,
      'isInteractable': isInteractable,
      'points': points,
    };
  }
}

enum ARObjectType {
  animal,
  plant,
  tree,
  building,
  waterFeature,
  interactive,
  information,
  quiz,
}

class ARPosition extends Equatable {
  final double x;
  final double y;
  final double z;

  const ARPosition({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  List<Object?> get props => [x, y, z];

  factory ARPosition.fromJson(Map<String, dynamic> json) {
    return ARPosition(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }
}

class ARRotation extends Equatable {
  final double x;
  final double y;
  final double z;

  const ARRotation({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  List<Object?> get props => [x, y, z];

  factory ARRotation.fromJson(Map<String, dynamic> json) {
    return ARRotation(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }
}

class ARScale extends Equatable {
  final double x;
  final double y;
  final double z;

  const ARScale({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  List<Object?> get props => [x, y, z];

  factory ARScale.fromJson(Map<String, dynamic> json) {
    return ARScale(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }
}

class ARAnimation extends Equatable {
  final String id;
  final ARAnimationType type;
  final Duration duration;
  final bool isLooping;
  final ARPosition? startPosition;
  final ARPosition? endPosition;
  final ARRotation? startRotation;
  final ARRotation? endRotation;
  final ARScale? startScale;
  final ARScale? endScale;

  const ARAnimation({
    required this.id,
    required this.type,
    required this.duration,
    required this.isLooping,
    this.startPosition,
    this.endPosition,
    this.startRotation,
    this.endRotation,
    this.startScale,
    this.endScale,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        duration,
        isLooping,
        startPosition,
        endPosition,
        startRotation,
        endRotation,
        startScale,
        endScale,
      ];

  factory ARAnimation.fromJson(Map<String, dynamic> json) {
    return ARAnimation(
      id: json['id'] as String,
      type: ARAnimationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      duration: Duration(milliseconds: json['duration'] as int),
      isLooping: json['isLooping'] as bool,
      startPosition: json['startPosition'] != null
          ? ARPosition.fromJson(json['startPosition'])
          : null,
      endPosition: json['endPosition'] != null
          ? ARPosition.fromJson(json['endPosition'])
          : null,
      startRotation: json['startRotation'] != null
          ? ARRotation.fromJson(json['startRotation'])
          : null,
      endRotation: json['endRotation'] != null
          ? ARRotation.fromJson(json['endRotation'])
          : null,
      startScale: json['startScale'] != null
          ? ARScale.fromJson(json['startScale'])
          : null,
      endScale: json['endScale'] != null
          ? ARScale.fromJson(json['endScale'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'duration': duration.inMilliseconds,
      'isLooping': isLooping,
      'startPosition': startPosition?.toJson(),
      'endPosition': endPosition?.toJson(),
      'startRotation': startRotation?.toJson(),
      'endRotation': endRotation?.toJson(),
      'startScale': startScale?.toJson(),
      'endScale': endScale?.toJson(),
    };
  }
}

enum ARAnimationType {
  move,
  rotate,
  scale,
  fade,
  bounce,
  pulse,
  custom,
}