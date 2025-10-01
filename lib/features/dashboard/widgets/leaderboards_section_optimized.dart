import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/image_cache_provider.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class LeaderboardsSectionOptimized extends ConsumerWidget {
  final List<Player> topScorers;
  final List<Player> topAssistors;
  final List<Player> topRated;

  const LeaderboardsSectionOptimized({
    super.key,
    required this.topScorers,
    required this.topAssistors,
    required this.topRated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        
        _buildLeaderboardCard(
          context,
          ref,
          title: AppLocalizations.of(context)!.topScorers,
          icon: Icons.sports_soccer,
          color: Colors.green,
          players: topScorers,
          getStatValue: (player) => player.goals.toString(),
          statLabel: 'goals',
        ),
        
        const SizedBox(height: 16),
        
        _buildLeaderboardCard(
          context,
          ref,
          title: AppLocalizations.of(context)!.topAssistors,
          icon: Icons.trending_up,
          color: Colors.deepOrange,
          players: topAssistors,
          getStatValue: (player) => player.assists.toString(),
          statLabel: 'assists',
        ),
        
        const SizedBox(height: 16),
        
        _buildLeaderboardCard(
          context,
          ref,
          title: AppLocalizations.of(context)!.highestRated,
          icon: Icons.star,
          color: Colors.amber,
          players: topRated,
          getStatValue: (player) => player.avgRating?.toStringAsFixed(1) ?? '0.0',
          statLabel: 'rating',
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Player> players,
    required String Function(Player) getStatValue,
    required String statLabel,
  }) {
    final filteredPlayers = players.where((player) {
      if (statLabel == 'goals') return player.goals > 0;
      if (statLabel == 'assists') return player.assists > 0;
      if (statLabel == 'rating') return player.avgRating != null && player.avgRating! > 0;
      return true;
    }).take(5).toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            if (filteredPlayers.isEmpty)
              _buildEmptyLeaderboard(context)
            else
              Column(
                children: filteredPlayers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  return OptimizedPlayerRow(
                    player: player,
                    position: index + 1,
                    statValue: getStatValue(player),
                    statLabel: statLabel,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard(BuildContext context) {
    return Center(
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
              AppLocalizations.of(context)!.noDataYetShort,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.statsWillAppearAfterMatches,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptimizedPlayerRow extends ConsumerWidget {
  final Player player;
  final int position;
  final String statValue;
  final String statLabel;

  const OptimizedPlayerRow({
    super.key,
    required this.player,
    required this.position,
    required this.statValue,
    required this.statLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageProviderAsync = ref.watch(playerImageProvider(player.id));

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

            imageProviderAsync.when(
              data: (imageProvider) => CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              loading: () => CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              error: (_, __) => CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Text(
                '${player.firstName} ${player.lastName}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            
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
        return Colors.amber[600]!;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return const Color(0xFFFF7F00);
    }
  }
}