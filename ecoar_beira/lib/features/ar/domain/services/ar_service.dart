import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:ecoar_beira/core/models/ar_object_model.dart';
import 'package:ecoar_beira/core/models/ar_scene_model.dart';
import 'package:ecoar_beira/core/utils/logger.dart';

class ARService {
  static ARService? _instance;
  static ARService get instance => _instance ??= ARService._();
  ARService._();

  // AR Flutter Plugin managers - universal para Android/iOS
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;
  ARLocationManager? _locationManager;
  
  // Event management
  StreamController<AREvent>? _eventController;
  
  // State management
  bool _isInitialized = false;
  bool _isSessionActive = false;
  ARSceneModel? _currentScene;
  
  // Node tracking
  final Map<String, ARNode> _activeNodes = {};
  final Map<String, StreamSubscription> _nodeSubscriptions = {};

  // Public getters
  Stream<AREvent> get eventStream => _eventController?.stream ?? const Stream.empty();
  bool get isInitialized => _isInitialized;
  bool get isSessionActive => _isSessionActive;
  ARSceneModel? get currentScene => _currentScene;

  /// Initialize the AR service
  Future<bool> initialize() async {
    try {
      AppLogger.i('Initializing AR Service...');
      
      if (_isInitialized) {
        AppLogger.w('AR Service already initialized');
        return true;
      }

      // Initialize event stream
      _eventController = StreamController<AREvent>.broadcast();

      // Basic platform checks can be done here if needed
      // but ar_flutter_plugin handles platform differences internally
      
      _isInitialized = true;
      AppLogger.i('AR Service initialized successfully');
      _broadcastEvent(AREvent.initialized());
      return true;

    } catch (e, stackTrace) {
      AppLogger.e('Error initializing AR Service', e, stackTrace);
      _broadcastEvent(AREvent.error('Erro ao inicializar AR: ${e.toString()}'));
      return false;
    }
  }

  /// Configure AR managers from ARView widget
  void configureManagers({
    required ARSessionManager sessionManager,
    required ARObjectManager objectManager,
    required ARAnchorManager anchorManager,
    required ARLocationManager locationManager,
  }) {
    AppLogger.i('Configuring AR managers...');
    
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;
    _locationManager = locationManager;
    
    _setupEventListeners();
    AppLogger.i('AR managers configured successfully');
  }

  /// Setup event listeners for AR interactions
  void _setupEventListeners() {
    try {
      // Setup node tap listener
      _objectManager?.onNodeTap = (List<String> nodeNames) {
        if (nodeNames.isNotEmpty) {
          final nodeName = nodeNames.first;
          AppLogger.d('Node tapped: $nodeName');
          onObjectTapped(nodeName);
        }
      };

      // Setup plane detection listener (if available)
      _sessionManager?.onPlaneOrPointTap = (List<ARHitTestResult> hitResults) {
        AppLogger.d('Plane or point tapped - ${hitResults.length} hits');
        _handlePlaneDetection(hitResults);
      };

      AppLogger.d('AR event listeners configured');
    } catch (e, stackTrace) {
      AppLogger.e('Error setting up AR event listeners', e, stackTrace);
    }
  }

  /// Start AR session with configuration
  Future<bool> startSession({
    bool enablePlaneDetection = true,
    bool enableLightEstimation = true,
    bool enableImageTracking = false,
  }) async {
    try {
      if (!_isInitialized) {
        AppLogger.e('AR Service not initialized');
        return false;
      }

      if (_isSessionActive) {
        AppLogger.w('AR Session already active');
        return true;
      }

      AppLogger.i('Starting AR Session...');

      // Configure plane detection
      if (enablePlaneDetection && _sessionManager != null) {
        // await _sessionManager!.enablePlaneDetection(
        //   PlaneDetectionConfig.horizontalAndVertical,
        // );
      }

      _isSessionActive = true;
      _broadcastEvent(AREvent.sessionStarted());
      AppLogger.i('AR Session started successfully');
      return true;

    } catch (e, stackTrace) {
      AppLogger.e('Error starting AR session', e, stackTrace);
      _broadcastEvent(AREvent.error('Erro ao iniciar sessão AR: ${e.toString()}'));
      return false;
    }
  }

