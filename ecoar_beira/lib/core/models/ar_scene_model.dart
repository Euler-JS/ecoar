import 'package:ecoar_beira/core/models/ar_object_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/rendering.dart';

class ARSceneModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String markerId;
  final List<ARObjectModel> objects;
  final AREnvironment environment;
  final List<ARInteraction> interactions;
  final ARLighting lighting;
  final ARSound? sound;
  final Duration maxDuration;
  final Map<String, dynamic> metadata;

  const ARSceneModel({
    required this.id,
    required this.name,
    required this.description,
    required this.markerId,
    required this.objects,
    required this.environment,
    required this.interactions,
    required this.lighting,
    this.sound,
    required this.maxDuration,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        markerId,
        objects,
        environment,
        interactions,
        lighting,
        sound,
        maxDuration,
        metadata,
      ];

  factory ARSceneModel.fromJson(Map<String, dynamic> json) {
    return ARSceneModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      markerId: json['markerId'] as String,
      objects: (json['objects'] as List)
          .map((o) => ARObjectModel.fromJson(o))
          .toList(),
      environment: AREnvironment.fromJson(json['environment']),
      interactions: (json['interactions'] as List)
          .map((i) => ARInteraction.fromJson(i))
          .toList(),
      lighting: ARLighting.fromJson(json['lighting']),
      sound: json['sound'] != null ? ARSound.fromJson(json['sound']) : null,
      maxDuration: Duration(seconds: json['maxDuration'] as int),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'markerId': markerId,
      'objects': objects.map((o) => o.toJson()).toList(),
      'environment': environment.toJson(),
      'interactions': interactions.map((i) => i.toJson()).toList(),
      'lighting': lighting.toJson(),
      'sound': sound?.toJson(),
      'maxDuration': maxDuration.inSeconds,
      'metadata': metadata,
    };
  }
}

class AREnvironment extends Equatable {
  final String skyboxPath;
  final Color backgroundColor;
  final double fogDensity;
  final Color fogColor;
  final List<ARParticleSystem> particleSystems;

  const AREnvironment({
    required this.skyboxPath,
    required this.backgroundColor,
    required this.fogDensity,
    required this.fogColor,
    required this.particleSystems,
  });

  @override
  List<Object?> get props => [
        skyboxPath,
        backgroundColor,
        fogDensity,
        fogColor,
        particleSystems,
      ];

  factory AREnvironment.fromJson(Map<String, dynamic> json) {
    return AREnvironment(
      skyboxPath: json['skyboxPath'] as String,
      backgroundColor: Color(json['backgroundColor'] as int),
      fogDensity: (json['fogDensity'] as num).toDouble(),
      fogColor: Color(json['fogColor'] as int),
      particleSystems: (json['particleSystems'] as List)
          .map((p) => ARParticleSystem.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skyboxPath': skyboxPath,
      'backgroundColor': backgroundColor.value,
      'fogDensity': fogDensity,
      'fogColor': fogColor.value,
      'particleSystems': particleSystems.map((p) => p.toJson()).toList(),
    };
  }
}

class ARParticleSystem extends Equatable {
  final String id;
  final ARPosition position;
  final int maxParticles;
  final double emissionRate;
  final Duration lifetime;
  final ARPosition velocity;
  final Color color;
  final double size;

  const ARParticleSystem({
    required this.id,
    required this.position,
    required this.maxParticles,
    required this.emissionRate,
    required this.lifetime,
    required this.velocity,
    required this.color,
    required this.size,
  });

  @override
  List<Object?> get props => [
        id,
        position,
        maxParticles,
        emissionRate,
        lifetime,
        velocity,
        color,
        size,
      ];

