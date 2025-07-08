import 'dart:math'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class MarkersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MarkersLoadAll extends MarkersEvent {}

class MarkersLoadByType extends MarkersEvent {
  final String type;
  
  MarkersLoadByType({required this.type});
  
  @override
  List<Object?> get props => [type];
}

class MarkersLoadNearby extends MarkersEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;
  
  MarkersLoadNearby({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5.0,
  });
  
  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

class MarkersMarkAsVisited extends MarkersEvent {
  final String markerId;
  
  MarkersMarkAsVisited({required this.markerId});
  
  @override
  List<Object?> get props => [markerId];
}

class MarkersSearch extends MarkersEvent {
  final String query;
  
  MarkersSearch({required this.query});
  
  @override
  List<Object?> get props => [query];
}

// Markers States
abstract class MarkersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MarkersInitial extends MarkersState {}

class MarkersLoading extends MarkersState {}

class MarkersLoaded extends MarkersState {
  final List<Map<String, dynamic>> markers;
  
  MarkersLoaded({required this.markers});
  
  @override
  List<Object?> get props => [markers];
}

class MarkersError extends MarkersState {
  final String message;
  
  MarkersError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class MarkersSearchResults extends MarkersState {
  final List<Map<String, dynamic>> results;
  final String query;
  
  MarkersSearchResults({required this.results, required this.query});
  
  @override
  List<Object?> get props => [results, query];
}

// Markers BLoC
class MarkersBloc extends Bloc<MarkersEvent, MarkersState> {
  List<Map<String, dynamic>> _allMarkers = [];
  
  MarkersBloc() : super(MarkersInitial()) {
    on<MarkersLoadAll>(_onLoadAll);
    on<MarkersLoadByType>(_onLoadByType);
    on<MarkersLoadNearby>(_onLoadNearby);
    on<MarkersMarkAsVisited>(_onMarkAsVisited);
    on<MarkersSearch>(_onSearch);
    
    // Initialize with mock data
    _initializeMockData();
  }
  
  void _initializeMockData() {
    _allMarkers = [
      {
        'id': 'bacia1_001',
        'title': 'Entrada Bacia 1',
        'description': 'Portal de biodiversidade - Comece sua jornada aqui!',
        'latitude': -19.8420,
        'longitude': 34.8350,
        'type': 'biodiversidade',
        'points': 50,
        'isVisited': false,
        'challenges': [
          {'id': 'bio_quiz_1', 'title': 'Quiz de Biodiversidade', 'points': 100},
          {'id': 'plant_id_1', 'title': 'Identificação de Plantas', 'points': 75},
        ],
        'arSceneId': 'biodiversity_scene_01',
        'qrCode': 'bacia1_001_qr',
        'imageUrls': ['https://example.com/bacia1_001.jpg'],
        'isActive': true,
      },
      {
        'id': 'bacia1_002',
        'title': 'Trilha das Árvores Nativas',
        'description': 'Descubra as espécies endêmicas de Moçambique',
        'latitude': -19.8425,
        'longitude': 34.8360,
        'type': 'biodiversidade',
        'points': 75,
        'isVisited': false,
        'challenges': [
          {'id': 'tree_id_1', 'title': 'Identificação de Árvores', 'points': 125},
        ],
        'arSceneId': 'trees_scene_01',
        'qrCode': 'bacia1_002_qr',
        'imageUrls': ['https://example.com/bacia1_002.jpg'],
        'isActive': true,
      },
      {
        'id': 'bacia2_001',
        'title': 'Centro de Recursos Hídricos',
        'description': 'Aprenda sobre conservação da água',
        'latitude': -19.8450,
        'longitude': 34.8400,
        'type': 'recursos_hidricos',
        'points': 75,
        'isVisited': false,
        'challenges': [
          {'id': 'water_cycle_1', 'title': 'Ciclo da Água', 'points': 100},
          {'id': 'water_conservation_1', 'title': 'Conservação de Água', 'points': 150},
        ],
        'arSceneId': 'water_scene_01',
        'qrCode': 'bacia2_001_qr',
        'imageUrls': ['https://example.com/bacia2_001.jpg'],
        'isActive': true,
      },
      {
        'id': 'bacia3_001',
        'title': 'Horta Comunitária',
        'description': 'Aprenda técnicas de agricultura sustentável',
        'latitude': -19.8470,
        'longitude': 34.8450,
        'type': 'agricultura_urbana',
        'points': 85,
        'isVisited': false,
        'challenges': [
          {'id': 'composting_1', 'title': 'Técnicas de Compostagem', 'points': 120},
        ],
        'arSceneId': 'farming_scene_01',
        'qrCode': 'bacia3_001_qr',
        'imageUrls': ['https://example.com/bacia3_001.jpg'],
        'isActive': true,
      },
    ];
  }
  
