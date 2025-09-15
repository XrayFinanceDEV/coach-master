import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_cache_utils.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/features/players/widgets/player_form_bottom_sheet.dart';

class PlayerListScreen extends ConsumerStatefulWidget {
  final String teamId;
  const PlayerListScreen({super.key, required this.teamId});

  @override
  ConsumerState<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends ConsumerState<PlayerListScreen> {
  String _selectedFilter = 'all'; // all, attack, midfield, defense

  @override
  Widget build(BuildContext context) {
    ref.watch(refreshCounterProvider);
    final localizations = AppLocalizations.of(context);
    // Watch for image updates to force rebuilds
    ref.watch(playerImageUpdateProvider);
    final allPlayers = ref.watch(playersForTeamProvider(widget.teamId));

    // Filter and organize players by position
    final filteredPlayers = _getFilteredPlayers(allPlayers);
    final organizedPlayers = _organizePlayersByPosition(filteredPlayers);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(localizations?.players ?? 'Players'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter buttons
          _buildFilterButtons(context),
          // Players grid
          Expanded(
            child: _buildPlayersGrid(context, organizedPlayers),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => PlayerFormBottomSheet(
              teamId: widget.teamId,
              onSaved: () {
                ref.read(refreshCounterProvider.notifier).increment();
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              context,
              'all',
              _getLocalizedFilterLabel(context, 'all'),
              Icons.people,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              context,
              'attack',
              _getLocalizedFilterLabel(context, 'attack'),
              Icons.sports_soccer,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              context,
              'midfield',
              _getLocalizedFilterLabel(context, 'midfield'),
              Icons.timeline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              context,
              'defense',
              _getLocalizedFilterLabel(context, 'defense'),
              Icons.shield,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedFilterLabel(BuildContext context, String filterKey) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    
    if (currentLocale == 'it') {
      switch (filterKey) {
        case 'all':
          return 'Tutti';
        case 'attack':
          return 'Attacco';
        case 'midfield':
          return 'Centrocampo';
        case 'defense':
          return 'Difesa';
        default:
          return 'Tutti';
      }
    } else {
      // English labels
      switch (filterKey) {
        case 'all':
          return 'All Players';
        case 'attack':
          return 'Attack';
        case 'midfield':
          return 'Midfield';
        case 'defense':
          return 'Defense';
        default:
          return 'All Players';
      }
    }
  }

  Widget _buildFilterChip(BuildContext context, String filterKey, String label, IconData icon) {
    final isSelected = _selectedFilter == filterKey;
    return FilledButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      style: FilledButton.styleFrom(
        backgroundColor: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        foregroundColor: isSelected 
            ? Colors.white 
            : Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Player> _getFilteredPlayers(List<Player> players) {
    if (_selectedFilter == 'all') return players;
    
    return players.where((player) {
      final position = player.position.toLowerCase();
      
      switch (_selectedFilter) {
        case 'attack':
          return position.contains('attaccante') ||
                 position.contains('trequartista') ||
                 position.contains('ala') ||
                 position.contains('punta') ||
                 // English equivalents
                 position.contains('forward') || 
                 position.contains('striker') ||
                 position.contains('attacker') ||
                 position.contains('winger');
        
        case 'midfield':
          return position.contains('centrocampista') ||
                 position.contains('mediano') ||
                 // English equivalents
                 position.contains('midfield') || 
                 position.contains('midfielder') ||
                 position.contains('attacking midfielder') ||
                 position.contains('defensive midfielder') ||
                 position.contains('central midfielder');
        
        case 'defense':
          return position.contains('difensore') ||
                 position.contains('terzino') ||
                 position.contains('quinto') ||
                 position.contains('portiere') ||
                 // English equivalents
                 position.contains('defender') || 
                 position.contains('back') ||
                 position.contains('center back') ||
                 position.contains('centre back') ||
                 position.contains('goalkeeper') ||
                 position.contains('fullback') ||
                 position.contains('wingback');
        
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<Player>> _organizePlayersByPosition(List<Player> players) {
    if (_selectedFilter != 'all') {
      return {'filtered': players};
    }

    final attack = <Player>[];
    final midfield = <Player>[];
    final defense = <Player>[];

    for (final player in players) {
      final position = player.position.toLowerCase();
      
      // Attacco group (Italian terms prioritized)
      if (position.contains('attaccante') ||
          position.contains('trequartista') ||
          position.contains('ala') ||
          position.contains('punta') ||
          // English equivalents
          position.contains('forward') || 
          position.contains('striker') ||
          position.contains('attacker') ||
          position.contains('winger')) {
        attack.add(player);
      } 
      // Centro Campo group (Italian terms prioritized)  
      else if (position.contains('centrocampista') ||
               position.contains('mediano') ||
               // English equivalents
               position.contains('midfield') || 
               position.contains('midfielder')) {
        midfield.add(player);
      } 
      // Difesa group (Italian terms prioritized) - catch all remaining players here
      else {
        // All remaining players go to defense (including goalkeeper, defenders, and any unrecognized positions)
        defense.add(player);
      }
    }

    // Sort each group by specific position hierarchy
    attack.sort((a, b) => _getAttackPositionOrder(a.position).compareTo(_getAttackPositionOrder(b.position)));
    midfield.sort((a, b) => _getMidfieldPositionOrder(a.position).compareTo(_getMidfieldPositionOrder(b.position)));
    defense.sort((a, b) => _getDefensePositionOrder(a.position).compareTo(_getDefensePositionOrder(b.position)));

    return {
      _getLocalizedSectionName(context, 'attack'): attack,
      _getLocalizedSectionName(context, 'midfield'): midfield,
      _getLocalizedSectionName(context, 'defense'): defense,
    };
  }

  String _getLocalizedSectionName(BuildContext context, String section) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    
    if (currentLocale == 'it') {
      switch (section) {
        case 'attack':
          return 'Attacco';
        case 'midfield':
          return 'Centro Campo';
        case 'defense':
          return 'Difesa';
        default:
          return 'Altro';
      }
    } else {
      // English section names
      switch (section) {
        case 'attack':
          return 'Attack';
        case 'midfield':
          return 'Midfield';
        case 'defense':
          return 'Defense';
        default:
          return 'Other';
      }
    }
  }

  String _getLocalizedPlayerCount(BuildContext context, int count) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    
    if (currentLocale == 'it') {
      return count == 1 ? '$count giocatore' : '$count giocatori';
    } else {
      return count == 1 ? '$count player' : '$count players';
    }
  }

  int _getAttackPositionOrder(String position) {
    final pos = position.toLowerCase();
    if (pos.contains('attaccante')) return 1;
    if (pos.contains('trequartista')) return 2;
    if (pos.contains('ala sinistra')) return 3;
    if (pos.contains('ala destra')) return 4;
    if (pos.contains('ala')) return 5;
    if (pos.contains('punta')) return 6;
    // English fallbacks
    if (pos.contains('striker')) return 1;
    if (pos.contains('winger')) return 5;
    if (pos.contains('forward')) return 6;
    return 99; // Other attacking positions
  }

  int _getMidfieldPositionOrder(String position) {
    final pos = position.toLowerCase();
    if (pos.contains('centrocampista centrale')) return 1;
    if (pos.contains('centrocampista')) return 2;
    if (pos.contains('mediano')) return 3;
    // English fallbacks
    if (pos.contains('central midfielder')) return 1;
    if (pos.contains('attacking midfielder')) return 2;
    if (pos.contains('defensive midfielder')) return 3;
    if (pos.contains('midfielder')) return 2;
    return 99; // Other midfield positions
  }

  int _getDefensePositionOrder(String position) {
    final pos = position.toLowerCase();
    if (pos.contains('portiere')) return 0; // Goalkeeper first
    if (pos.contains('difensore centrale')) return 1;
    if (pos.contains('difensore')) return 2;
    if (pos.contains('terzino sinistro')) return 3;
    if (pos.contains('terzino destro')) return 4;
    if (pos.contains('terzino')) return 5;
    if (pos.contains('quinto')) return 6;
    // English fallbacks
    if (pos.contains('goalkeeper')) return 0;
    if (pos.contains('center back')) return 1;
    if (pos.contains('centre back')) return 1;
    if (pos.contains('fullback')) return 5;
    if (pos.contains('wingback')) return 6;
    if (pos.contains('defender')) return 2;
    return 99; // Other defensive positions
  }

  Widget _buildPlayersGrid(BuildContext context, Map<String, List<Player>> organizedPlayers) {
    if (organizedPlayers.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: organizedPlayers.entries.map((entry) {
        return _buildPositionSection(context, entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildPositionSection(BuildContext context, String sectionTitle, List<Player> players) {
    if (players.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTitle != 'filtered') ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(sectionTitle),
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  _getLocalizedPlayerCount(context, players.length),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        _buildPlayerCardsGrid(players),
        const SizedBox(height: 8),
      ],
    );
  }

  IconData _getSectionIcon(String section) {
    // Handle both Italian and English section names
    switch (section) {
      case 'Attacco':
      case 'Attack':
        return Icons.sports_soccer;
      case 'Centro Campo':
      case 'Midfield':
        return Icons.timeline;
      case 'Difesa':
      case 'Defense':
        return Icons.shield;
      default:
        return Icons.people;
    }
  }

  Widget _buildPlayerCardsGrid(List<Player> players) {
    final rows = <Widget>[];
    
    for (int i = 0; i < players.length; i += 2) {
      final playersInRow = players.sublist(i, (i + 2).clamp(0, players.length));
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: _PlayerCard(player: playersInRow[0]),
              ),
              if (playersInRow.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _PlayerCard(player: playersInRow[1]),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    
    return Column(children: rows);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No players found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add players to your team to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends ConsumerWidget {
  final Player player;

  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch image updates to trigger rebuilds when player photos change

    return InkWell(
      onTap: () => context.go('/players/${player.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          color: Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    _buildPlayerImage(context),
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

  Widget _buildPlayerImage(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        gradient: (player.photoPath == null || player.photoPath!.isEmpty) ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ) : null,
      ),
      child: (player.photoPath != null && player.photoPath!.isNotEmpty)
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: Image(
                image: kIsWeb && (player.photoPath!.startsWith('data:') || player.photoPath!.startsWith('blob:') || player.photoPath!.startsWith('http'))
                    ? NetworkImage(player.photoPath!) as ImageProvider
                    : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider : NetworkImage(player.photoPath!)),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            _formatBirthDate(player.birthDate),
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  player.position,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_getFootAbbreviation(player.preferredFoot).isNotEmpty) ...[
                Text(
                  ' (${_getFootAbbreviation(player.preferredFoot)})',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
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
