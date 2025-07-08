import 'dart:convert';
import 'package:ecoar_beira/core/models/ar_object_model.dart';
import 'package:ecoar_beira/core/models/ar_scene_model.dart';
import 'package:ecoar_beira/core/utils/logger.dart';
import 'package:flutter/services.dart';

class ARSceneRepository {
  static final Map<String, ARSceneModel> _cachedScenes = {};
  
  Future<ARSceneModel?> getSceneByMarkerId(String markerId) async {
    try {
      // Check cache first
      if (_cachedScenes.containsKey(markerId)) {
        return _cachedScenes[markerId];
      }

      // Load from assets or API
      final scene = await _loadSceneFromAssets(markerId);
      if (scene != null) {
        _cachedScenes[markerId] = scene;
      }

      return scene;
    } catch (e, stackTrace) {
      AppLogger.e('Error loading scene for marker: $markerId', e, stackTrace);
      return null;
    }
  }

  Future<List<ARSceneModel>> getAllScenes() async {
    try {
      final sceneIds = _getAvailableSceneIds();
      final scenes = <ARSceneModel>[];

      for (final sceneId in sceneIds) {
        final scene = await getSceneByMarkerId(sceneId);
        if (scene != null) {
          scenes.add(scene);
        }
      }

      return scenes;
    } catch (e, stackTrace) {
      AppLogger.e('Error loading all scenes', e, stackTrace);
      return [];
    }
  }

