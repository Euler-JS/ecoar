// lib/features/plant_identification/data/services/plantnet_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ecoar_beira/core/utils/logger.dart';

class PlantNetService {
  static const String baseUrl = 'https://my-api.plantnet.org/v2';
  static const String project = 'all'; // ou 'weurope', 'canada', etc.

  final Dio _dio;
  final String apiKey;

  PlantNetService({
    required this.apiKey,
  }) : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 60); // Aumentado para upload
    
    // ✅ Remover headers manuais - Dio configura automaticamente para multipart
    _dio.options.headers = {
      'Accept': 'application/json',
    };
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // Não logar imagens
      responseBody: true,
      requestHeader: true,
      logPrint: (obj) => AppLogger.d('PlantNet API: $obj'),
    ));
  }

  Future<PlantIdentificationResult> identifyPlant({
    required File imageFile,
    required PlantOrgan organ,
  }) async {
    try {
      AppLogger.i('Identifying plant with PlantNet API...');
      
      // ✅ Validações
      if (!await imageFile.exists()) {
        throw PlantNetException('Arquivo de imagem não encontrado');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw PlantNetException('Imagem muito grande. Máximo 5MB.');
      }

      // ✅ CORREÇÃO PRINCIPAL: FormData com formato correto
      final formData = FormData();
      
      // Adicionar imagem
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(
          imageFile.path,
          filename: 'plant_image.jpg',
        ),
      ));
      
      // ✅ CORREÇÃO: organs como lista (mesmo com um só item)
      formData.fields.add(MapEntry('organs', organ.value));
      
      // ✅ CORREÇÃO: Modifiers não são suportados pela API PlantNet v2
      // Removido o parâmetro modifiers que causava erro 400

      // URL da API
      const url = '$baseUrl/identify/$project';
      AppLogger.d('Request URL: $url');
      AppLogger.d('API Key (primeiros 8 chars): ${apiKey.substring(0, 8)}...');

      final response = await _dio.post(
        url,
        data: formData,
        queryParameters: {
          'api-key': apiKey,  // ✅ API Key como query parameter
          'include-related-images': false, // Opcional: imagens similares
          'no-reject': false, // Opcional: não rejeitar identificações baixas
          'lang': 'pt', // Opcional: idioma dos nomes comuns
        },
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      AppLogger.d('Response status: ${response.statusCode}');
      AppLogger.d('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        return PlantIdentificationResult.fromJson(response.data);
      } else if (response.statusCode == 401) {
        throw PlantNetException('API key inválida. Verifique sua configuração.');
      } else if (response.statusCode == 404) {
        AppLogger.e('404 Error - URL: $url, Project: $project');
        throw PlantNetException('Serviço temporariamente indisponível. Projeto "$project" não encontrado.');
      } else {
        throw PlantNetException('Erro da API: ${response.statusCode} - ${response.data}');
      }

    } on DioException catch (e) {
      AppLogger.e('PlantNet API DioException', e);
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw PlantNetException('Conexão muito lenta. Verifique sua internet.');
      } else if (e.type == DioExceptionType.sendTimeout) {
        throw PlantNetException('Upload muito lento. Tente uma imagem menor.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw PlantNetException('Resposta muito lenta. Tente novamente.');
      } else if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        
        AppLogger.e('API Error Response: $responseData');
        
        switch (statusCode) {
          case 400:
            throw PlantNetException('Dados da requisição inválidos. Verifique a imagem e o órgão especificado.');
          case 401:
            throw PlantNetException('API key inválida ou expirada.');
          case 403:
            throw PlantNetException('Acesso negado. Verifique suas permissões.');
          case 404:
            throw PlantNetException('Endpoint não encontrado. Verifique a configuração.');
          case 413:
            throw PlantNetException('Imagem muito grande. Máximo 5MB.');
          case 429:
            throw PlantNetException('Muitas tentativas. Aguarde um momento.');
          case 500:
            throw PlantNetException('Erro no servidor. Tente novamente mais tarde.');
          default:
            throw PlantNetException('Erro HTTP $statusCode: $responseData');
        }
      } else {
        throw PlantNetException('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      AppLogger.e('Unexpected error in plant identification', e);
      throw PlantNetException('Erro inesperado: $e');
    }
  }

  // ✅ Método para identificar com múltiplas imagens
  Future<PlantIdentificationResult> identifyPlantMultipleImages({
    required List<File> imageFiles,
    required List<PlantOrgan> organs,
  }) async {
    try {
      if (imageFiles.isEmpty || organs.isEmpty) {
        throw PlantNetException('É necessário pelo menos uma imagem e um órgão');
      }
      
      if (imageFiles.length != organs.length) {
        throw PlantNetException('Número de imagens deve ser igual ao número de órgãos');
      }
      
      if (imageFiles.length > 5) {
        throw PlantNetException('Máximo 5 imagens por requisição');
      }

      AppLogger.i('Identifying plant with ${imageFiles.length} images...');

      final formData = FormData();
      
      // ✅ Adicionar múltiplas imagens
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        
        if (!await file.exists()) {
          throw PlantNetException('Arquivo de imagem ${i + 1} não encontrado');
        }

        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw PlantNetException('Imagem ${i + 1} muito grande. Máximo 5MB.');
        }

        formData.files.add(MapEntry(
          'images', // ✅ Mesmo nome para todas as imagens
          await MultipartFile.fromFile(
            file.path,
            filename: 'plant_image_${i + 1}.jpg',
          ),
        ));
      }
      
      // ✅ Adicionar órgãos correspondentes
      for (final organ in organs) {
        formData.fields.add(MapEntry('organs', organ.value));
      }
      
      // ✅ NOTA: Modifiers não são suportados pela API PlantNet v2

      const url = '$baseUrl/identify/$project';
      
      final response = await _dio.post(
        url,
        data: formData,
        queryParameters: {
          'api-key': apiKey,
          'include-related-images': false,
          'no-reject': false,
          'lang': 'pt',
        },
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return PlantIdentificationResult.fromJson(response.data);
      } else {
        throw PlantNetException('Erro da API: ${response.statusCode} - ${response.data}');
      }

    } catch (e) {
      if (e is PlantNetException) rethrow;
      AppLogger.e('Unexpected error in multiple image identification', e);
      throw PlantNetException('Erro inesperado: $e');
    }
  }

  Future<List<PlantSpecies>> getSpeciesInfo(List<String> scientificNames) async {
    // Implementar busca de informações detalhadas sobre espécies
    return scientificNames.map((name) => PlantSpecies(
      scientificName: name,
      commonNames: ['Nome comum não disponível'],
      family: 'Família não identificada',
      description: 'Informações detalhadas em breve.',
      scientificNameWithoutAuthor: name,
      scientificNameAuthorship: '',
      genus: '',
    )).toList();
  }
}