  /// Load complete AR scene
  Future<bool> loadScene(ARSceneModel scene) async {
    try {
      if (!_isSessionActive) {
        AppLogger.e('AR Session not active');
        return false;
      }

      AppLogger.i('Loading AR scene: ${scene.name}');
      _broadcastEvent(AREvent.loadingScene(scene.id));

      // Clear existing scene
      await clearScene();
      _currentScene = scene;

      // Load environment settings
      await _loadEnvironment(scene.environment);

      // Load lighting configuration
      await _loadLighting(scene.lighting);

      // Load sound configuration
      if (scene.sound != null) {
        await _loadSound(scene.sound!);
      }

      // Load all AR objects
      for (final object in scene.objects) {
        await _loadARObject(object);
      }

      // Setup interactions
      await _setupInteractions(scene.interactions);

      _broadcastEvent(AREvent.sceneLoaded(scene.id));
      AppLogger.i('AR scene loaded successfully: ${scene.name}');
      return true;

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR scene', e, stackTrace);
      _broadcastEvent(AREvent.error('Erro ao carregar cena AR: ${e.toString()}'));
      return false;
    }
  }

  /// Load individual AR object
  Future<void> _loadARObject(ARObjectModel object) async {
    try {
      AppLogger.d('Loading AR object: ${object.name}');

      if (_objectManager == null) {
        throw Exception('Object manager not configured');
      }

      // Create AR node based on object type
      final node = await _createARNode(object);
      if (node == null) {
        throw Exception('Failed to create AR node for ${object.name}');
      }

      // Add node to scene
      final success = await _objectManager!.addNode(node);
      if (success != true) {
        throw Exception('Failed to add node to AR scene');
      }

      // Store node reference
      _activeNodes[object.id] = node;

      // Start animations if any
      for (final animation in object.animations) {
        _startAnimation(object.id, animation);
      }

      _broadcastEvent(AREvent.objectLoaded(object.id));
      AppLogger.d('AR object loaded successfully: ${object.name}');

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR object: ${object.name}', e, stackTrace);
      _broadcastEvent(AREvent.error('Erro ao carregar objeto: ${object.name}'));
    }
  }

  /// Create AR node from object model
  Future<ARNode?> _createARNode(ARObjectModel object) async {
    try {
      NodeType nodeType;
      String? uri;

      // Determine node type and URI based on object
      if (object.modelPath.isNotEmpty) {
        if (object.modelPath.toLowerCase().endsWith('.glb') || 
            object.modelPath.toLowerCase().endsWith('.gltf')) {
          nodeType = NodeType.localGLTF2;
          uri = object.modelPath;
        } else if (object.modelPath.toLowerCase().endsWith('.dae')) {
          nodeType = NodeType.localGLTF2;
          uri = object.modelPath;
        } else {
          // Default to GLTF2 for unknown formats
          nodeType = NodeType.localGLTF2;
          uri = object.modelPath;
        }
      } else {
        // Create basic geometric shape for objects without models
        nodeType = _getGeometricNodeType(object.type);
      }

      // Create the AR node
      final node = ARNode(
        type: nodeType,
        uri: uri!,
        scale: Vector3(
          object.scale.x,
          object.scale.y,
          object.scale.z,
        ),
        position: Vector3(
          object.position.x,
          object.position.y,
          object.position.z,
        ),
        rotation: Vector4(
          object.rotation.x,
          object.rotation.y,
          object.rotation.z,
          object.rotation.x,
        ),
        name: object.id,
      );

      return node;

    } catch (e, stackTrace) {
      AppLogger.e('Error creating AR node', e, stackTrace);
      return null;
    }
  }

  /// Get geometric node type for object without model
  NodeType _getGeometricNodeType(ARObjectType objectType) {
    switch (objectType) {
      case ARObjectType.tree:
        return NodeType.localGLTF2; // Use a default tree model
      case ARObjectType.animal:
        return NodeType.localGLTF2; // Use a default animal model
      case ARObjectType.plant:
        return NodeType.localGLTF2; // Use a default plant model
      case ARObjectType.building:
        return NodeType.localGLTF2; // Use a default building model
      default:
        return NodeType.localGLTF2; // Default fallback
    }
  }

  /// Load environment configuration
  Future<void> _loadEnvironment(AREnvironment environment) async {
    try {
      AppLogger.d('Loading AR environment configuration');
      
      // Load particle systems
      for (final particleSystem in environment.particleSystems) {
        await _createParticleSystem(particleSystem);
      }

      // Environment fog and atmosphere settings would be handled by 
      // the AR framework automatically or through scene configuration

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR environment', e, stackTrace);
    }
  }

