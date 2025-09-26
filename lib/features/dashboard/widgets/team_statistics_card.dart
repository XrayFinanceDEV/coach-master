import 'package:flutter/material.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match.dart';

class TeamStatisticsCard extends StatefulWidget {
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
  State<TeamStatisticsCard> createState() => _TeamStatisticsCardState();
}

class _TeamStatisticsCardState extends State<TeamStatisticsCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
                  '${AppLocalizations.of(context)!.teamStatistics} - ${widget.team.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats Carousel
            SizedBox(
              height: 280, // Increased height for 2x2 layout
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // Page 1: Key Match Stats
                  _buildStatsPage([
                    _StatsData(
                      icon: Icons.sports,
                      label: AppLocalizations.of(context)!.matches,
                      value: teamStats['matches']!.toString(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _StatsData(
                      icon: Icons.percent,
                      label: AppLocalizations.of(context)!.winRate,
                      value: '${teamStats['winRate']!}%',
                      color: Colors.blue,
                    ),
                    _StatsData(
                      icon: Icons.emoji_events,
                      label: AppLocalizations.of(context)!.wins,
                      value: teamStats['wins']!.toString(),
                      color: Colors.green,
                    ),
                    _StatsData(
                      icon: Icons.trending_down,
                      label: AppLocalizations.of(context)!.losses,
                      value: teamStats['losses']!.toString(),
                      color: Colors.red,
                    ),
                  ]),

                  // Page 2: Goals & Advanced Stats
                  _buildStatsPage([
                    _StatsData(
                      icon: Icons.sports_soccer,
                      label: AppLocalizations.of(context)!.goalsFor,
                      value: teamStats['goalsFor']!.toString(),
                      color: Colors.green,
                    ),
                    _StatsData(
                      icon: Icons.shield,
                      label: AppLocalizations.of(context)!.goalsAgainst,
                      value: teamStats['goalsAgainst']!.toString(),
                      color: Colors.red,
                    ),
                    _StatsData(
                      icon: Icons.compare_arrows,
                      label: AppLocalizations.of(context)!.goalDifference,
                      value: teamStats['goalDiff']!.toString(),
                      color: teamStats['goalDiff'] >= 0 ? Colors.green : Colors.red,
                    ),
                    _StatsData(
                      icon: Icons.handshake,
                      label: AppLocalizations.of(context)!.draws,
                      value: teamStats['draws']!.toString(),
                      color: Colors.orange,
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 2; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPage(List<_StatsData> stats) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          // First Row
          Row(
            children: [
              Expanded(child: _buildMiniStatCard(
                context,
                icon: stats[0].icon,
                label: stats[0].label,
                value: stats[0].value,
                color: stats[0].color,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStatCard(
                context,
                icon: stats[1].icon,
                label: stats[1].label,
                value: stats[1].value,
                color: stats[1].color,
              )),
            ],
          ),
          const SizedBox(height: 8),

          // Second Row
          Row(
            children: [
              Expanded(child: _buildMiniStatCard(
                context,
                icon: stats[2].icon,
                label: stats[2].label,
                value: stats[2].value,
                color: stats[2].color,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniStatCard(
                context,
                icon: stats[3].icon,
                label: stats[3].label,
                value: stats[3].value,
                color: stats[3].color,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateTeamStats() {
    // Calculate goals for/against from completed matches
    int goalsFor = 0;
    int goalsAgainst = 0;
    final completedMatches = widget.matches.where((m) => m.status == MatchStatus.completed).toList();
    final wins = completedMatches.where((m) => m.result == MatchResult.win).length;
    final draws = completedMatches.where((m) => m.result == MatchResult.draw).length;
    final losses = completedMatches.where((m) => m.result == MatchResult.loss).length;

    for (final match in completedMatches) {
      if (match.goalsFor != null && match.goalsAgainst != null) {
        goalsFor += match.goalsFor!.toInt();
        goalsAgainst += match.goalsAgainst!.toInt();
      }
    }

    // Calculate player statistics
    final totalAssists = widget.players.fold(0, (sum, player) => sum + player.assists);
    final totalYellowCards = widget.players.fold(0, (sum, player) => sum + player.yellowCards);

    return {
      'players': widget.players.length,
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

class _StatsData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _StatsData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}