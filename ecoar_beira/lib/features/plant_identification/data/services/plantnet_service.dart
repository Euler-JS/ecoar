// lib/features/plant_identification/data/services/plantnet_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ecoar_beira/core/utils/logger.dart';

class PlantNetService {
  static const String baseUrl = 'https://my-api.plantnet.org/v1';
  static const String project = 'weurope'; // ou 'world' para cobertura global
  
  final Dio _dio;
  final String apiKey;

  PlantNetService({required this.apiKey}) : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Não logar imagens
      responseBody: true,
      logPrint: (obj) => AppLogger.d('PlantNet API: $obj'),
    ));
  }

  Future<PlantIdentificationResult> identifyPlant({
    required File imageFile,
    required PlantOrgan organ,
    List<PlantModifier> modifiers = const [],
  }) async {
    try {
      AppLogger.i('Identifying plant with PlantNet API...');
      
      // Preparar FormData
      final formData = FormData.fromMap({
        'images': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'plant_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'organs': organ.value,
        'modifiers': modifiers.map((m) => m.value).join(','),
        'nb-results': 5, // Top 5 resultados
        'lang': 'pt', // Português
        'type': 'kt', // Key Tree - melhor para plantas urbanas
      });

      final response = await _dio.post(
        '$baseUrl/identify/$project',
        data: formData,
        queryParameters: {'api-key': apiKey},
      );

      if (response.statusCode == 200) {
        return PlantIdentificationResult.fromJson(response.data);
      } else {
        throw PlantNetException('API returned ${response.statusCode}');
      }

    } on DioException catch (e) {
      AppLogger.e('PlantNet API error', e);
      if (e.type == DioExceptionType.connectionTimeout) {
        throw PlantNetException('Conexão muito lenta. Tente novamente.');
      } else if (e.response?.statusCode == 404) {
        throw PlantNetException('Planta não encontrada na base de dados.');
      } else if (e.response?.statusCode == 429) {
        throw PlantNetException('Muitas tentativas. Aguarde um momento.');
      } else {
        throw PlantNetException('Erro de conectividade: ${e.message}');
      }
    } catch (e) {
      AppLogger.e('Unexpected error in plant identification', e);
      throw PlantNetException('Erro inesperado: $e');
    }
  }

  Future<List<PlantSpecies>> getSpeciesInfo(List<String> scientificNames) async {
    // Implementar busca de informações detalhadas sobre espécies
    // Por enquanto retorna dados mockados
    return scientificNames.map((name) => PlantSpecies(
      scientificName: name,
      commonNames: ['Nome comum não disponível'],
      family: 'Família não identificada',
      description: 'Informações detalhadas em breve.',
      scientificNameWithoutAuthor: '',
      scientificNameAuthorship: '',
      genus: '',
    )).toList();
  }
}

class PlantIdentificationResult {
  final String query;
  final String language;
  final int nbResults;
  final List<PlantMatch> results;
  final bool remainingIdentificationRequests;

  PlantIdentificationResult({
    required this.query,
    required this.language,
    required this.nbResults,
    required this.results,
    required this.remainingIdentificationRequests,
  });

  factory PlantIdentificationResult.fromJson(Map<String, dynamic> json) {
    return PlantIdentificationResult(
      query: json['query']?.toString() ?? '',
      language: json['language']?.toString() ?? 'pt',
      nbResults: json['nbResults'] ?? 0,
      results: (json['results'] as List? ?? [])
          .map((r) => PlantMatch.fromJson(r))
          .toList(),
      remainingIdentificationRequests: json['remainingIdentificationRequests'] ?? true,
    );
  }

  PlantMatch? get bestMatch {
    if (results.isEmpty) return null;
    return results.first;
  }

  bool get hasConfidentMatch {
    return bestMatch != null && bestMatch!.score > 0.3;
  }
}

class PlantMatch {
  final double score;
  final PlantSpecies species;
  final List<PlantImage> images;

  PlantMatch({
    required this.score,
    required this.species,
    required this.images,
  });

  factory PlantMatch.fromJson(Map<String, dynamic> json) {
    return PlantMatch(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      species: PlantSpecies.fromJson(json['species'] ?? {}),
      images: (json['images'] as List? ?? [])
          .map((i) => PlantImage.fromJson(i))
          .toList(),
    );
  }

  String get confidenceText {
    if (score > 0.7) return 'Alta confiança';
    if (score > 0.4) return 'Média confiança';
    if (score > 0.2) return 'Baixa confiança';
    return 'Muito incerto';
  }

  int get confidencePercent => (score * 100).round();
}

class PlantSpecies {
  final String scientificNameWithoutAuthor;
  final String scientificNameAuthorship;
  final String scientificName;
  final String genus;
  final String family;
  final List<String> commonNames;
  final String? description;

  PlantSpecies({
    required this.scientificNameWithoutAuthor,
    required this.scientificNameAuthorship,
    required this.scientificName,
    required this.genus,
    required this.family,
    required this.commonNames,
    this.description,
  });

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      scientificNameWithoutAuthor: json['scientificNameWithoutAuthor']?.toString() ?? '',
      scientificNameAuthorship: json['scientificNameAuthorship']?.toString() ?? '',
      scientificName: json['scientificNameWithoutAuthor']?.toString() ?? '',
      genus: json['genus']?.toString() ?? '',
      family: json['family']?.toString() ?? '',
      commonNames: (json['commonNames'] as List? ?? [])
          .map((name) => name.toString())
          .toList(),
    );
  }

  String get displayName {
    if (commonNames.isNotEmpty) {
      return commonNames.first;
    }
    return scientificNameWithoutAuthor;
  }

  String get fullScientificName {
    return '$scientificNameWithoutAuthor $scientificNameAuthorship'.trim();
  }
}

class PlantImage {
  final String url;
  final String organ;
  final String author;
  final String license;

  PlantImage({
    required this.url,
    required this.organ,
    required this.author,
    required this.license,
  });

  factory PlantImage.fromJson(Map<String, dynamic> json) {
    return PlantImage(
      url: json['url']?.toString() ?? '',
      organ: json['organ']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      license: json['license']?.toString() ?? '',
    );
  }
}

enum PlantOrgan {
  leaf('leaf'),
  flower('flower'),
  fruit('fruit'),
  bark('bark'),
  habit('habit'),
  other('other');

  const PlantOrgan(this.value);
  final String value;

  static PlantOrgan fromString(String value) {
    return PlantOrgan.values.firstWhere(
      (organ) => organ.value == value,
      orElse: () => PlantOrgan.other,
    );
  }

  String get displayName {
    switch (this) {
      case PlantOrgan.leaf:
        return 'Folha';
      case PlantOrgan.flower:
        return 'Flor';
      case PlantOrgan.fruit:
        return 'Fruto';
      case PlantOrgan.bark:
        return 'Casca';
      case PlantOrgan.habit:
        return 'Planta Inteira';
      case PlantOrgan.other:
        return 'Outro';
    }
  }
}

enum PlantModifier {
  planted('planted'),
  cultivated('cultivated'),
  garden('garden');

  const PlantModifier(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case PlantModifier.planted:
        return 'Plantada';
      case PlantModifier.cultivated:
        return 'Cultivada';
      case PlantModifier.garden:
        return 'Jardim';
    }
  }
}

class PlantNetException implements Exception {
  final String message;
  PlantNetException(this.message);

  @override
  String toString() => 'PlantNetException: $message';
}