  /// Create particle system (simplified implementation)
  Future<void> _createParticleSystem(ARParticleSystem particleSystem) async {
    try {
      AppLogger.d('Creating particle system: ${particleSystem.id}');
      
      // For now, we'll create a simple representation
      // In a full implementation, this would create multiple small objects
      // to simulate particles or use a specialized particle system
      
      // This could be implemented by creating multiple small spheres
      // or using specialized particle effect models

    } catch (e, stackTrace) {
      AppLogger.e('Error creating particle system', e, stackTrace);
    }
  }

  /// Load lighting configuration
  Future<void> _loadLighting(ARLighting lighting) async {
    try {
      AppLogger.d('Setting up AR lighting');
      
      // Load individual lights
      for (final light in lighting.lights) {
        await _createLight(light);
      }

      // Lighting in ar_flutter_plugin is mostly handled automatically
      // through light estimation, but we can store configuration for
      // custom lighting effects

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR lighting', e, stackTrace);
    }
  }

  /// Create individual light (configuration storage)
  Future<void> _createLight(ARLight light) async {
    try {
      AppLogger.d('Configuring AR light: ${light.id}');
      
      // Store light configuration for potential future use
      // ar_flutter_plugin handles most lighting automatically

    } catch (e, stackTrace) {
      AppLogger.e('Error configuring AR light', e, stackTrace);
    }
  }

  /// Load sound configuration
  Future<void> _loadSound(ARSound sound) async {
    try {
      AppLogger.d('Loading AR sound configuration: ${sound.id}');
      
      // Sound would be handled by audioplayers package
      // Store configuration for 3D positional audio if needed

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR sound', e, stackTrace);
    }
  }

  /// Setup interaction handlers
  Future<void> _setupInteractions(List<ARInteraction> interactions) async {
    try {
      AppLogger.d('Setting up AR interactions');
      
      for (final interaction in interactions) {
        await _registerInteraction(interaction);
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error setting up AR interactions', e, stackTrace);
    }
  }

  /// Register individual interaction
  Future<void> _registerInteraction(ARInteraction interaction) async {
    try {
      AppLogger.d('Registering interaction: ${interaction.id}');
      
      switch (interaction.trigger) {
        case ARInteractionTrigger.onTap:
          _setupTapInteraction(interaction);
          break;
        case ARInteractionTrigger.onLongPress:
          _setupLongPressInteraction(interaction);
          break;
        case ARInteractionTrigger.onApproach:
          _setupProximityInteraction(interaction);
          break;
        case ARInteractionTrigger.onTimer:
          _setupTimerInteraction(interaction);
          break;
        default:
          AppLogger.w('Unsupported interaction trigger: ${interaction.trigger}');
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error registering interaction', e, stackTrace);
    }
  }

  void _setupTapInteraction(ARInteraction interaction) {
    AppLogger.d('Setting up tap interaction for: ${interaction.targetObjectId}');
    // Tap interactions are handled by the onNodeTap callback
  }

  void _setupLongPressInteraction(ARInteraction interaction) {
    AppLogger.d('Setting up long press interaction for: ${interaction.targetObjectId}');
    // Long press would need custom gesture detection
  }

  void _setupProximityInteraction(ARInteraction interaction) {
    AppLogger.d('Setting up proximity interaction for: ${interaction.targetObjectId}');
    // Proximity detection would use location manager
  }

  void _setupTimerInteraction(ARInteraction interaction) {
    final delay = Duration(
      milliseconds: interaction.parameters['delay'] as int? ?? 0,
    );
    
    Timer(delay, () {
      _executeInteractionEffects(interaction.effects);
    });
  }

  /// Execute interaction effects
  void _executeInteractionEffects(List<ARInteractionEffect> effects) {
    for (final effect in effects) {
      Timer(effect.delay, () {
        _executeEffect(effect);
      });
    }
  }

  /// Execute individual effect
  void _executeEffect(ARInteractionEffect effect) {
    switch (effect.type) {
      case AREffectType.playAnimation:
        _playAnimation(effect.parameters);
        break;
      case AREffectType.playSound:
        _playSound(effect.parameters);
        break;
      case AREffectType.showDialog:
        _showDialog(effect.parameters);
        break;
      case AREffectType.addPoints:
        _addPoints(effect.parameters);
        break;
      case AREffectType.spawnParticles:
        _spawnParticles(effect.parameters);
        break;
      default:
        AppLogger.w('Unsupported effect type: ${effect.type}');
    }
  }

  void _playAnimation(Map<String, dynamic> parameters) {
    final objectId = parameters['objectId'] as String;
    final animationId = parameters['animationId'] as String;
    
    AppLogger.d('Playing animation: $animationId on object: $objectId');
    _broadcastEvent(AREvent.animationStarted(objectId, animationId));
  }

  void _playSound(Map<String, dynamic> parameters) {
    final soundId = parameters['soundId'] as String;
    AppLogger.d('Playing sound: $soundId');
    _broadcastEvent(AREvent.soundPlayed(soundId));
  }

  void _showDialog(Map<String, dynamic> parameters) {
    final title = parameters['title'] as String;
    final message = parameters['message'] as String;
    
    AppLogger.d('Showing dialog: $title');
    _broadcastEvent(AREvent.dialogRequested(title, message));
  }

  void _addPoints(Map<String, dynamic> parameters) {
    final points = parameters['points'] as int;
    AppLogger.d('Adding points: $points');
    _broadcastEvent(AREvent.pointsEarned(points));
  }

  void _spawnParticles(Map<String, dynamic> parameters) {
    final position = parameters['position'] as Map<String, dynamic>;
    AppLogger.d('Spawning particles at: $position');
    _broadcastEvent(AREvent.particlesSpawned(position));
  }

  /// Start animation on object
  void _startAnimation(String objectId, ARAnimation animation) {
    AppLogger.d('Starting animation: ${animation.id} on object: $objectId');
    
    // Create animation timer
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = timer.tick * 16;
      if (elapsed >= animation.duration.inMilliseconds) {
        timer.cancel();
        if (animation.isLooping) {
          _startAnimation(objectId, animation);
        }
      }
    });
  }

