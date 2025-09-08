import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'dart:io';

class LeaderboardsSection extends ConsumerWidget {
  final List<Player> players;
  final String teamId;

  const LeaderboardsSection({
    super.key,
    required this.players,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerRepo = ref.watch(playerRepositoryProvider);
    
    // Add null check for teamId
    if (teamId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Leaderboards',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No team selected'),
            ),
          ),
        ],
      );
    }
    
    try {
      debugPrint('LeaderboardsSection building for teamId: $teamId');
      // Get top 5 lists
      final topScorers = playerRepo.getTopScorers(teamId, limit: 5);
      final topAssistors = playerRepo.getTopAssistors(teamId, limit: 5);
      final topRated = playerRepo.getTopRated(teamId, limit: 5);
      final mostPresent = playerRepo.getMostPresent(teamId, limit: 5);

      debugPrint('Creating leaderboard cards...');
      debugPrint('Top scorers: ${topScorers.length} players');
      debugPrint('Top assistors: ${topAssistors.length} players'); 
      debugPrint('Top rated: ${topRated.length} players');
      debugPrint('Most present: ${mostPresent.length} players');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 5 Leaderboards',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Leaderboards Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
          children: [
            _buildLeaderboardCard(
              context,
              title: 'Top Scorers',
              icon: Icons.sports_soccer,
              color: Colors.green, // Keep green for goals (positive)
              players: topScorers,
              getStatValue: (player) => player.goals.toString(),
              statLabel: 'goals',
            ),
            _buildLeaderboardCard(
              context,
              title: 'Top Assistors',
              icon: Icons.assistant,
              color: Colors.deepOrange, // Sports theme - assists
              players: topAssistors,
              getStatValue: (player) => player.assists.toString(),
              statLabel: 'assists',
            ),
            _buildLeaderboardCard(
              context,
              title: 'Highest Rated',
              icon: Icons.star,
              color: Colors.amber, // Gold for highest rated (excellence)
              players: topRated,
              getStatValue: (player) => player.avgRating?.toStringAsFixed(2) ?? 'N/A',
              statLabel: 'avg rating',
            ),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: const Color(0xFFFF7F00), size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Most Present',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF7F00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Temporarily disabled',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
    } catch (e) {
      debugPrint('Error in leaderboards: $e');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Leaderboards',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading leaderboards. Please try again.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLeaderboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Player> players,
    required String Function(Player) getStatValue,
    required String statLabel,
    bool isInverted = false,
  }) {
    debugPrint('Building leaderboard card: $title with ${players.length} players');
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Players List
            Expanded(
              child: players.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No data yet',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final statValue = getStatValue(player);
                        
                        // Skip players with no stats for certain categories
                        if (statLabel == 'avg rating' && player.avgRating == null) {
                          return const SizedBox.shrink();
                        }
                        if (statLabel == 'goals' && player.goals == 0) {
                          return const SizedBox.shrink();
                        }
                        if (statLabel == 'assists' && player.assists == 0) {
                          return const SizedBox.shrink();
                        }
                        
                        return _buildPlayerListItem(
                          context,
                          player: player,
                          position: index + 1,
                          statValue: statValue,
                          statLabel: statLabel,
                          color: color,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerListItem(
    BuildContext context, {
    required Player player,
    required int position,
    required String statValue,
    required String statLabel,
    required Color color,
  }) {
    return InkWell(
      onTap: () => context.go('/players/${player.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Position Badge
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getPositionColor(position),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  position.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Player Photo
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: player.photoPath != null && File(player.photoPath!).existsSync()
                  ? ClipOval(
                      child: Image.file(
                        File(player.photoPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        '${player.firstName[0]}${player.lastName[0]}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            
            // Player Name and Stat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${player.firstName} ${player.lastName}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$statValue $statLabel',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber[600]!; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[400]!; // Bronze
      default:
        return const Color(0xFFFF7F00); // Caterpillar orange
    }
  }
}