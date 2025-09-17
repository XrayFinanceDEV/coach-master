import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/image_cache_provider.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class PlayerCardsGridOptimized extends ConsumerStatefulWidget {
  final List<Player> players;
  final List<Player> sortedByName;
  final String teamName;

  const PlayerCardsGridOptimized({
    super.key,
    required this.players,
    required this.sortedByName,
    required this.teamName,
  });

  @override
  ConsumerState<PlayerCardsGridOptimized> createState() => _PlayerCardsGridOptimizedState();
}

class _PlayerCardsGridOptimizedState extends ConsumerState<PlayerCardsGridOptimized> {
  String sortMode = 'position';
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = sortMode == 'position' 
        ? widget.players 
        : widget.sortedByName;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            
            if (sortedPlayers.isEmpty)
              _buildEmptyState(context)
            else ...[
              _buildPlayerCarousel(sortedPlayers),
              const SizedBox(height: 16),
              if ((sortedPlayers.length / 2).ceil() > 1)
                _buildDotIndicator(sortedPlayers),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '${AppLocalizations.of(context)!.players} - ${widget.teamName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              sortMode = sortMode == 'position' ? 'name' : 'position';
            });
          },
          icon: const Icon(Icons.sort, size: 16),
          label: Text(
            sortMode == 'position' 
                ? AppLocalizations.of(context)!.sortByName 
                : AppLocalizations.of(context)!.sortByPosition,
            style: const TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCarousel(List<Player> players) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemCount: (players.length / 2).ceil(),
        itemBuilder: (context, pageIndex) {
          final startIndex = pageIndex * 2;
          final endIndex = (startIndex + 2).clamp(0, players.length);
          final playersOnPage = players.sublist(startIndex, endIndex);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (int i = 0; i < playersOnPage.length; i++) ...[
                  Expanded(
                    child: OptimizedPlayerCard(player: playersOnPage[i]),
                  ),
                  if (i < playersOnPage.length - 1) const SizedBox(width: 12),
                ],
                if (playersOnPage.length == 1) const Expanded(child: SizedBox()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDotIndicator(List<Player> players) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        (players.length / 2).ceil(),
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          AppLocalizations.of(context)!.noPlayersInTeamYet,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

class OptimizedPlayerCard extends ConsumerWidget {
  final Player player;

  const OptimizedPlayerCard({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageProvider = ref.watch(playerImageProvider(player.id));

    return InkWell(
      onTap: () => context.go('/players/${player.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber, width: 2),
          color: Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    _buildPlayerImage(context, imageProvider),
                    _buildStatsOverlay(),
                    _buildGradientOverlay(),
                  ],
                ),
              ),
            ),
            
            Expanded(
              flex: 2,
              child: _buildPlayerInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerImage(BuildContext context, ImageProvider? imageProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        gradient: imageProvider == null ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ) : null,
      ),
      child: imageProvider != null
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlayerInitials(),
              ),
            )
          : _buildPlayerInitials(),
    );
  }

  Widget _buildPlayerInitials() {
    return Center(
      child: Text(
        '${player.firstName[0]}${player.lastName[0]}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return Positioned(
      top: 8,
      left: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatBadge('⚽ ${player.goals}'),
          const SizedBox(height: 4),
          _buildStatBadge('🎯 ${player.assists}'),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${player.firstName} ${player.lastName}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 1),
          Text(
            _formatBirthDate(player.birthDate),
            style: const TextStyle(fontSize: 9, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  player.position,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_getFootAbbreviation(player.preferredFoot).isNotEmpty) ...[
                Text(
                  ' (${_getFootAbbreviation(player.preferredFoot)})',
                  style: const TextStyle(fontSize: 9, color: Colors.black87),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatBirthDate(DateTime birthDate) {
    return '${birthDate.day.toString().padLeft(2, '0')}/${birthDate.month.toString().padLeft(2, '0')}/${birthDate.year}';
  }

  String _getFootAbbreviation(String preferredFoot) {
    final foot = preferredFoot.toLowerCase();
    if (foot.contains('right') || foot.contains('destro')) return 'R';
    if (foot.contains('left') || foot.contains('sinistro')) return 'L';
    if (foot.contains('both') || foot.contains('ambi')) return 'A';
    return '';
  }
}