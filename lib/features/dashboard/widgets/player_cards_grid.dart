import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_cache_utils.dart';
import 'dart:io';

class PlayerCardsGrid extends ConsumerStatefulWidget {
  final String teamId; // Changed: now takes teamId instead of players list
  final String teamName;

  const PlayerCardsGrid({
    super.key,
    required this.teamId, // Changed: pass teamId to get fresh data
    required this.teamName,
  });

  @override
  ConsumerState<PlayerCardsGrid> createState() => _PlayerCardsGridState();
}

class _PlayerCardsGridState extends ConsumerState<PlayerCardsGrid> {
  String sortMode = 'position'; // 'position' or 'name'
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get fresh player data directly from repository
    final playerRepository = ref.watch(playerRepositoryProvider);
    // Watch for image updates to force rebuilds
    ref.watch(playerImageUpdateProvider);
    final players = playerRepository.getPlayersForTeam(widget.teamId);
    final sortedPlayers = _sortPlayers(players);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    sortMode == 'position' ? AppLocalizations.of(context)!.sortByName : AppLocalizations.of(context)!.sortByPosition,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Players Carousel
            if (sortedPlayers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    AppLocalizations.of(context)!.noPlayersInTeamYet,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 180, // Reduced height for better mobile fit
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: (sortedPlayers.length / 2).ceil(), // Pages needed for 2 cards per page
                  itemBuilder: (context, pageIndex) {
                    final startIndex = pageIndex * 2;
                    final endIndex = (startIndex + 2).clamp(0, sortedPlayers.length);
                    final playersOnPage = sortedPlayers.sublist(startIndex, endIndex);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          for (int i = 0; i < playersOnPage.length; i++) ...[
                            Expanded(
                              child: _buildPlayerCard(context, playersOnPage[i]),
                            ),
                            if (i < playersOnPage.length - 1) const SizedBox(width: 12),
                          ],
                          // Add spacer if only one card on the page
                          if (playersOnPage.length == 1) const Expanded(child: SizedBox()),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Dots Indicator
              if ((sortedPlayers.length / 2).ceil() > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    (sortedPlayers.length / 2).ceil(),
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
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, Player player) {
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
            // Photo Section (takes most of the space)
            Expanded(
              flex: 4, // Reduced from 5 to 4 for better mobile fit
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    // Player Photo
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        gradient: player.photoPath == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                      ),
                      child: player.photoPath != null && player.photoPath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                              child: kIsWeb
                                  ? (player.photoPath!.startsWith('data:') || player.photoPath!.startsWith('blob:') || player.photoPath!.startsWith('http')
                                      ? Image.network(
                                          player.photoPath!,
                                          key: ValueKey(player.photoPath), // Force rebuild when photo changes
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('Failed to load web image: ${player.photoPath}, Error: $error');
                                            return _buildPlayerInitials(player);
                                          },
                                        )
                                      : _buildPlayerInitials(player)) // Web with file path - show initials
                                  : Image.file(
                                      File(player.photoPath!),
                                      key: ValueKey(player.photoPath), // Force rebuild when photo changes
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Failed to load file image: ${player.photoPath}, Error: $error');
                                        return Container(
                                          color: Colors.red[100],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.error, color: Colors.red),
                                              const SizedBox(height: 4),
                                              Text('Image\nError', 
                                                style: TextStyle(fontSize: 10, color: Colors.red[800]),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            )
                          : _buildPlayerInitials(player),
                    ),
                    
                    // Statistics Overlay (Top Left)
                    Positioned(
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
                    ),

                    // Gradient Overlay for text readability
                    Positioned(
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
                    ),
                  ],
                ),
              ),
            ),
            
            // Player Info Section (bottom)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(6), // Reduced padding
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
                    // Name
                    Text(
                      '${player.firstName} ${player.lastName}',
                      style: const TextStyle(
                        fontSize: 11, // Reduced from 12
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 1), // Reduced spacing
                    
                    // Birth Date
                    Text(
                      _formatBirthDate(player.birthDate),
                      style: const TextStyle(
                        fontSize: 9, // Reduced from 10
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 1), // Reduced spacing
                    
                    // Position and Foot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            player.position,
                            style: const TextStyle(
                              fontSize: 9, // Reduced from 10
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
                            style: const TextStyle(
                              fontSize: 9, // Reduced from 10
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInitials(Player player) {
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

  List<Player> _sortPlayers(List<Player> players) {
    final List<Player> sortedPlayers = List.from(players);
    
    if (sortMode == 'position') {
      // Sort by position priority
      final positionOrder = {
        'Goalkeeper': 1, 'Portiere': 1,
        'Defender': 2, 'Difensore': 2, 'Difensore centrale': 2, 'Terzino': 3,
        'Midfielder': 4, 'Mediano': 4, 'Centrocampista': 5, 'Regista': 6, 'Mezzala': 7,
        'Winger': 8, 'Fascia': 8, 'Esterno': 8,
        'Forward': 9, 'Attaccante': 9, 'Trequartista': 9, 'Seconda punta': 10, 'Punta': 11,
      };
      
      sortedPlayers.sort((a, b) {
        final orderA = positionOrder[a.position] ?? 99;
        final orderB = positionOrder[b.position] ?? 99;
        return orderA.compareTo(orderB);
      });
    } else {
      // Sort by last name
      sortedPlayers.sort((a, b) => a.lastName.compareTo(b.lastName));
    }
    
    return sortedPlayers;
  }
}