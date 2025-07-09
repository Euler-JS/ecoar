import 'dart:async';
import 'dart:io';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:ecoar_beira/core/models/ar_object_model.dart';
import 'package:ecoar_beira/core/models/ar_scene_model.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:vector_math/vector_math.dart' hide Vector3, Vector4;
import 'package:vector_math/vector_math_64.dart';
import 'package:vector_math/vector_math_64.dart' as arcore show Vector3;

class ARService {
  static ARService? _instance;
  static ARService get instance => _instance ??= ARService._();
  ARService._();

  ArCoreController? _arCoreController;
  ArCoreMaterial? _arCoreMaterial;

  // arcore.ArCoreController? _arCoreController;
  
  // Corrigido: Usar as classes corretas do ar_flutter_plugin
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  
  StreamController<AREvent>? _eventController;
  bool _isInitialized = false;
  bool _isSessionActive = false;
  ARSceneModel? _currentScene;
  final Map<String, ArCoreNode> _arCoreNodes = {};
  final Map<String, ARNode> _arNodes = {}; // Corrigido: ARNode sem prefixo

  Stream<AREvent> get eventStream => _eventController?.stream ?? const Stream.empty();
  bool get isInitialized => _isInitialized;
  bool get isSessionActive => _isSessionActive;
  ARSceneModel? get currentScene => _currentScene;

  Future<bool> initialize() async {
    try {
      AppLogger.i('Initializing AR Service...');
      
      if (_isInitialized) {
        AppLogger.w('AR Service already initialized');
        return true;
      }

      _eventController = StreamController<AREvent>.broadcast();

      // Check AR availability
      if (Platform.isAndroid) {
        final isAvailable = await ArCoreController.checkArCoreAvailability();
        if (!isAvailable) {
          AppLogger.e('ARCore not available on this device');
          _broadcastEvent(AREvent.error('ARCore não disponível neste dispositivo'));
          return false;
        }

        final isInstalled = await ArCoreController.checkIsArCoreInstalled();
        if (!isInstalled) {
          AppLogger.e('ARCore not installed');
          _broadcastEvent(AREvent.error('ARCore não está instalado'));
          return false;
        }
      }

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

      if (Platform.isAndroid) {
        // Configure ARCore session
        // This would be handled by the ArCoreView widget
        _isSessionActive = true;
      } else if (Platform.isIOS) {
        // Corrigido: Inicialização correta para iOS
        // Os managers são inicializados junto com o ARView widget
        _isSessionActive = true;
      }

      _broadcastEvent(AREvent.sessionStarted());
      AppLogger.i('AR Session started successfully');
      return true;

    } catch (e, stackTrace) {
      AppLogger.e('Error starting AR session', e, stackTrace);
      _broadcastEvent(AREvent.error('Erro ao iniciar sessão AR: ${e.toString()}'));
      return false;
    }
  }

  // Método para configurar os managers do ARKit (chamado pelo widget AR)
  void configureARKitManagers({
    required ARSessionManager sessionManager,
    required ARObjectManager objectManager,
    required ARAnchorManager anchorManager,
  }) {
    _arSessionManager = sessionManager;
    _arObjectManager = objectManager;
    _arAnchorManager = anchorManager;
    
    // Configurar callbacks
    // _arSessionManager?.onInitialize = () {
    //   AppLogger.i('ARKit session initialized');
    //   _isSessionActive = true;
    //   _broadcastEvent(AREvent.sessionStarted());
    // };

    // _arSessionManager?.onPlaneOrPointTap = (List<ARHitTestResult> hitResults) {
    //   AppLogger.d('Plane or point tapped');
    //   // Processar tap nos planos
    // };

    _arObjectManager?.onNodeTap = (List<String> nodeNames) {
      if (nodeNames.isNotEmpty) {
        final nodeName = nodeNames.first;
        AppLogger.d('Node tapped: $nodeName');
        onObjectTapped(nodeName);
      }
    };
  }

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

      // Load environment
      await _loadEnvironment(scene.environment);

      // Load lighting
      await _loadLighting(scene.lighting);

      // Load sound
      if (scene.sound != null) {
        await _loadSound(scene.sound!);
      }

      // Load AR objects
      for (final object in scene.objects) {
        await _loadARObject(object);
      }

      // Setup interactions
      await _setupInteractions(scene.interactions);

