// lib/features/map/presentation/pages/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  // Beira, Mozambique coordinates
  static const LatLng _beiraCenter = LatLng(-19.8437, 34.8389);
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _selectedFilter = 'todos';
  
  // Mock markers data
  final List<MarkerData> _markerData = [
    // Bacia 1 - Biodiversidade
    MarkerData(
      id: 'bacia1_001',
      title: 'Entrada Bacia 1',
      description: 'Portal de biodiversidade - Comece sua jornada aqui!',
      position: const LatLng(-19.8420, 34.8350),
      type: MarkerType.biodiversidade,
      points: 50,
      isVisited: true,
      challenges: 2,
    ),
    MarkerData(
      id: 'bacia1_002',
      title: 'Trilha das Árvores Nativas',
      description: 'Descubra as espécies endêmicas de Moçambique',
      position: const LatLng(-19.8425, 34.8360),
      type: MarkerType.biodiversidade,
      points: 75,
      isVisited: false,
      challenges: 3,
    ),
    MarkerData(
      id: 'bacia1_003',
      title: 'Observatório de Aves',
      description: 'Mais de 50 espécies de aves podem ser vistas aqui',
      position: const LatLng(-19.8430, 34.8370),
      type: MarkerType.biodiversidade,
      points: 100,
      isVisited: false,
      challenges: 4,
    ),
    
    // Bacia 2 - Recursos Hídricos
    MarkerData(
      id: 'bacia2_001',
      title: 'Centro de Recursos Hídricos',
      description: 'Aprenda sobre conservação da água',
      position: const LatLng(-19.8450, 34.8400),
      type: MarkerType.recursosHidricos,
      points: 75,
      isVisited: true,
      challenges: 3,
    ),
    MarkerData(
      id: 'bacia2_002',
      title: 'Lago Interativo',
      description: 'Simulação do ciclo da água em AR',
      position: const LatLng(-19.8455, 34.8410),
      type: MarkerType.recursosHidricos,
      points: 100,
      isVisited: false,
      challenges: 2,
    ),
    MarkerData(
      id: 'bacia2_003',
      title: 'Estação de Tratamento',
      description: 'Veja como funciona o tratamento de água',
      position: const LatLng(-19.8460, 34.8420),
      type: MarkerType.recursosHidricos,
      points: 125,
      isVisited: false,
      challenges: 5,
    ),
    
    // Bacia 3 - Agricultura Urbana
    MarkerData(
      id: 'bacia3_001',
      title: 'Horta Comunitária',
      description: 'Aprenda técnicas de agricultura sustentável',
      position: const LatLng(-19.8470, 34.8450),
      type: MarkerType.agriculturaUrbana,
      points: 85,
      isVisited: false,
      challenges: 3,
    ),
    MarkerData(
      id: 'bacia3_002',
      title: 'Centro de Compostagem',
      description: 'Transforme resíduos em adubo orgânico',
      position: const LatLng(-19.8475, 34.8460),
      type: MarkerType.agriculturaUrbana,
      points: 90,
      isVisited: false,
      challenges: 4,
    ),
    MarkerData(
      id: 'bacia3_003',
      title: 'Mercado Sustentável',
      description: 'Economia circular em ação',
      position: const LatLng(-19.8480, 34.8470),
      type: MarkerType.agriculturaUrbana,
      points: 110,
      isVisited: false,
      challenges: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    _fabAnimationController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  List<Marker> _getFilteredMarkers() {
    final filteredData = _markerData.where((markerData) {
      return _selectedFilter == 'todos' || 
             _getFilterType(markerData.type) == _selectedFilter;
    }).toList();

    return filteredData.map((markerData) {
      return Marker(
        point: markerData.position,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showMarkerDetails(markerData),
          child: Container(
            decoration: BoxDecoration(
              color: markerData.isVisited 
                  ? AppTheme.successGreen 
                  : _getTypeColor(markerData.type),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getTypeIcon(markerData.type),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  String _getFilterType(MarkerType type) {
    switch (type) {
      case MarkerType.biodiversidade:
        return 'biodiversidade';
      case MarkerType.recursosHidricos:
        return 'recursos';
      case MarkerType.agriculturaUrbana:
        return 'agricultura';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedSnackBar();
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      
      // Mover o mapa para a localização atual
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
      
    } catch (e) {
      _showLocationErrorSnackBar();
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa dos Parques'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showMapLegend,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Flutter Map com OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _beiraCenter,
              zoom: 14.0,
              maxZoom: 18.0,
              minZoom: 10.0,
            ),
            children: [
              // Tile Layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecoar_beira',
                maxZoom: 18,
              ),
              
              // Markers Layer
              MarkerLayer(
                markers: _getFilteredMarkers(),
              ),
              
              // Current Location Marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Filter Chips
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('todos', 'Todos', Icons.map),
                  const SizedBox(width: 8),
                  _buildFilterChip('biodiversidade', 'Biodiversidade', Icons.eco),
                  const SizedBox(width: 8),
                  _buildFilterChip('recursos', 'Recursos Hídricos', Icons.water_drop),
                  const SizedBox(width: 8),
                  _buildFilterChip('agricultura', 'Agricultura', Icons.agriculture),
                ],
              ),
            ),
          ),
          
          // Stats Card
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _buildStatsCard(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "location",
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              backgroundColor: AppTheme.primaryBlue,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: "scan",
              onPressed: () => context.go('/scanner'),
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.qr_code_scanner),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalMarkers = _markerData.length;
    final visitedMarkers = _markerData.where((m) => m.isVisited).length;
    final totalPoints = _markerData.where((m) => m.isVisited).fold(0, (sum, m) => sum + m.points);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Visitados',
            '$visitedMarkers/$totalMarkers',
            Icons.location_on,
            AppTheme.primaryGreen,
          ),
          _buildStatItem(
            'Pontos',
            totalPoints.toString(),
            Icons.star,
            AppTheme.warningOrange,
          ),
          _buildStatItem(
            'Próximo',
            _getNextMarkerDistance(),
            Icons.navigation,
            AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getNextMarkerDistance() {
    if (_currentPosition == null) return '--';
    
    final unvisitedMarkers = _markerData.where((m) => !m.isVisited);
    if (unvisitedMarkers.isEmpty) return '0m';
    
    double minDistance = double.infinity;
    for (var marker in unvisitedMarkers) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    if (minDistance < 1000) {
      return '${minDistance.round()}m';
    } else {
      return '${(minDistance / 1000).toStringAsFixed(1)}km';
    }
  }

  void _showMarkerDetails(MarkerData markerData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTypeColor(markerData.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getTypeIcon(markerData.type),
                              color: _getTypeColor(markerData.type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  markerData.title,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  _getTypeName(markerData.type),
                                  style: TextStyle(
                                    color: _getTypeColor(markerData.type),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (markerData.isVisited)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Visitado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        markerData.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              'Pontos',
                              markerData.points.toString(),
                              Icons.star,
                              AppTheme.warningOrange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              'Desafios',
                              markerData.challenges.toString(),
                              Icons.quiz,
                              AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              'Distância',
                              _getDistanceToMarker(markerData),
                              Icons.navigation,
                              AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToMarker(markerData.position);
                              },
                              icon: const Icon(Icons.directions),
                              label: const Text('Navegação'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.go('/scanner');
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Escanear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(MarkerType type) {
    switch (type) {
      case MarkerType.biodiversidade:
        return AppTheme.primaryGreen;
      case MarkerType.recursosHidricos:
        return AppTheme.primaryBlue;
      case MarkerType.agriculturaUrbana:
        return AppTheme.warningOrange;
    }
  }

  IconData _getTypeIcon(MarkerType type) {
    switch (type) {
      case MarkerType.biodiversidade:
        return Icons.eco;
      case MarkerType.recursosHidricos:
        return Icons.water_drop;
      case MarkerType.agriculturaUrbana:
        return Icons.agriculture;
    }
  }

  String _getTypeName(MarkerType type) {
    switch (type) {
      case MarkerType.biodiversidade:
        return 'Biodiversidade';
      case MarkerType.recursosHidricos:
        return 'Recursos Hídricos';
      case MarkerType.agriculturaUrbana:
        return 'Agricultura Urbana';
    }
  }

  String _getDistanceToMarker(MarkerData markerData) {
    if (_currentPosition == null) return '--';
    
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      markerData.position.latitude,
      markerData.position.longitude,
    );
    
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  void _navigateToMarker(LatLng position) {
    _mapController.move(position, 18.0);
  }

  void _showMapLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legenda do Mapa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Icons.eco, 'Biodiversidade', AppTheme.primaryGreen),
            _buildLegendItem(Icons.water_drop, 'Recursos Hídricos', AppTheme.primaryBlue),
            _buildLegendItem(Icons.agriculture, 'Agricultura Urbana', AppTheme.warningOrange),
            const SizedBox(height: 16),
            const Text(
              'Marcadores com borda verde indicam locais já visitados.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Serviços de Localização'),
        content: const Text('Por favor, habilite os serviços de localização para usar esta funcionalidade.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissão de localização negada'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _showLocationErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erro ao obter localização'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }
}

// Helper classes
class MarkerData {
  final String id;
  final String title;
  final String description;
  final LatLng position;
  final MarkerType type;
  final int points;
  final bool isVisited;
  final int challenges;

  MarkerData({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.type,
    required this.points,
    required this.isVisited,
    required this.challenges,
  });
}

enum MarkerType {
  biodiversidade,
  recursosHidricos,
  agriculturaUrbana,
}