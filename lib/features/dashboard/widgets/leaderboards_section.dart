import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_utils.dart';

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
            AppLocalizations.of(context)!.topLeaderboards,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(context)!.noTeamsInSeason),
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
      final mostAbsences = playerRepo.getMostAbsences(teamId, limit: 5);

      debugPrint('Creating leaderboard cards...');
      debugPrint('Top scorers: ${topScorers.length} players');
      debugPrint('Top assistors: ${topAssistors.length} players'); 
      debugPrint('Top rated: ${topRated.length} players');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.topLeaderboards,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Top Scorers Card
        _buildLeaderboardCard(
          context,
          title: AppLocalizations.of(context)!.topScorers,
          icon: Icons.sports_soccer,
          color: Colors.green,
          players: topScorers,
          getStatValue: (player) => player.goals.toString(),
          statLabel: 'goals',
        ),
        
        const SizedBox(height: 16),
        
        // Top Assistors Card
        _buildLeaderboardCard(
          context,
          title: AppLocalizations.of(context)!.topAssistors,
          icon: Icons.gps_fixed,
          color: Colors.deepOrange,
          players: topAssistors,
          getStatValue: (player) => player.assists.toString(),
          statLabel: 'assists',
        ),
        
        const SizedBox(height: 16),
        
        // Highest Rated Card
        _buildLeaderboardCard(
          context,
          title: AppLocalizations.of(context)!.highestRated,
          icon: Icons.star,
          color: Colors.amber,
          players: topRated,
          getStatValue: (player) => player.avgRating?.toStringAsFixed(1) ?? '0.0',
          statLabel: 'rating',
        ),
        
        const SizedBox(height: 16),
        
        // Most Absences Card
        _buildLeaderboardCard(
          context,
          title: 'Most Absences',
          icon: Icons.cancel,
          color: Colors.red,
          players: mostAbsences,
          getStatValue: (player) => player.absences.toString(),
          statLabel: 'absences',
        ),
      ],
    );
    } catch (e) {
      debugPrint('Error in leaderboards: $e');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.topLeaderboards,
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
  }) {
    debugPrint('Building leaderboard card: $title with ${players.length} players');
    
    // Filter players with stats > 0
    final filteredPlayers = players.where((player) {
      if (statLabel == 'goals') return player.goals > 0;
      if (statLabel == 'assists') return player.assists > 0;
      if (statLabel == 'rating') return player.avgRating != null && player.avgRating! > 0;
      if (statLabel == 'absences') return player.absences > 0;
      return true;
    }).take(5).toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Players List
            if (filteredPlayers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No data yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stats will appear after matches',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: filteredPlayers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  return _buildPlayerRow(context, player, index + 1, getStatValue(player), statLabel);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    Player player,
    int position,
    String statValue,
    String statLabel,
  ) {
    return InkWell(
      onTap: () => context.go('/players/${player.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getPositionColor(position),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  position.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Player avatar (using safe image utility)
            ImageUtils.buildPlayerAvatar(
              firstName: player.firstName,
              lastName: player.lastName,
              photoPath: player.photoPath,
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              textColor: Theme.of(context).colorScheme.primary,
              fontSize: 10,
            ),
            const SizedBox(width: 12),
            
            // Player name
            Expanded(
              child: Text(
                '${player.firstName} ${player.lastName}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            
            // Stat value
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statValue,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
        return const Color(0xFFFF7F00); // Orange
    }
  }
}