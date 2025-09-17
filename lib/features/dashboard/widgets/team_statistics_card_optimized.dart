import 'package:flutter/material.dart';
import 'package:coachmaster/models/dashboard_data.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class TeamStatisticsCardOptimized extends StatelessWidget {
  final TeamStatistics teamStats;
  final String teamName;

  const TeamStatisticsCardOptimized({
    super.key,
    required this.teamStats,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    final statsMap = teamStats.toMap();

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
                  '${AppLocalizations.of(context)!.teamStatistics} - $teamName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.sports,
                  label: 'Matches',
                  value: statsMap['matches']!.toString(),
                  color: Theme.of(context).colorScheme.primary,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.emoji_events,
                  label: 'Wins',
                  value: statsMap['wins']!.toString(),
                  color: Colors.green,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.handshake,
                  label: 'Draws',
                  value: statsMap['draws']!.toString(),
                  color: Colors.orange,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.trending_down,
                  label: 'Losses',
                  value: statsMap['losses']!.toString(),
                  color: Colors.red,
                )),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.sports_soccer,
                  label: 'Goals For',
                  value: statsMap['goalsFor']!.toString(),
                  color: Colors.green,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.shield,
                  label: 'Goals Against', 
                  value: statsMap['goalsAgainst']!.toString(),
                  color: Colors.red,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.compare_arrows,
                  label: 'Goal Diff',
                  value: statsMap['goalDiff']!.toString(),
                  color: statsMap['goalDiff'] >= 0 ? Colors.green : Colors.red,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.percent,
                  label: 'Win Rate',
                  value: '${statsMap['winRate']!}%',
                  color: Colors.blue,
                )),
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
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}