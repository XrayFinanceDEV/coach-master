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
            
            // First Row - Match Statistics
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.sports,
                  label: 'Matches',
                  value: teamStats['matches']!.toString(),
                  color: Theme.of(context).colorScheme.primary,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.emoji_events,
                  label: 'Wins',
                  value: teamStats['wins']!.toString(),
                  color: Colors.green,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.handshake,
                  label: 'Draws',
                  value: teamStats['draws']!.toString(),
                  color: Colors.orange,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.trending_down,
                  label: 'Losses',
                  value: teamStats['losses']!.toString(),
                  color: Colors.red,
                )),
              ],
            ),
            const SizedBox(height: 12),
            
            // Second Row - Goals and Stats
            Row(
              children: [
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.sports_soccer,
                  label: 'Goals For',
                  value: teamStats['goalsFor']!.toString(),
                  color: Colors.green,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.shield,
                  label: 'Goals Against', 
                  value: teamStats['goalsAgainst']!.toString(),
                  color: Colors.red,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.compare_arrows,
                  label: 'Goal Diff',
                  value: teamStats['goalDiff']!.toString(),
                  color: teamStats['goalDiff'] >= 0 ? Colors.green : Colors.red,
                )),
                Expanded(child: _buildStatCard(
                  context,
                  icon: Icons.percent,
                  label: 'Win Rate',
                  value: '${teamStats['winRate']!}%',
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
          Icon(
            icon,
            color: color,
            size: 24,
          ),
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

  Map<String, dynamic> _calculateTeamStats() {
    // Calculate goals for/against from completed matches
    int goalsFor = 0;
    int goalsAgainst = 0;
    final completedMatches = matches.where((m) => m.status == MatchStatus.completed).toList();
    final wins = completedMatches.where((m) => m.result == MatchResult.win).length;
    final draws = completedMatches.where((m) => m.result == MatchResult.draw).length;
    final losses = completedMatches.where((m) => m.result == MatchResult.loss).length;

    for (final match in completedMatches) {
      if (match.goalsFor != null && match.goalsAgainst != null) {
        goalsFor += match.goalsFor!;
        goalsAgainst += match.goalsAgainst!;
      }
    }

    // Calculate player statistics
    final totalAssists = players.fold(0, (sum, player) => sum + player.assists);
    final totalYellowCards = players.fold(0, (sum, player) => sum + player.yellowCards);

    return {
      'players': players.length,
      'matches': completedMatches.length,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDiff': goalsFor - goalsAgainst,
      'winRate': completedMatches.isNotEmpty ? ((wins / completedMatches.length * 100).round()) : 0,
      'totalAssists': totalAssists,
      'yellowCards': totalYellowCards,
    };
  }
}