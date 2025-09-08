import 'package:flutter/material.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match.dart';

class TeamStatisticsCard extends StatelessWidget {
  final Team team;
  final List<Player> players;
  final List<Match> matches;

  const TeamStatisticsCard({
    super.key,
    required this.team,
    required this.players,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate team statistics
    final teamStats = _calculateTeamStats();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.teamStatistics} - ${team.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, // Changed from 3 to 2 for mobile
              crossAxisSpacing: 8, // Reduced from 12
              mainAxisSpacing: 8, // Reduced from 12
              childAspectRatio: 1.4, // Adjusted for better fit
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.people,
                  label: AppLocalizations.of(context)!.playerCount,
                  value: teamStats['players']!.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.sports_soccer,
                  label: AppLocalizations.of(context)!.goalsFor,
                  value: teamStats['goalsFor']!.toString(),
                  color: Colors.green,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.shield,
                  label: AppLocalizations.of(context)!.goalsAgainst,
                  value: teamStats['goalsAgainst']!.toString(),
                  color: Colors.red,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.assistant,
                  label: AppLocalizations.of(context)!.totalAssists,
                  value: teamStats['totalAssists']!.toString(),
                  color: Colors.orange,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.warning,
                  label: AppLocalizations.of(context)!.yellowCards,
                  value: teamStats['yellowCards']!.toString(),
                  color: Colors.amber,
                ),
                _buildStatCard(
                  context,
                  icon: Icons.sports,
                  label: AppLocalizations.of(context)!.matchCount,
                  value: teamStats['matches']!.toString(),
                  color: Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 12
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 20, // Reduced from 24
          ),
          const SizedBox(height: 4), // Reduced from 8
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 18, // Explicitly set smaller size
            ),
          ),
          const SizedBox(height: 2), // Reduced from 4
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11, // Smaller label text
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow wrapping if needed
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateTeamStats() {
    // Calculate goals for/against from completed matches
    int goalsFor = 0;
    int goalsAgainst = 0;
    int completedMatches = 0;

    for (final match in matches) {
      if (match.goalsFor != null && match.goalsAgainst != null) {
        goalsFor += match.goalsFor!;
        goalsAgainst += match.goalsAgainst!;
        completedMatches++;
      }
    }

    // Calculate player statistics
    final totalAssists = players.fold(0, (sum, player) => sum + player.assists);
    final totalYellowCards = players.fold(0, (sum, player) => sum + player.yellowCards);

    return {
      'players': players.length,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'totalAssists': totalAssists,
      'yellowCards': totalYellowCards,
      'matches': completedMatches,
    };
  }
}