  Future<void> _onLoadAll(
    MarkersLoadAll event,
    Emitter<MarkersState> emit,
  ) async {
    emit(MarkersLoading());
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      emit(MarkersLoaded(markers: _allMarkers));
    } catch (e) {
      emit(MarkersError(message: 'Erro ao carregar marcadores: ${e.toString()}'));
    }
  }
  
  Future<void> _onLoadByType(
    MarkersLoadByType event,
    Emitter<MarkersState> emit,
  ) async {
    emit(MarkersLoading());
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final filteredMarkers = _allMarkers
          .where((marker) => marker['type'] == event.type)
          .toList();
      
      emit(MarkersLoaded(markers: filteredMarkers));
    } catch (e) {
      emit(MarkersError(message: 'Erro ao filtrar marcadores: ${e.toString()}'));
    }
  }
  
  Future<void> _onLoadNearby(
    MarkersLoadNearby event,
    Emitter<MarkersState> emit,
  ) async {
    emit(MarkersLoading());
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simple distance calculation (in a real app, use proper geolocation)
      final nearbyMarkers = _allMarkers.where((marker) {
        final lat = marker['latitude'] as double;
        final lng = marker['longitude'] as double;
        
        // Simplified distance check
        final distance = _calculateDistance(
          event.latitude, event.longitude, lat, lng);
        
        return distance <= event.radiusKm;
      }).toList();
      
      emit(MarkersLoaded(markers: nearbyMarkers));
    } catch (e) {
      emit(MarkersError(message: 'Erro ao buscar marcadores próximos: ${e.toString()}'));
    }
  }
  
  Future<void> _onMarkAsVisited(
    MarkersMarkAsVisited event,
    Emitter<MarkersState> emit,
  ) async {
    try {
      final markerIndex = _allMarkers.indexWhere(
        (marker) => marker['id'] == event.markerId);
      
      if (markerIndex != -1) {
        _allMarkers[markerIndex]['isVisited'] = true;
        emit(MarkersLoaded(markers: _allMarkers));
      }
    } catch (e) {
      emit(MarkersError(message: 'Erro ao marcar como visitado: ${e.toString()}'));
    }
  }
  
  Future<void> _onSearch(
    MarkersSearch event,
    Emitter<MarkersState> emit,
  ) async {
    emit(MarkersLoading());
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (event.query.isEmpty) {
        emit(MarkersLoaded(markers: _allMarkers));
        return;
      }
      
      final results = _allMarkers.where((marker) {
        final title = marker['title'].toString().toLowerCase();
        final description = marker['description'].toString().toLowerCase();
        final query = event.query.toLowerCase();
        
        return title.contains(query) || description.contains(query);
      }).toList();
      
      emit(MarkersSearchResults(results: results, query: event.query));
    } catch (e) {
      emit(MarkersError(message: 'Erro na busca: ${e.toString()}'));
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simplified distance calculation
    // In a real app, use the Geolocator package's distanceBetween method
    const double p = 0.017453292519943295;
    final a = 0.5 - 
        cos((lat2 - lat1) * p) / 2 + 
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}