      _broadcastEvent(AREvent.sceneLoaded(scene.id));
      AppLogger.i('AR scene loaded successfully');
      return true;

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR scene', e, stackTrace);
      _broadcastEvent(AREvent.error('Erro ao carregar cena AR: ${e.toString()}'));
      return false;
    }
  }

  Future<void> _loadARObject(ARObjectModel object) async {
    try {
      AppLogger.d('Loading AR object: ${object.name}');

      if (Platform.isAndroid) {
        await _loadARCoreObject(object);
      } else if (Platform.isIOS) {
        await _loadARKitObject(object);
      }

      _broadcastEvent(AREvent.objectLoaded(object.id));

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR object: ${object.name}', e, stackTrace);
      _broadcastEvent(AREvent.error('Erro ao carregar objeto AR: ${object.name}'));
    }
  }

  Future<void> _loadARCoreObject(ARObjectModel object) async {
    if (_arCoreController == null) return;

    try {
      // Create ARCore node
      // Create appropriate shape based on object type
      switch (object.type) {
        case ARObjectType.animal:
        case ARObjectType.plant:
          if (object.modelPath.isNotEmpty) {
           
          } else {
            
          }
          break;
        case ARObjectType.tree:
          
          break;
        case ARObjectType.building:
          
          break;
        default:
          
      }

      // Start animations if any
      for (final animation in object.animations) {
        _startAnimation(object.id, animation);
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error loading ARCore object', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _loadARKitObject(ARObjectModel object) async {
    if (_arObjectManager == null) return;

    try {
      AppLogger.d('Loading ARKit object: ${object.name}');
      
      // Corrigido: Criação correta do ARNode
      final node = ARNode(
        type: NodeType.localGLTF2,
        uri: object.modelPath,
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
          1.0,
        ),
        name: object.id,
      );

      _arNodes[object.id] = node;

      // Corrigido: Adicionar node usando o object manager
      final success = await _arObjectManager!.addNode(node);
      if (!success!) {
        AppLogger.e('Failed to add ARKit node: ${object.id}');
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error loading ARKit object', e, stackTrace);
      rethrow;
    }
  }

  Future<Uint8List?> _loadTexture(String texturePath) async {
    try {
      if (texturePath.isEmpty) return null;
      
      if (texturePath.startsWith('assets/')) {
        final byteData = await rootBundle.load(texturePath);
        return byteData.buffer.asUint8List();
      } else {
        final file = File(texturePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      AppLogger.e('Error loading texture: $texturePath', e);
      return null;
    }
  }

  Future<void> _loadEnvironment(AREnvironment environment) async {
    try {
      AppLogger.d('Loading AR environment');
      
      // Load particle systems
      for (final particleSystem in environment.particleSystems) {
        await _createParticleSystem(particleSystem);
      }

      // Set fog and lighting would be handled by the AR framework
      // This is a simplified implementation

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR environment', e, stackTrace);
    }
  }

  Future<void> _createParticleSystem(ARParticleSystem particleSystem) async {
    try {
      AppLogger.d('Creating particle system: ${particleSystem.id}');
      
      // Create particle system - this would be implemented based on the AR framework
      // For now, we'll create a simple representation
      
      if (Platform.isAndroid && _arCoreController != null) {
        // Create multiple small spheres to simulate particles
       
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error creating particle system', e, stackTrace);
    }
  }

  Future<void> _loadLighting(ARLighting lighting) async {
    try {
      AppLogger.d('Setting up AR lighting');
      
      // Load individual lights
      for (final light in lighting.lights) {
        await _createLight(light);
      }

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR lighting', e, stackTrace);
    }
  }

  Future<void> _createLight(ARLight light) async {
    try {
      AppLogger.d('Creating AR light: ${light.id}');
      
      // Light creation would be framework-specific
      // This is a simplified implementation

    } catch (e, stackTrace) {
      AppLogger.e('Error creating AR light', e, stackTrace);
    }
  }

  Future<void> _loadSound(ARSound sound) async {
    try {
      AppLogger.d('Loading AR sound: ${sound.id}');
      
      // Sound loading would be implemented using audioplayers package
      // This would handle 3D positional audio if supported

    } catch (e, stackTrace) {
      AppLogger.e('Error loading AR sound', e, stackTrace);
    }
  }

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

  Future<void> _registerInteraction(ARInteraction interaction) async {
    try {
      AppLogger.d('Registering interaction: ${interaction.id}');
      
      // Register interaction handlers based on trigger type
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
    // Setup tap handling for the target object
    AppLogger.d('Setting up tap interaction for: ${interaction.targetObjectId}');
  }

  void _setupLongPressInteraction(ARInteraction interaction) {
    // Setup long press handling
    AppLogger.d('Setting up long press interaction for: ${interaction.targetObjectId}');
  }

  void _setupProximityInteraction(ARInteraction interaction) {
    // Setup proximity detection
    AppLogger.d('Setting up proximity interaction for: ${interaction.targetObjectId}');
  }

  void _setupTimerInteraction(ARInteraction interaction) {
    // Setup timer-based interaction
    final delay = Duration(
      milliseconds: interaction.parameters['delay'] as int? ?? 0,
    );
    
    Timer(delay, () {
      _executeInteractionEffects(interaction.effects);
    });
  }

  void _executeInteractionEffects(List<ARInteractionEffect> effects) {
    for (final effect in effects) {
      Timer(effect.delay, () {
        _executeEffect(effect);
      });
    }
  }

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

  void _startAnimation(String objectId, ARAnimation animation) {
    AppLogger.d('Starting animation: ${animation.id} on object: $objectId');
    
    // Animation implementation would depend on the AR framework
    // This is a simplified version
    
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      // Update animation frame
      if (timer.tick * 16 >= animation.duration.inMilliseconds) {
        timer.cancel();
        if (animation.isLooping) {
          _startAnimation(objectId, animation);
        }
      }
    });
  }

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

  Future<void> clearScene() async {
    try {
      AppLogger.d('Clearing AR scene');

      // Clear ARCore nodes
      for (final node in _arCoreNodes.values) {
        await _arCoreController?.removeNode(nodeName: node.name);
      }
      _arCoreNodes.clear();

      // Clear ARKit nodes
      if (_arObjectManager != null) {
        for (final nodeId in _arNodes.keys) {
          await _arObjectManager!.removeNode(_arNodes[nodeId]!);
        }
      }
      _arNodes.clear();

      _currentScene = null;
      _broadcastEvent(AREvent.sceneCleared());

    } catch (e, stackTrace) {
      AppLogger.e('Error clearing AR scene', e, stackTrace);
    }
  }

  Future<void> pauseSession() async {
    try {
      if (!_isSessionActive) return;

      AppLogger.i('Pausing AR session');
      
      // Pause AR session
      if (Platform.isAndroid) {
        // ARCore pause handling
      } else if (Platform.isIOS) {
        // _arSessionManager?.pause();
      }

      _broadcastEvent(AREvent.sessionPaused());

    } catch (e, stackTrace) {
      AppLogger.e('Error pausing AR session', e, stackTrace);
    }
  }

  Future<void> resumeSession() async {
    try {
      if (!_isInitialized) return;

      AppLogger.i('Resuming AR session');
      
      // Resume AR session
      if (Platform.isAndroid) {
        // ARCore resume handling
      } else if (Platform.isIOS) {
        // _arSessionManager?.resume();
      }

      _isSessionActive = true;
      _broadcastEvent(AREvent.sessionResumed());

    } catch (e, stackTrace) {
      AppLogger.e('Error resuming AR session', e, stackTrace);
    }
  }

  Future<void> stopSession() async {
    try {
      if (!_isSessionActive) return;

      AppLogger.i('Stopping AR session');

      await clearScene();

      // Stop AR session
      if (Platform.isAndroid) {
        _arCoreController?.dispose();
        _arCoreController = null;
      } else if (Platform.isIOS) {
        _arSessionManager?.dispose();
        // _arObjectManager?.dispose();
        // _arAnchorManager?.dispose();
        _arSessionManager = null;
        _arObjectManager = null;
        _arAnchorManager = null;
      }

      _isSessionActive = false;
      _broadcastEvent(AREvent.sessionStopped());

    } catch (e, stackTrace) {
      AppLogger.e('Error stopping AR session', e, stackTrace);
    }
  }

  void setArCoreController(ArCoreController controller) {
    _arCoreController = controller;
    AppLogger.d('ARCore controller set');
  }

  void _broadcastEvent(AREvent event) {
    _eventController?.add(event);
  }

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