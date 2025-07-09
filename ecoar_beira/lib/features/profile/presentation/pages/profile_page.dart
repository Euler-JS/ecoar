import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ecoar_beira/core/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'João Silva',
    'email': 'joao.silva@email.com',
    'level': 'Explorador',
    'points': 1250,
    'markersVisited': 8,
    'challengesCompleted': 15,
    'badgesEarned': 3,
    'joinDate': '15 de Janeiro, 2024',
    'avatar': null,
  };

  final List<Map<String, dynamic>> _badges = [
    {
      'id': 'descobridor',
      'name': 'Descobridor',
      'description': 'Primeiro marcador escaneado',
      'icon': Icons.explore,
      'color': Colors.blue,
      'earned': true,
      'date': '16 Jan 2024',
    },
    {
      'id': 'cientista',
      'name': 'Pequeno Cientista',
      'description': '10 quizzes corretos',
      'icon': Icons.science,
      'color': Colors.purple,
      'earned': true,
      'date': '22 Jan 2024',
    },
    {
      'id': 'eco_warrior',
      'name': 'Eco Warrior',
      'description': 'Visitou as 3 bacias',
      'icon': Icons.eco,
      'color': Colors.green,
      'earned': true,
      'date': '28 Jan 2024',
    },
    {
      'id': 'influencer',
      'name': 'Influencer Verde',
      'description': 'Compartilhou 5 experiências',
      'icon': Icons.share,
      'color': Colors.orange,
      'earned': false,
      'date': null,
    },
    {
      'id': 'mestre',
      'name': 'Mestre Ambiental',
      'description': 'Completou 50 desafios',
      'icon': Icons.school,
      'color': Colors.red,
      'earned': false,
      'date': null,
    },
  ];

  final List<Map<String, dynamic>> _recentActivities = [
    {
      'title': 'Quiz de Biodiversidade Completado',
      'description': 'Bacia 1 - 10/10 respostas corretas',
      'points': '+100 pontos',
      'icon': Icons.quiz,
      'color': AppTheme.primaryGreen,
      'date': 'Hoje, 14:30',
    },
    {
      'title': 'Marcador Escaneado',
      'description': 'Trilha das Árvores Nativas',
      'points': '+75 pontos',
      'icon': Icons.qr_code_scanner,
      'color': AppTheme.primaryBlue,
      'date': 'Ontem, 16:45',
    },
    {
      'title': 'Badge Conquistado',
      'description': 'Eco Warrior - Visitou todas as bacias',
      'points': 'Badge desbloqueado',
      'icon': Icons.military_tech,
      'color': AppTheme.warningOrange,
      'date': '28 Jan, 10:20',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _userData['avatar'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        _userData['avatar'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppTheme.primaryGreen,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _editProfile,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name and Level
                        Text(
                          _userData['name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _userData['level'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Membro desde ${_userData['joinDate']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showSettings,
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Cards
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    
                    // Badges Section
                    _buildBadgesSection(),
                    const SizedBox(height: 24),
                    
                    // Recent Activities
                    _buildActivitiesSection(),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pontos',
                _userData['points'].toString(),
                Icons.star,
                AppTheme.warningOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Marcadores',
                _userData['markersVisited'].toString(),
                Icons.location_on,
                AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Desafios',
                _userData['challengesCompleted'].toString(),
                Icons.quiz,
                AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Badges',
                _userData['badgesEarned'].toString(),
                Icons.military_tech,
                AppTheme.errorRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Badges Conquistados',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: _showAllBadges,
              child: const Text('Ver Todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _badges.length,
            itemBuilder: (context, index) {
              final badge = _badges[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: _buildBadgeCard(badge),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final isEarned = badge['earned'] as bool;
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEarned ? badge['color'].withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? badge['color'].withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              badge['icon'],
              size: 32,
              color: isEarned ? badge['color'] : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              badge['name'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEarned ? badge['color'] : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isEarned && badge['date'] != null) ...[
              const SizedBox(height: 4),
              Text(
                badge['date'],
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atividades Recentes',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        ...(_recentActivities.map((activity) => _buildActivityItem(activity))),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  activity['description'],
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  activity['date'],
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['points'],
            style: TextStyle(
              color: activity['color'],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/leaderboard'),
            icon: const Icon(Icons.leaderboard),
            label: const Text('Ver Ranking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareProfile,
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Exportar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Editar Perfil',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                // Edit form would go here
                const Text('Funcionalidade em desenvolvimento'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificações'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidade'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Ajuda'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: const Text('Sair', style: TextStyle(color: AppTheme.errorRed)),
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllBadges() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => AllBadgesPage(badges: _badges),
    //   ),
    // );
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(badge['icon'], color: badge['color']),
            const SizedBox(width: 8),
            Text(badge['name']),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge['description']),
            if (badge['earned'] && badge['date'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Conquistado em: ${badge['date']}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhamento em desenvolvimento')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportação em desenvolvimento')),
    );
  }
}