  /// Handle plane detection results
  void _handlePlaneDetection(List<ARHitTestResult> hitResults) {
    for (final result in hitResults) {
      AppLogger.d('Plane detected at: ${result.worldTransform}');
      _broadcastEvent(AREvent.planeDetected('plane_${DateTime.now().millisecondsSinceEpoch}'));
    }
  }

  /// Handle object tap events
  Future<void> onObjectTapped(String objectId) async {
    try {
      AppLogger.d('Object tapped: $objectId');
      _broadcastEvent(AREvent.objectTapped(objectId));

      // Find and execute tap interactions for this object
      if (_currentScene != null) {
        final tapInteractions = _currentScene!.interactions
            .where((i) => 
                i.targetObjectId == objectId && 
                i.trigger == ARInteractionTrigger.onTap)
            .toList();

        for (final interaction in tapInteractions) {
          _executeInteractionEffects(interaction.effects);
        }
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error handling object tap', e, stackTrace);
    }
  }

  /// Clear all objects from current scene
  Future<void> clearScene() async {
    try {
      AppLogger.d('Clearing AR scene');

      if (_objectManager != null) {
        // Remove all active nodes
        for (final entry in _activeNodes.entries) {
          try {
            await _objectManager!.removeNode(entry.value);
          } catch (e) {
            AppLogger.w('Error removing node ${entry.key}: $e');
          }
        }
      }

      // Cancel all subscriptions
      for (final subscription in _nodeSubscriptions.values) {
        await subscription.cancel();
      }

      // Clear tracking maps
      _activeNodes.clear();
      _nodeSubscriptions.clear();
      
      _currentScene = null;
      _broadcastEvent(AREvent.sceneCleared());

    } catch (e, stackTrace) {
      AppLogger.e('Error clearing AR scene', e, stackTrace);
    }
  }

  /// Pause AR session
  Future<void> pauseSession() async {
    try {
      if (!_isSessionActive) return;

      AppLogger.i('Pausing AR session');
      
      // await _sessionManager?.pause();
      _broadcastEvent(AREvent.sessionPaused());

    } catch (e, stackTrace) {
      AppLogger.e('Error pausing AR session', e, stackTrace);
    }
  }

  /// Resume AR session
  Future<void> resumeSession() async {
    try {
      if (!_isInitialized) return;

      AppLogger.i('Resuming AR session');
      
      // await _sessionManager?.resume();
      _isSessionActive = true;
      _broadcastEvent(AREvent.sessionResumed());

    } catch (e, stackTrace) {
      AppLogger.e('Error resuming AR session', e, stackTrace);
    }
  }

  /// Stop AR session
  Future<void> stopSession() async {
    try {
      if (!_isSessionActive) return;

      AppLogger.i('Stopping AR session');

      // Clear scene first
      await clearScene();

      // Dispose managers
      await _sessionManager?.dispose();
      // await _objectManager?.dispose();
      // await _anchorManager?.dispose();
      // await _locationManager?.dispose();

      // Reset references
      _sessionManager = null;
      _objectManager = null;
      _anchorManager = null;
      _locationManager = null;

      _isSessionActive = false;
      _broadcastEvent(AREvent.sessionStopped());

    } catch (e, stackTrace) {
      AppLogger.e('Error stopping AR session', e, stackTrace);
    }
  }

  /// Broadcast event to listeners
  void _broadcastEvent(AREvent event) {
    _eventController?.add(event);
  }

  /// Dispose service and cleanup resources
  Future<void> dispose() async {
    try {
      AppLogger.i('Disposing AR Service');

      await stopSession();
      await _eventController?.close();
      _eventController = null;
      _isInitialized = false;

    } catch (e, stackTrace) {
      AppLogger.e('Error disposing AR Service', e, stackTrace);
    }
  }
}

// AR Event Classes
abstract class AREvent {
  const AREvent();