  Future<ARSceneModel?> _loadSceneFromAssets(String markerId) async {
    try {
      // Try to load from JSON file
      final jsonString = await rootBundle.loadString('assets/ar_scenes/$markerId.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return ARSceneModel.fromJson(jsonData);
    } catch (e) {
      // If file doesn't exist, create mock scene
      AppLogger.w('Scene file not found for $markerId, creating mock scene');
      return _createMockScene(markerId);
    }
  }

  List<String> _getAvailableSceneIds() {
    return [
      'bacia1_001',
      'bacia1_002',
      'bacia1_003',
      'bacia2_001',
      'bacia2_002',
      'bacia2_003',
      'bacia3_001',
      'bacia3_002',
      'bacia3_003',
    ];
  }

  ARSceneModel _createMockScene(String markerId) {
    // Create different scenes based on marker ID
    if (markerId.startsWith('bacia1')) {
      return _createBiodiversityScene(markerId);
    } else if (markerId.startsWith('bacia2')) {
      return _createWaterResourcesScene(markerId);
    } else if (markerId.startsWith('bacia3')) {
      return _createUrbanFarmingScene(markerId);
    } else {
      return _createDefaultScene(markerId);
    }
  }

  ARSceneModel _createBiodiversityScene(String markerId) {
    return ARSceneModel(
      id: 'scene_$markerId',
      name: 'Biodiversidade - ${markerId.toUpperCase()}',
      description: 'Explore a rica biodiversidade da Bacia 1 com realidade aumentada',
      markerId: markerId,
      objects: [
        // Baobá Tree
        ARObjectModel(
          id: 'baoba_tree_001',
          name: 'Baobá Gigante',
          description: 'Árvore icônica de Moçambique, pode viver mais de 1000 anos',
          type: ARObjectType.tree,
          modelPath: 'assets/ar_models/baoba_tree.glb',
          texturePath: 'assets/ar_models/textures/baoba_bark.jpg',
          position: const ARPosition(x: 0.0, y: 0.0, z: -1.5),
          rotation: const ARRotation(x: 0.0, y: 0.0, z: 0.0),
          scale: const ARScale(x: 1.0, y: 1.0, z: 1.0),
          animations: [
            ARAnimation(
              id: 'sway_animation',
              type: ARAnimationType.rotate,
              duration: const Duration(seconds: 4),
              isLooping: true,
              startRotation: const ARRotation(x: 0.0, y: -5.0, z: 0.0),
              endRotation: const ARRotation(x: 0.0, y: 5.0, z: 0.0),
            ),
          ],
          interactionData: {
            'info': 'O Baobá é conhecido como a "Árvore da Vida" e é sagrado para muitas culturas africanas.',
            'facts': [
              'Pode armazenar até 120.000 litros de água no tronco',
              'Frutos são ricos em vitamina C',
              'Folhas são usadas medicinalmente',
            ],
          },
          isInteractable: true,
          points: 75,
        ),

        // Native Bird
        ARObjectModel(
          id: 'bird_001',
          name: 'Bem-te-vi Moçambicano',
          description: 'Ave nativa com canto característico',
          type: ARObjectType.animal,
          modelPath: 'assets/ar_models/bird_bem_te_vi.glb',
          texturePath: 'assets/ar_models/textures/bird_yellow.jpg',
          position: const ARPosition(x: 1.0, y: 1.5, z: -1.0),
          rotation: const ARRotation(x: 0.0, y: 45.0, z: 0.0),
          scale: const ARScale(x: 0.5, y: 0.5, z: 0.5),
          animations: [
            ARAnimation(
              id: 'wing_flap',
              type: ARAnimationType.custom,
              duration: const Duration(milliseconds: 500),
              isLooping: true,
            ),
            ARAnimation(
              id: 'fly_around',
              type: ARAnimationType.move,
              duration: const Duration(seconds: 8),
              isLooping: true,
              startPosition: const ARPosition(x: 1.0, y: 1.5, z: -1.0),
              endPosition: const ARPosition(x: -1.0, y: 1.8, z: -0.5),
            ),
          ],
          interactionData: {
            'sound': 'bird_bem_te_vi_song.mp3',
            'info': 'Esta ave é comum nos parques urbanos e tem um canto muito melodioso.',
          },
          isInteractable: true,
          points: 50,
        ),

        // Native Plant
        ARObjectModel(
          id: 'plant_001',
          name: 'Strelitzia Nicolai',
          description: 'Planta tropical nativa com folhas grandes',
          type: ARObjectType.plant,
          modelPath: 'assets/ar_models/strelitzia.glb',
          texturePath: 'assets/ar_models/textures/strelitzia_leaves.jpg',
          position: const ARPosition(x: -0.8, y: 0.0, z: -1.2),
          rotation: const ARRotation(x: 0.0, y: 20.0, z: 0.0),
          scale: const ARScale(x: 0.8, y: 0.8, z: 0.8),
          animations: [
            ARAnimation(
              id: 'leaf_rustle',
              type: ARAnimationType.scale,
              duration: const Duration(seconds: 3),
              isLooping: true,
              startScale: const ARScale(x: 0.8, y: 0.8, z: 0.8),
              endScale: const ARScale(x: 0.85, y: 0.85, z: 0.85),
            ),
          ],
          interactionData: {
            'info': 'Também conhecida como Ave do Paraíso, produz flores espetaculares.',
            'care_tips': [
              'Prefere luz indireta brilhante',
              'Rega quando o solo estiver seco',
              'Limpe as folhas regularmente',
            ],
          },
          isInteractable: true,
          points: 40,
        ),

        // Information Panel
        ARObjectModel(
          id: 'info_panel_001',
          name: 'Painel Educativo',
          description: 'Informações sobre a biodiversidade local',
          type: ARObjectType.information,
          modelPath: 'assets/ar_models/info_panel.glb',
          texturePath: 'assets/ar_models/textures/info_panel.jpg',
          position: const ARPosition(x: 0.0, y: 0.5, z: -2.0),
          rotation: const ARRotation(x: 0.0, y: 0.0, z: 0.0),
          scale: const ARScale(x: 1.2, y: 1.2, z: 1.2),
          animations: [],
          interactionData: {
            'title': 'Biodiversidade da Bacia 1',
            'content': 'A Bacia 1 abriga mais de 150 espécies de plantas e 45 espécies de aves...',
            'quiz_id': 'biodiversity_quiz_001',
          },
          isInteractable: true,
          points: 25,
        ),
      ],
      environment: AREnvironment(
        skyboxPath: 'assets/ar_models/skyboxes/forest_day.hdr',
        backgroundColor: const Color(0xFF87CEEB),
        fogDensity: 0.01,
        fogColor: const Color(0xFFE6F3FF),
        particleSystems: [
          ARParticleSystem(
            id: 'pollen_particles',
            position: const ARPosition(x: 0.0, y: 2.0, z: 0.0),
            maxParticles: 50,
            emissionRate: 5.0,
            lifetime: const Duration(seconds: 4),
            velocity: const ARPosition(x: 0.1, y: -0.2, z: 0.1),
            color: const Color(0xFFFFD700),
            size: 0.02,
          ),
        ],
      ),
      interactions: [
        ARInteraction(
          id: 'tree_tap_interaction',
          type: ARInteractionType.tap,
          targetObjectId: 'baoba_tree_001',
          trigger: ARInteractionTrigger.onTap,
          parameters: {'haptic': true},
          effects: [
            ARInteractionEffect(
              id: 'show_tree_info',
              type: AREffectType.showInformation,
              parameters: {
                'title': 'Baobá - Árvore da Vida',
                'message': 'Esta majestosa árvore pode viver mais de 1000 anos!',
              },
              delay: Duration.zero,
              duration: const Duration(seconds: 3),
            ),
            ARInteractionEffect(
              id: 'add_tree_points',
              type: AREffectType.addPoints,
              parameters: {'points': 75},
              delay: const Duration(milliseconds: 500),
              duration: Duration.zero,
            ),
          ],
        ),
        ARInteraction(
          id: 'bird_proximity_interaction',
          type: ARInteractionType.proximity,
          targetObjectId: 'bird_001',
          trigger: ARInteractionTrigger.onApproach,
          parameters: {'distance': 0.5},
          effects: [
            ARInteractionEffect(
              id: 'play_bird_sound',
              type: AREffectType.playSound,
              parameters: {'soundId': 'bird_bem_te_vi_song'},
              delay: Duration.zero,
              duration: const Duration(seconds: 3),
            ),
          ],
        ),
      ],
      lighting: ARLighting(
        ambientColor: const Color(0xFFFFFFFF),
        ambientIntensity: 0.6,
        lights: [
          ARLight(
            id: 'sun_light',
            type: ARLightType.directional,
            position: const ARPosition(x: 2.0, y: 3.0, z: 1.0),
            rotation: const ARRotation(x: -45.0, y: 30.0, z: 0.0),
            color: const Color(0xFFFFF8DC),
            intensity: 1.0,
            range: 10.0,
          ),
        ],
      ),
      sound: const ARSound(
        id: 'forest_ambience',
        audioPath: 'assets/audio/forest_ambience.mp3',
        isLooping: true,
        volume: 0.3,
        is3D: false,
      ),
      maxDuration: const Duration(minutes: 10),
      metadata: {
        'category': 'biodiversidade',
        'difficulty': 'beginner',
        'tags': ['natureza', 'plantas', 'animais', 'ecossistema'],
        'version': '1.0',
      },
    );
  }

  ARSceneModel _createWaterResourcesScene(String markerId) {
    return ARSceneModel(
      id: 'scene_$markerId',
      name: 'Recursos Hídricos - ${markerId.toUpperCase()}',
      description: 'Descubra a importância da água através de experiências interativas',
      markerId: markerId,
      objects: [
        // Water Cycle Visualization
        ARObjectModel(
          id: 'water_cycle_001',
          name: 'Ciclo da Água',
          description: 'Visualização 3D do ciclo hidrológico',
          type: ARObjectType.interactive,
          modelPath: 'assets/ar_models/water_cycle.glb',
          texturePath: 'assets/ar_models/textures/water_blue.jpg',
          position: const ARPosition(x: 0.0, y: 1.0, z: -1.5),
          rotation: const ARRotation(x: 0.0, y: 0.0, z: 0.0),
          scale: const ARScale(x: 1.5, y: 1.5, z: 1.5),
          animations: [
            ARAnimation(
              id: 'water_flow',
              type: ARAnimationType.custom,
              duration: const Duration(seconds: 8),
              isLooping: true,
            ),
            ARAnimation(
              id: 'cloud_movement',
              type: ARAnimationType.move,
              duration: const Duration(seconds: 6),
              isLooping: true,
              startPosition: const ARPosition(x: -1.0, y: 2.0, z: -1.5),
              endPosition: const ARPosition(x: 1.0, y: 2.0, z: -1.5),
            ),
          ],
          interactionData: {
            'stages': ['evaporação', 'condensação', 'precipitação', 'infiltração'],
            'info': 'O ciclo da água é essencial para toda vida na Terra.',
          },
          isInteractable: true,
          points: 100,
        ),

        // Water Quality Tester
        ARObjectModel(
          id: 'water_tester_001',
          name: 'Testador de Qualidade',
          description: 'Instrumento virtual para testar qualidade da água',
          type: ARObjectType.interactive,
          modelPath: 'assets/ar_models/water_tester.glb',
          texturePath: 'assets/ar_models/textures/device_metal.jpg',
          position: const ARPosition(x: 1.0, y: 0.3, z: -1.0),
          rotation: const ARRotation(x: 0.0, y: -30.0, z: 0.0),
          scale: const ARScale(x: 0.8, y: 0.8, z: 0.8),
          animations: [
            ARAnimation(
              id: 'screen_glow',
              type: ARAnimationType.fade,
              duration: const Duration(seconds: 2),
              isLooping: true,
            ),
          ],
          interactionData: {
            'measurements': ['pH', 'oxigênio dissolvido', 'turbidez', 'temperatura'],
            'mini_game': 'water_quality_test',
          },
          isInteractable: true,
          points: 80,
        ),

        // Aquatic Plant
        ARObjectModel(
          id: 'aquatic_plant_001',
          name: 'Aguapé',
          description: 'Planta aquática que ajuda na purificação da água',
          type: ARObjectType.plant,
          modelPath: 'assets/ar_models/water_hyacinth.glb',
          texturePath: 'assets/ar_models/textures/aquatic_plant.jpg',
          position: const ARPosition(x: -1.2, y: 0.0, z: -1.0),
          rotation: const ARRotation(x: 0.0, y: 45.0, z: 0.0),
          scale: const ARScale(x: 1.0, y: 1.0, z: 1.0),
          animations: [
            ARAnimation(
              id: 'float_motion',
              type: ARAnimationType.move,
              duration: const Duration(seconds: 4),
              isLooping: true,
              startPosition: const ARPosition(x: -1.2, y: 0.0, z: -1.0),
              endPosition: const ARPosition(x: -1.2, y: 0.1, z: -1.0),
            ),
          ],
          interactionData: {
            'function': 'filtração natural',
            'benefits': ['remove poluentes', 'oxigena a água', 'habitat para peixes'],
          },
          isInteractable: true,
          points: 60,
        ),
      ],
      environment: AREnvironment(
        skyboxPath: 'assets/ar_models/skyboxes/lake_day.hdr',
        backgroundColor: const Color(0xFF87CEEB),
        fogDensity: 0.005,
        fogColor: const Color(0xFFE6F7FF),
        particleSystems: [
          ARParticleSystem(
            id: 'water_droplets',
            position: const ARPosition(x: 0.0, y: 2.5, z: 0.0),
            maxParticles: 30,
            emissionRate: 3.0,
            lifetime: const Duration(seconds: 6),
            velocity: const ARPosition(x: 0.0, y: -0.3, z: 0.0),
            color: const Color(0xFF00BFFF),
            size: 0.03,
          ),
        ],
      ),
      interactions: [
        ARInteraction(
          id: 'water_cycle_tap',
          type: ARInteractionType.tap,
          targetObjectId: 'water_cycle_001',
          trigger: ARInteractionTrigger.onTap,
          parameters: {},
          effects: [
            ARInteractionEffect(
              id: 'start_cycle_animation',
              type: AREffectType.playAnimation,
              parameters: {'animationId': 'water_flow'},
              delay: Duration.zero,
              duration: const Duration(seconds: 8),
            ),
            ARInteractionEffect(
              id: 'cycle_points',
              type: AREffectType.addPoints,
              parameters: {'points': 100},
              delay: const Duration(seconds: 1),
              duration: Duration.zero,
            ),
          ],
        ),
      ],
      lighting: ARLighting(
        ambientColor: const Color(0xFFE6F7FF),
        ambientIntensity: 0.7,
        lights: [
          ARLight(
            id: 'water_reflection',
            type: ARLightType.point,
            position: const ARPosition(x: 0.0, y: 0.5, z: -1.0),
            rotation: const ARRotation(x: 0.0, y: 0.0, z: 0.0),
            color: const Color(0xFF00BFFF),
            intensity: 0.8,
            range: 3.0,
          ),
        ],
      ),
      sound: const ARSound(
        id: 'water_sounds',
        audioPath: 'assets/audio/water_ambience.mp3',
        isLooping: true,
        volume: 0.4,
        is3D: false,
      ),
      maxDuration: const Duration(minutes: 8),
      metadata: {
        'category': 'recursos_hidricos',
        'difficulty': 'intermediate',
        'tags': ['água', 'ciclo', 'conservação', 'qualidade'],
        'version': '1.0',
      },
    );
  }

  ARSceneModel _createUrbanFarmingScene(String markerId) {
    return ARSceneModel(
      id: 'scene_$markerId',
      name: 'Agricultura Urbana - ${markerId.toUpperCase()}',
      description: 'Aprenda sobre agricultura sustentável na cidade',
      markerId: markerId,
      objects: [
        // Vertical Garden
        ARObjectModel(
          id: 'vertical_garden_001',
          name: 'Horta Vertical',
          description: 'Sistema de cultivo vertical para espaços pequenos',
          type: ARObjectType.building,
          modelPath: 'assets/ar_models/vertical_garden.glb',
          texturePath: 'assets/ar_models/textures/garden_structure.jpg',
          position: const ARPosition(x: 0.0, y: 0.0, z: -1.5),
          rotation: const ARRotation(x: 0.0, y: 0.0, z: 0.0),
          scale: const ARScale(x: 1.2, y: 1.2, z: 1.2),
          animations: [
            ARAnimation(
              id: 'plant_growth',
              type: ARAnimationType.scale,
              duration: const Duration(seconds: 5),
              isLooping: false,
              startScale: const ARScale(x: 0.8, y: 0.8, z: 0.8),
              endScale: const ARScale(x: 1.2, y: 1.2, z: 1.2),
            ),
          ],
          interactionData: {
            'benefits': ['economiza espaço', 'fácil manutenção', 'produção constante'],
            'plants': ['alface', 'rúcula', 'manjericão', 'tomate cereja'],
          },
          isInteractable: true,
          points: 90,
        ),

        // Compost Bin
        ARObjectModel(
          id: 'compost_bin_001',
          name: 'Compostor',
          description: 'Sistema de compostagem para resíduos orgânicos',
          type: ARObjectType.interactive,
          modelPath: 'assets/ar_models/compost_bin.glb',
          texturePath: 'assets/ar_models/textures/compost_wood.jpg',
          position: const ARPosition(x: 1.5, y: 0.0, z: -1.0),
          rotation: const ARRotation(x: 0.0, y: -45.0, z: 0.0),
          scale: const ARScale(x: 0.9, y: 0.9, z: 0.9),
          animations: [
            ARAnimation(
              id: 'decomposition_process',
              type: ARAnimationType.custom,
              duration: const Duration(seconds: 6),
              isLooping: true,
            ),
          ],
          interactionData: {
            'process': 'transformação de resíduos orgânicos em adubo',
            'timeline': '3-6 meses para compostagem completa',
            'mini_game': 'compost_sorting',
          },
          isInteractable: true,
          points: 70,
        ),

        // Vegetable Plants
        ARObjectModel(
          id: 'vegetable_plants_001',
          name: 'Horta de Vegetais',
          description: 'Variedade de vegetais cultivados organicamente',
          type: ARObjectType.plant,
          modelPath: 'assets/ar_models/vegetable_garden.glb',
          texturePath: 'assets/ar_models/textures/fresh_vegetables.jpg',
          position: const ARPosition(x: -1.0, y: 0.0, z: -1.2),
          rotation: const ARRotation(x: 0.0, y: 30.0, z: 0.0),
          scale: const ARScale(x: 1.0, y: 1.0, z: 1.0),
          animations: [
            ARAnimation(
              id: 'growing_stages',
              type: ARAnimationType.scale,
              duration: const Duration(seconds: 8),
              isLooping: true,
              startScale: const ARScale(x: 0.5, y: 0.5, z: 0.5),
              endScale: const ARScale(x: 1.2, y: 1.2, z: 1.2),
            ),
          ],
          interactionData: {
            'varieties': ['tomate', 'pimentão', 'couve', 'cenoura'],
            'care_tips': ['rega regular', 'sol direto', 'adubo orgânico'],
          },
          isInteractable: true,
          points: 50,
        ),
      ],
      environment: AREnvironment(
        skyboxPath: 'assets/ar_models/skyboxes/garden_day.hdr',
        backgroundColor: const Color(0xFF90EE90),
        fogDensity: 0.003,
        fogColor: const Color(0xFFF0FFF0),
        particleSystems: [
          ARParticleSystem(
            id: 'soil_particles',
            position: const ARPosition(x: 0.0, y: 0.5, z: 0.0),
            maxParticles: 20,
            emissionRate: 2.0,
            lifetime: const Duration(seconds: 3),
            velocity: const ARPosition(x: 0.05, y: 0.1, z: 0.05),
            color: const Color(0xFF8B4513),
            size: 0.01,
          ),
        ],
      ),
      interactions: [
        ARInteraction(
          id: 'garden_interaction',
          type: ARInteractionType.tap,
          targetObjectId: 'vertical_garden_001',
          trigger: ARInteractionTrigger.onTap,
          parameters: {},
          effects: [
            ARInteractionEffect(
              id: 'show_growth_animation',
              type: AREffectType.playAnimation,
              parameters: {'animationId': 'plant_growth'},
              delay: Duration.zero,
              duration: const Duration(seconds: 5),
            ),
            ARInteractionEffect(
              id: 'garden_points',
              type: AREffectType.addPoints,
              parameters: {'points': 90},
              delay: const Duration(seconds: 2),
              duration: Duration.zero,
            ),
          ],
        ),
      ],
      lighting: ARLighting(
        ambientColor: const Color(0xFFF0FFF0),
        ambientIntensity: 0.8,
        lights: [
          ARLight(
            id: 'garden_sun',
            type: ARLightType.directional,
            position: const ARPosition(x: 1.0, y: 3.0, z: 0.0),
            rotation: const ARRotation(x: -60.0, y: 0.0, z: 0.0),
            color: const Color(0xFFFFFFE0),
            intensity: 1.2,
            range: 8.0,
          ),
        ],
      ),
      sound: const ARSound(
        id: 'garden_ambience',
        audioPath: 'assets/audio/garden_sounds.mp3',
        isLooping: true,
        volume: 0.2,
        is3D: false,
      ),
      maxDuration: const Duration(minutes: 12),
      metadata: {
        'category': 'agricultura_urbana',
        'difficulty': 'beginner',
        'tags': ['sustentabilidade', 'compostagem', 'cultivo', 'orgânico'],
        'version': '1.0',
      },
    );
  }

  ARSceneModel _createDefaultScene(String markerId) {
    return ARSceneModel(
      id: 'scene_$markerId',
      name: 'Experiência AR - $markerId',
      description: 'Experiência básica de realidade aumentada',
      markerId: markerId,
      objects: [
        ARObjectModel(
          id: 'default_object_001',
          name: 'Objeto Interativo',
          description: 'Objeto 3D básico para demonstração',
          type: ARObjectType.interactive,
          modelPath: 'assets/ar_models/sphere.glb',
          texturePath: 'assets/ar_models/textures/default.jpg',
          position: const ARPosition(x: 0.0, y: 0.5, z: -1.0),
          rotation: const ARRotation(x: 0.0, y: 0.0, z: 0.0),
          scale: const ARScale(x: 0.5, y: 0.5, z: 0.5),
          animations: [
            ARAnimation(
              id: 'rotation',
              type: ARAnimationType.rotate,
              duration: const Duration(seconds: 4),
              isLooping: true,
              startRotation: const ARRotation(x: 0.0, y: 0.0, z: 0.0),
              endRotation: const ARRotation(x: 0.0, y: 360.0, z: 0.0),
            ),
          ],
          interactionData: {
            'info': 'Este é um objeto AR básico para demonstração.',
          },
          isInteractable: true,
          points: 25,
        ),
      ],
      environment: AREnvironment(
        skyboxPath: 'assets/ar_models/skyboxes/default.hdr',
        backgroundColor: const Color(0xFF87CEEB),
        fogDensity: 0.01,
        fogColor: const Color(0xFFFFFFFF),
        particleSystems: [],
      ),
      interactions: [
        ARInteraction(
          id: 'default_tap',
          type: ARInteractionType.tap,
          targetObjectId: 'default_object_001',
          trigger: ARInteractionTrigger.onTap,
          parameters: {},
          effects: [
            ARInteractionEffect(
              id: 'default_points',
              type: AREffectType.addPoints,
              parameters: {'points': 25},
              delay: Duration.zero,
              duration: Duration.zero,
            ),
          ],
        ),
      ],
      lighting: ARLighting(
        ambientColor: const Color(0xFFFFFFFF),
        ambientIntensity: 0.5,
        lights: [],
      ),
      maxDuration: const Duration(minutes: 5),
      metadata: {
        'category': 'default',
        'difficulty': 'beginner',
        'tags': ['demo', 'básico'],
        'version': '1.0',
      },
    );
  }

  Future<void> preloadScenes() async {
    try {
      AppLogger.i('Preloading AR scenes...');
      
      final sceneIds = _getAvailableSceneIds();
      for (final sceneId in sceneIds.take(3)) { // Preload first 3 scenes
        await getSceneByMarkerId(sceneId);
      }
      
      AppLogger.i('AR scenes preloaded successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error preloading AR scenes', e, stackTrace);
    }
  }

  void clearCache() {
    _cachedScenes.clear();
    AppLogger.d('AR scene cache cleared');
  }
}