// ✅ Resto das classes permanecem iguais...
class PlantIdentificationResult {
  final String query;
  final String language;
  final int nbResults;
  final List<PlantMatch> results;
  final int remainingIdentificationRequests; // ✅ Mudado de bool para int

  PlantIdentificationResult({
    required this.query,
    required this.language,
    required this.nbResults,
    required this.results,
    required this.remainingIdentificationRequests,
  });

  factory PlantIdentificationResult.fromJson(Map<String, dynamic> json) {
    try {
      return PlantIdentificationResult(
        query: json['query']?.toString() ?? '',
        language: json['language']?.toString() ?? 'pt',
        nbResults: (json['nbResults'] as num?)?.toInt() ?? 0, // ✅ Conversão segura
        results: (json['results'] as List? ?? [])
            .map((r) => PlantMatch.fromJson(r as Map<String, dynamic>))
            .toList(),
        remainingIdentificationRequests: (json['remainingIdentificationRequests'] as num?)?.toInt() ?? 999, // ✅ Conversão segura
      );
    } catch (e) {
      AppLogger.e('Error parsing PlantIdentificationResult: $e');
      // Retorna resultado vazio em caso de erro
      return PlantIdentificationResult(
        query: '',
        language: 'pt',
        nbResults: 0,
        results: [],
        remainingIdentificationRequests: 0,
      );
    }
  }

  PlantMatch? get bestMatch {
    if (results.isEmpty) return null;
    return results.first;
  }

  bool get hasConfidentMatch {
    return bestMatch != null && bestMatch!.score > 0.3;
  }

  // ✅ Novo getter para verificar se ainda há requisições disponíveis
  bool get hasRemainingRequests {
    return remainingIdentificationRequests > 0;
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
    try {
      return PlantMatch(
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        species: PlantSpecies.fromJson((json['species'] as Map<String, dynamic>?) ?? {}),
        images: (json['images'] as List? ?? [])
            .map((i) => PlantImage.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      AppLogger.e('Error parsing PlantMatch: $e');
      return PlantMatch(
        score: 0.0,
        species: PlantSpecies(
          scientificNameWithoutAuthor: 'Erro no parsing',
          scientificNameAuthorship: '',
          scientificName: 'Erro',
          genus: '',
          family: '',
          commonNames: [],
        ),
        images: [],
      );
    }
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
    try {
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
    } catch (e) {
      AppLogger.e('Error parsing PlantSpecies: $e');
      return PlantSpecies(
        scientificNameWithoutAuthor: 'Erro no parsing',
        scientificNameAuthorship: '',
        scientificName: 'Erro',
        genus: '',
        family: '',
        commonNames: [],
      );
    }
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
    try {
      return PlantImage(
        url: json['url']?.toString() ?? '',
        organ: json['organ']?.toString() ?? '',
        author: json['author']?.toString() ?? '',
        license: json['license']?.toString() ?? '',
      );
    } catch (e) {
      AppLogger.e('Error parsing PlantImage: $e');
      return PlantImage(
        url: '',
        organ: '',
        author: '',
        license: '',
      );
    }
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

/*
// ✅ NOTA: Modifiers não são suportados pela API PlantNet v2
// Mantido comentado para possível uso futuro
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
*/

class PlantNetException implements Exception {
  final String message;
  PlantNetException(this.message);

  @override
  String toString() => 'PlantNetException: $message';
}