  factory AREvent.initialized() = ARInitializedEvent;
  factory AREvent.sessionStarted() = ARSessionStartedEvent;
  factory AREvent.sessionPaused() = ARSessionPausedEvent;
  factory AREvent.sessionResumed() = ARSessionResumedEvent;
  factory AREvent.sessionStopped() = ARSessionStoppedEvent;
  factory AREvent.loadingScene(String sceneId) = ARLoadingSceneEvent;
  factory AREvent.sceneLoaded(String sceneId) = ARSceneLoadedEvent;
  factory AREvent.sceneCleared() = ARSceneClearedEvent;
  factory AREvent.objectLoaded(String objectId) = ARObjectLoadedEvent;
  factory AREvent.objectTapped(String objectId) = ARObjectTappedEvent;
  factory AREvent.animationStarted(String objectId, String animationId) = ARAnimationStartedEvent;
  factory AREvent.soundPlayed(String soundId) = ARSoundPlayedEvent;
  factory AREvent.pointsEarned(int points) = ARPointsEarnedEvent;
  factory AREvent.dialogRequested(String title, String message) = ARDialogRequestedEvent;
  factory AREvent.particlesSpawned(Map<String, dynamic> position) = ARParticlesSpawnedEvent;
  factory AREvent.planeDetected(String planeId) = ARPlaneDetectedEvent;
  factory AREvent.error(String message) = ARErrorEvent;
}

class ARInitializedEvent extends AREvent {
  const ARInitializedEvent();
}

class ARSessionStartedEvent extends AREvent {
  const ARSessionStartedEvent();
}

class ARSessionPausedEvent extends AREvent {
  const ARSessionPausedEvent();
}

class ARSessionResumedEvent extends AREvent {
  const ARSessionResumedEvent();
}

class ARSessionStoppedEvent extends AREvent {
  const ARSessionStoppedEvent();
}

class ARLoadingSceneEvent extends AREvent {
  final String sceneId;
  const ARLoadingSceneEvent(this.sceneId);
}

class ARSceneLoadedEvent extends AREvent {
  final String sceneId;
  const ARSceneLoadedEvent(this.sceneId);
}

class ARSceneClearedEvent extends AREvent {
  const ARSceneClearedEvent();
}

class ARObjectLoadedEvent extends AREvent {
  final String objectId;
  const ARObjectLoadedEvent(this.objectId);
}

class ARObjectTappedEvent extends AREvent {
  final String objectId;
  const ARObjectTappedEvent(this.objectId);
}

class ARAnimationStartedEvent extends AREvent {
  final String objectId;
  final String animationId;
  const ARAnimationStartedEvent(this.objectId, this.animationId);
}

class ARSoundPlayedEvent extends AREvent {
  final String soundId;
  const ARSoundPlayedEvent(this.soundId);
}

class ARPointsEarnedEvent extends AREvent {
  final int points;
  const ARPointsEarnedEvent(this.points);
}

class ARDialogRequestedEvent extends AREvent {
  final String title;
  final String message;
  const ARDialogRequestedEvent(this.title, this.message);
}

class ARParticlesSpawnedEvent extends AREvent {
  final Map<String, dynamic> position;
  const ARParticlesSpawnedEvent(this.position);
}

class ARPlaneDetectedEvent extends AREvent {
  final String planeId;
  const ARPlaneDetectedEvent(this.planeId);
}

class ARErrorEvent extends AREvent {
  final String message;
  const ARErrorEvent(this.message);
}