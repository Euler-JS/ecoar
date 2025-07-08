import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _weeklyLeaders = [
    {
      'rank': 1,
      'name': 'Maria Santos',
      'points': 850,
      'avatar': null,
      'badges': 5,
      'isCurrentUser': false,
    },
    {
      'rank': 2,
      'name': 'João Silva',
      'points': 750,
      'avatar': null,
      'badges': 3,
      'isCurrentUser': true,
    },
    {
      'rank': 3,
      'name': 'Ana Costa',
      'points': 680,
      'avatar': null,
      'badges': 4,
      'isCurrentUser': false,
    },
    {
      'rank': 4,
      'name': 'Pedro Lima',
      'points': 520,
      'avatar': null,
      'badges': 2,
      'isCurrentUser': false,
    },
    {
      'rank': 5,
      'name': 'Sofia Oliveira',
      'points': 480,
      'avatar': null,
      'badges': 3,
      'isCurrentUser': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semanal'),
            Tab(text: 'Mensal'),
            Tab(text: 'Geral'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(_weeklyLeaders),
          _buildLeaderboardTab(_weeklyLeaders), // Mock data
          _buildLeaderboardTab(_weeklyLeaders), // Mock data
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(List<Map<String, dynamic>> leaders) {
    return CustomScrollView(
      slivers: [
        // Top 3 Podium
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: _buildPodium(leaders.take(3).toList()),
          ),
        ),
        
        // Rest of the list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final leader = leaders[index + 3];
              return _buildLeaderboardItem(leader);
            },
            childCount: leaders.length - 3,
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (topThree.length > 1) _buildPodiumItem(topThree[1], 80),
          const SizedBox(width: 16),
          // 1st place
          if (topThree.isNotEmpty) _buildPodiumItem(topThree[0], 100),
          const SizedBox(width: 16),
          // 3rd place
          if (topThree.length > 2) _buildPodiumItem(topThree[2], 60),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> leader, double height) {
    final rank = leader['rank'] as int;
    Color podiumColor;
    IconData crownIcon;
    
    switch (rank) {
      case 1:
        podiumColor = Colors.amber;
        crownIcon = Icons.emoji_events;
        break;
      case 2:
        podiumColor = Colors.grey[400]!;
        crownIcon = Icons.military_tech;
        break;
      case 3:
        podiumColor = Colors.orange[300]!;
        crownIcon = Icons.workspace_premium;
        break;
      default:
        podiumColor = Colors.grey;
        crownIcon = Icons.star;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown/Trophy
        Icon(
          crownIcon,
          color: podiumColor,
          size: rank == 1 ? 32 : 24,
        ),
        const SizedBox(height: 8),
        // Avatar
        Container(
          width: rank == 1 ? 60 : 50,
          height: rank == 1 ? 60 : 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: podiumColor, width: 3),
          ),
          child: const Icon(
            Icons.person,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          leader['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        // Points
        Text(
          '${leader['points']} pts',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        // Podium base
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> leader) {
    final isCurrentUser = leader['isCurrentUser'] as bool;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? AppTheme.primaryGreen : Colors.grey.shade200,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isCurrentUser ? AppTheme.primaryGreen : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                '#${leader['rank']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      leader['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser ? AppTheme.primaryGreen : AppTheme.textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Você',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.military_tech,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${leader['badges']} badges',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${leader['points']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? AppTheme.primaryGreen : AppTheme.textPrimary,
                ),
              ),
              const Text(
                'pontos',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