  factory ARParticleSystem.fromJson(Map<String, dynamic> json) {
    return ARParticleSystem(
      id: json['id'] as String,
      position: ARPosition.fromJson(json['position']),
      maxParticles: json['maxParticles'] as int,
      emissionRate: (json['emissionRate'] as num).toDouble(),
      lifetime: Duration(milliseconds: json['lifetime'] as int),
      velocity: ARPosition.fromJson(json['velocity']),
      color: Color(json['color'] as int),
      size: (json['size'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position.toJson(),
      'maxParticles': maxParticles,
      'emissionRate': emissionRate,
      'lifetime': lifetime.inMilliseconds,
      'velocity': velocity.toJson(),
      'color': color.value,
      'size': size,
    };
  }
}

class ARInteraction extends Equatable {
  final String id;
  final ARInteractionType type;
  final String targetObjectId;
  final ARInteractionTrigger trigger;
  final Map<String, dynamic> parameters;
  final List<ARInteractionEffect> effects;

  const ARInteraction({
    required this.id,
    required this.type,
    required this.targetObjectId,
    required this.trigger,
    required this.parameters,
    required this.effects,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        targetObjectId,
        trigger,
        parameters,
        effects,
      ];

  factory ARInteraction.fromJson(Map<String, dynamic> json) {
    return ARInteraction(
      id: json['id'] as String,
      type: ARInteractionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      targetObjectId: json['targetObjectId'] as String,
      trigger: ARInteractionTrigger.values.firstWhere(
        (e) => e.toString().split('.').last == json['trigger'],
      ),
      parameters: json['parameters'] as Map<String, dynamic>,
      effects: (json['effects'] as List)
          .map((e) => ARInteractionEffect.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'targetObjectId': targetObjectId,
      'trigger': trigger.toString().split('.').last,
      'parameters': parameters,
      'effects': effects.map((e) => e.toJson()).toList(),
    };
  }
}

enum ARInteractionType {
  tap,
  longPress,
  proximity,
  voice,
  gesture,
  timer,
}

enum ARInteractionTrigger {
  onTap,
  onLongPress,
  onApproach,
  onVoiceCommand,
  onGesture,
  onTimer,
  onSceneStart,
}

class ARInteractionEffect extends Equatable {
  final String id;
  final AREffectType type;
  final Map<String, dynamic> parameters;
  final Duration delay;
  final Duration duration;

  const ARInteractionEffect({
    required this.id,
    required this.type,
    required this.parameters,
    required this.delay,
    required this.duration,
  });

  @override
  List<Object?> get props => [id, type, parameters, delay, duration];

  factory ARInteractionEffect.fromJson(Map<String, dynamic> json) {
    return ARInteractionEffect(
      id: json['id'] as String,
      type: AREffectType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      parameters: json['parameters'] as Map<String, dynamic>,
      delay: Duration(milliseconds: json['delay'] as int),
      duration: Duration(milliseconds: json['duration'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'parameters': parameters,
      'delay': delay.inMilliseconds,
      'duration': duration.inMilliseconds,
    };
  }
}

enum AREffectType {
  playAnimation,
  playSound,
  showDialog,
  addPoints,
  spawnParticles,
  changeColor,
  changeScale,
  changePosition,
  showInformation,
  startQuiz,
}

class ARLighting extends Equatable {
  final Color ambientColor;
  final double ambientIntensity;
  final List<ARLight> lights;

  const ARLighting({
    required this.ambientColor,
    required this.ambientIntensity,
    required this.lights,
  });

  @override
  List<Object?> get props => [ambientColor, ambientIntensity, lights];

  factory ARLighting.fromJson(Map<String, dynamic> json) {
    return ARLighting(
      ambientColor: Color(json['ambientColor'] as int),
      ambientIntensity: (json['ambientIntensity'] as num).toDouble(),
      lights: (json['lights'] as List)
          .map((l) => ARLight.fromJson(l))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ambientColor': ambientColor.value,
      'ambientIntensity': ambientIntensity,
      'lights': lights.map((l) => l.toJson()).toList(),
    };
  }
}

class ARLight extends Equatable {
  final String id;
  final ARLightType type;
  final ARPosition position;
  final ARRotation rotation;
  final Color color;
  final double intensity;
  final double range;

  const ARLight({
    required this.id,
    required this.type,
    required this.position,
    required this.rotation,
    required this.color,
    required this.intensity,
    required this.range,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        position,
        rotation,
        color,
        intensity,
        range,
      ];

  factory ARLight.fromJson(Map<String, dynamic> json) {
    return ARLight(
      id: json['id'] as String,
      type: ARLightType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      position: ARPosition.fromJson(json['position']),
      rotation: ARRotation.fromJson(json['rotation']),
      color: Color(json['color'] as int),
      intensity: (json['intensity'] as num).toDouble(),
      range: (json['range'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'position': position.toJson(),
      'rotation': rotation.toJson(),
      'color': color.value,
      'intensity': intensity,
      'range': range,
    };
  }
}

enum ARLightType {
  directional,
  point,
  spot,
}

class ARSound extends Equatable {
  final String id;
  final String audioPath;
  final bool isLooping;
  final double volume;
  final bool is3D;
  final ARPosition? position;

  const ARSound({
    required this.id,
    required this.audioPath,
    required this.isLooping,
    required this.volume,
    required this.is3D,
    this.position,
  });

  @override
  List<Object?> get props => [id, audioPath, isLooping, volume, is3D, position];

  factory ARSound.fromJson(Map<String, dynamic> json) {
    return ARSound(
      id: json['id'] as String,
      audioPath: json['audioPath'] as String,
      isLooping: json['isLooping'] as bool,
      volume: (json['volume'] as num).toDouble(),
      is3D: json['is3D'] as bool,
      position: json['position'] != null
          ? ARPosition.fromJson(json['position'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioPath': audioPath,
      'isLooping': isLooping,
      'volume': volume,
      'is3D': is3D,
      'position': position?.toJson(),
    };
  }
}