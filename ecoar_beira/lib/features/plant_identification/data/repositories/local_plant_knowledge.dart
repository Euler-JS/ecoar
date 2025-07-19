// lib/features/plant_identification/data/repositories/local_plant_knowledge.dart
import 'package:ecoar_beira/core/utils/logger.dart';

class LocalPlantKnowledge {
  static LocalPlantKnowledge? _instance;
  static LocalPlantKnowledge get instance => _instance ??= LocalPlantKnowledge._();
  LocalPlantKnowledge._();

  // Base de conhecimento de plantas específicas de Moçambique/Beira
  static const Map<String, LocalPlantInfo> _plantDatabase = {
    // Plantas Nativas Icônicas
    'adansonia digitata': LocalPlantInfo(
      localNames: ['Baobá', 'Embondeiro', 'Árvore da Vida'],
      importance: 'Árvore sagrada e símbolo de Moçambique',
      ecologicalRole: 'Armazena até 120.000 litros de água no tronco, fornece abrigo para muitas espécies',
      traditionalUses: [
        'Medicina tradicional (folhas para febre)',
        'Alimentação (frutos ricos em vitamina C)',
        'Fibras (casca para cordas)',
        'Abrigo e sombra em comunidades rurais'
      ],
      conservationStatus: 'Protegida por lei em Moçambique',
      funFacts: [
        'Pode viver mais de 1000 anos',
        'Frutos são 6x mais ricos em vitamina C que laranjas',
        'Tronco pode chegar a 25 metros de circunferência',
        'Flores só abrem à noite'
      ],
      seasonalInfo: 'Flores: Setembro-Dezembro | Frutos: Março-Junho',
      culturalSignificance: 'Considerado sagrado por muitas etnias, local de reuniões comunitárias',
      points: 100,
      rarity: PlantRarity.iconic,
    ),

    'strelitzia nicolai': LocalPlantInfo(
      localNames: ['Ave do Paraíso', 'Estrelitzia'],
      importance: 'Planta ornamental tropical popular em paisagismo urbano',
      ecologicalRole: 'Atrai aves polinizadoras, purifica ar urbano',
      traditionalUses: [
        'Ornamentação de jardins',
        'Paisagismo urbano',
        'Planta de interior (folhas grandes)'
      ],
      conservationStatus: 'Bem adaptada ao clima da Beira',
      funFacts: [
        'Folhas se rasgam naturalmente com vento forte',
        'Pode crescer até 12 metros',
        'Flores parecem cabeça de ave tropical',
        'Originária da África do Sul'
      ],
      seasonalInfo: 'Cresce melhor na estação chuvosa',
      culturalSignificance: 'Símbolo de elegância tropical em jardins modernos',
      points: 40,
      rarity: PlantRarity.common,
    ),

    'eichhornia crassipes': LocalPlantInfo(
      localNames: ['Aguapé', 'Jacinto de Água'],
      importance: 'Planta aquática com papel crucial na purificação de águas',
      ecologicalRole: 'Remove poluentes da água, oxigena corpos hídricos, habitat para peixes',
      traditionalUses: [
        'Purificação natural de água',
        'Controle de erosão em margens',
        'Artesanato (fibras das raízes)',
        'Compostagem (rica em nutrientes)'
      ],
      conservationStatus: 'Nativa da região, importante para ecossistemas aquáticos',
      funFacts: [
        'Pode duplicar população em 12 dias',
        'Raízes filtram metais pesados',
        'Flores roxas são muito ornamentais',
        'Flutuam graças a bolsas de ar nas folhas'
      ],
      seasonalInfo: 'Flores: Outubro-Março (estação quente)',
      culturalSignificance: 'Usada tradicionalmente para limpeza de águas domésticas',
      points: 60,
      rarity: PlantRarity.common,
    ),

    // Árvores Urbanas Comuns
    'delonix regia': LocalPlantInfo(
      localNames: ['Flamboyant', 'Árvore de Fogo', 'Flamboiã'],
      importance: 'Árvore ornamental icônica das cidades tropicais',
      ecologicalRole: 'Sombra urbana, habitat para aves, corredor ecológico',
      traditionalUses: [
        'Sombra em praças e ruas',
        'Ornamentação urbana',
        'Madeira para construção',
        'Medicina tradicional (casca)'
      ],
      conservationStatus: 'Bem estabelecida em ambientes urbanos',
      funFacts: [
        'Flores vermelhas cobrem toda a copa',
        'Perde folhas na estação seca',
        'Sementes são usadas para artesanato',
        'Originária de Madagascar'
      ],
      seasonalInfo: 'Flores: Setembro-Janeiro | Sem folhas: Junho-Setembro',
      culturalSignificance: 'Marco visual das cidades moçambicanas',
      points: 50,
      rarity: PlantRarity.common,
    ),

    'mangifera indica': LocalPlantInfo(
      localNames: ['Mangueira', 'Manga'],
      importance: 'Árvore frutífera fundamental na alimentação local',
      ecologicalRole: 'Atrai fauna frugívora, sombra, sequestro de carbono',
      traditionalUses: [
        'Frutos para alimentação',
        'Sombra natural',
        'Medicina tradicional (folhas)',
        'Madeira para construção'
      ],
      conservationStatus: 'Bem adaptada, presente em toda Moçambique',
      funFacts: [
        'Uma árvore pode produzir 300kg de frutos/ano',
        'Folhas jovens são avermelhadas',
        'Pode viver mais de 100 anos',
        'Flores são pequenas mas muito numerosas'
      ],
      seasonalInfo: 'Flores: Agosto-Outubro | Frutos: Novembro-Fevereiro',
      culturalSignificance: 'Árvore de quintal tradicional, local de convívio',
      points: 45,
      rarity: PlantRarity.common,
    ),

    // Plantas de Jardim/Ornamentais
    'bougainvillea spectabilis': LocalPlantInfo(
      localNames: ['Bougainvillea', 'Três-Marias', 'Primavera'],
      importance: 'Planta ornamental resistente ao clima tropical',
      ecologicalRole: 'Atrai beija-flores e borboletas, cobertura vegetal',
      traditionalUses: [
        'Ornamentação de jardins',
        'Cercas vivas',
        'Cobertura de muros',
        'Decoração urbana'
      ],
      conservationStatus: 'Muito bem adaptada ao clima da Beira',
      funFacts: [
        'Flores verdadeiras são pequenas e brancas',
        'Cores vistosas são brácteas modificadas',
        'Muito resistente à seca',
        'Espinhos ajudam na proteção'
      ],
      seasonalInfo: 'Flores abundantes na estação seca',
      culturalSignificance: 'Símbolo de jardins tropicais bem cuidados',
      points: 30,
      rarity: PlantRarity.common,
    ),

    'cocos nucifera': LocalPlantInfo(
      localNames: ['Coqueiro', 'Côco'],
      importance: 'Palmeira fundamental da zona costeira',
      ecologicalRole: 'Proteção contra erosão costeira, habitat para aves',
      traditionalUses: [
        'Frutos para alimentação e bebida',
        'Óleo de coco',
        'Fibras para artesanato',
        'Folhas para cobertura'
      ],
      conservationStatus: 'Nativo da região costeira, bem conservado',
      funFacts: [
        'Coco pode flutuar por 3000km no oceano',
        'Uma árvore produz 30-75 cocos/ano',
        'Raízes não danificam construções',
        'Pode viver mais de 60 anos'
      ],
      seasonalInfo: 'Produz frutos o ano todo',
      culturalSignificance: 'Símbolo da costa moçambicana, economia familiar',
      points: 70,
      rarity: PlantRarity.common,
    ),
  };

