import 'package:dio/dio.dart';
import 'logger.dart';

class ErrorHandler {
  
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FormatException) {
      return 'Formato de dados inválido';
    } else if (error is TypeError) {
      return 'Erro de tipo de dados';
    } else {
      return error.toString().isEmpty 
          ? 'Erro desconhecido' 
          : error.toString();
    }
  }
  
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tempo limite de conexão excedido';
      case DioExceptionType.sendTimeout:
        return 'Tempo limite de envio excedido';
      case DioExceptionType.receiveTimeout:
        return 'Tempo limite de recebimento excedido';
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'Requisição cancelada';
      case DioExceptionType.connectionError:
        return 'Erro de conexão. Verifique sua internet';
      case DioExceptionType.unknown:
        return 'Erro de rede desconhecido';
      default:
        return 'Erro de comunicação';
    }
  }
  
  static String _handleResponseError(int? statusCode) {
    if (statusCode == null) return 'Resposta inválida do servidor';
    
    switch (statusCode) {
      case 400:
        return 'Requisição inválida';
      case 401:
        return 'Não autorizado. Faça login novamente';
      case 403:
        return 'Acesso negado';
      case 404:
        return 'Recurso não encontrado';
      case 409:
        return 'Conflito de dados';
      case 422:
        return 'Dados inválidos';
      case 429:
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 500:
        return 'Erro interno do servidor';
      case 502:
        return 'Servidor indisponível';
      case 503:
        return 'Serviço temporariamente indisponível';
      default:
        return 'Erro do servidor (${statusCode})';
    }
  }
  
  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    final message = getErrorMessage(error);
    AppLogger.logError(context, '$message - ${error.toString()}', stackTrace);
  }
  
  static Map<String, dynamic> createErrorReport(
    String context,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
      'error_message': getErrorMessage(error),
      'error_type': error.runtimeType.toString(),
      'stack_trace': stackTrace?.toString(),
      'app_version': AppConfig.appVersion,
    };
  }
}