  LocalPlantInfo? getPlantInfo(String scientificName) {
    final key = scientificName.toLowerCase().trim();
    final info = _plantDatabase[key];
    
    if (info != null) {
      AppLogger.d('Found local info for: $scientificName');
    } else {
      AppLogger.d('No local info for: $scientificName');
    }
    
    return info;
  }

  // Fallback educativo quando planta não é identificada
  EducationalContent getGeneralPlantEducation() {
    return EducationalContent(
      title: 'Plantas da Beira',
      description: 'Mesmo sem identificar a espécie, vamos aprender!',
      sections: [
        EducationSection(
          title: '🌳 Biodiversidade Urbana',
          content: 'A Beira possui mais de 200 espécies de plantas em espaços urbanos. '
              'Cada planta tem um papel importante no ecossistema da cidade.',
        ),
        EducationSection(
          title: '🌍 Plantas Nativas vs. Exóticas',
          content: 'Plantas nativas como Baobá e Aguapé estão adaptadas ao nosso clima. '
              'Plantas exóticas podem ser bonitas mas nem sempre beneficiam nossa fauna local.',
        ),
        EducationSection(
          title: '💧 Importância para Beira',
          content: 'Plantas urbanas purificam o ar, controlam temperatura, '
              'previnem erosão e fornecem habitat para aves e insetos.',
        ),
        EducationSection(
          title: '🏃‍♂️ Como Ajudar',
          content: 'Não arranque plantas nativas, regue árvores jovens em época seca, '
              'e plante espécies locais no seu quintal.',
        ),
      ],
      points: 25,
    );
  }

  List<LocalPlantInfo> getCommonLocalPlants() {
    return _plantDatabase.values
        .where((plant) => plant.rarity == PlantRarity.common)
        .toList();
  }

  List<LocalPlantInfo> getIconicLocalPlants() {
    return _plantDatabase.values
        .where((plant) => plant.rarity == PlantRarity.iconic)
        .toList();
  }

  List<String> getAllScientificNames() {
    return _plantDatabase.keys.toList();
  }
}

class LocalPlantInfo {
  final List<String> localNames;
  final String importance;
  final String ecologicalRole;
  final List<String> traditionalUses;
  final String conservationStatus;
  final List<String> funFacts;
  final String seasonalInfo;
  final String culturalSignificance;
  final int points;
  final PlantRarity rarity;

  const LocalPlantInfo({
    required this.localNames,
    required this.importance,
    required this.ecologicalRole,
    required this.traditionalUses,
    required this.conservationStatus,
    required this.funFacts,
    required this.seasonalInfo,
    required this.culturalSignificance,
    required this.points,
    required this.rarity,
  });

  String get primaryName => localNames.isNotEmpty ? localNames.first : 'Planta não identificada';
}

enum PlantRarity {
  common,
  uncommon,
  rare,
  iconic,
}

class EducationalContent {
  final String title;
  final String description;
  final List<EducationSection> sections;
  final int points;

  EducationalContent({
    required this.title,
    required this.description,
    required this.sections,
    required this.points,
  });
}

class EducationSection {
  final String title;
  final String content;

  EducationSection({
    required this.title,
    required this.content,
  });
}