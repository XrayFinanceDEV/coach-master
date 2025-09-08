import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/features/dashboard/widgets/team_statistics_card.dart';
import 'package:coachmaster/features/dashboard/widgets/player_cards_grid.dart';
import 'package:coachmaster/features/dashboard/widgets/leaderboards_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? selectedSeasonId;
  String? selectedTeamId;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    // Auto-select the first available season and team
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectDefaults();
    });
  }

  void _autoSelectDefaults() {
    final seasonRepo = ref.read(seasonRepositoryProvider);
    final teamRepo = ref.read(teamRepositoryProvider);
    
    final seasons = seasonRepo.getSeasons();
    if (seasons.isNotEmpty && selectedSeasonId == null) {
      selectedSeasonId = seasons.first.id;
      
      final teams = teamRepo.getTeamsForSeason(selectedSeasonId!);
      if (teams.isNotEmpty && selectedTeamId == null) {
        selectedTeamId = teams.first.id;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonRepo = ref.watch(seasonRepositoryProvider);
    final teamRepo = ref.watch(teamRepositoryProvider);
    final playerRepo = ref.watch(playerRepositoryProvider);
    final matchRepo = ref.watch(matchRepositoryProvider);

    final seasons = seasonRepo.getSeasons();
    final teams = selectedSeasonId != null ? teamRepo.getTeamsForSeason(selectedSeasonId!) : <Team>[];
    final players = selectedTeamId != null ? playerRepo.getPlayersForTeam(selectedTeamId!) : <Player>[];
    final matches = selectedTeamId != null && selectedSeasonId != null 
        ? matchRepo.getMatchesForTeam(selectedTeamId!) : <Match>[];

    final selectedSeason = selectedSeasonId != null ? seasonRepo.getSeason(selectedSeasonId!) : null;
    final selectedTeam = selectedTeamId != null ? teamRepo.getTeam(selectedTeamId!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.home, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.home),
            if (selectedSeason != null) ...[
              const Text(' — '),
              Text(
                '${AppLocalizations.of(context)!.season} ${selectedSeason.name}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding for FAB
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (teams.isEmpty && seasons.isNotEmpty) ...[
              // No teams message
              _buildEmptyTeamsMessage(),
            ] else if (selectedTeam != null && players.isNotEmpty) ...[
              // Team Statistics Overview
              TeamStatisticsCard(
                team: selectedTeam,
                players: players,
                matches: matches,
              ),
              const SizedBox(height: 16),

              // Player Cards Grid
              PlayerCardsGrid(
                teamId: selectedTeamId!,
                teamName: selectedTeam.name,
              ),
              const SizedBox(height: 16),

              // Top 5 Leaderboards
              LeaderboardsSection(
                players: players,
                teamId: selectedTeamId!,
              ),
            ] else if (selectedTeam != null && players.isEmpty) ...[
              // No players message
              _buildEmptyPlayersMessage(),
            ] else if (seasons.isEmpty) ...[
              // Welcome message
              _buildWelcomeMessage(),
            ],
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.welcomeTo(AppLocalizations.of(context)!.appTitle),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createFirstSeasonAndTeam,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTeamsMessage() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.groups,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTeamsInSeason,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createFirstTeam,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlayersMessage() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.people,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noPlayersInTeam,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addFirstPlayer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSpeedDialOpen) ...[
            // Add Match button
            _buildSpeedDialChild(
              icon: Icons.sports_soccer,
              label: AppLocalizations.of(context)!.addMatch,
              onTap: () => _showAddMatchDialog(),
            ),
            const SizedBox(height: 16),
            
            // Add Training button
            _buildSpeedDialChild(
              icon: Icons.fitness_center,
              label: AppLocalizations.of(context)!.addTraining,
              onTap: () => _showAddTrainingDialog(),
            ),
            const SizedBox(height: 16),
            
            // Add Player button
            _buildSpeedDialChild(
              icon: Icons.person_add,
              label: AppLocalizations.of(context)!.addPlayer,
              onTap: () => _showAddPlayerDialog(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Main FAB
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isSpeedDialOpen = !_isSpeedDialOpen;
              });
            },
            child: AnimatedRotation(
              turns: _isSpeedDialOpen ? 0.125 : 0, // 45 degree rotation when open
              duration: const Duration(milliseconds: 300),
              child: Icon(_isSpeedDialOpen ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialChild({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: label, // Unique tag for each FAB
          onPressed: () {
            setState(() {
              _isSpeedDialOpen = false;
            });
            onTap();
          },
          child: Icon(icon),
        ),
      ],
    );
  }

  void _showAddPlayerDialog() {
    // Implementation will be similar to the one in PlayersScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Player - Coming soon!')),
    );
  }

  void _showAddTrainingDialog() {
    // Implementation will be similar to the one in TrainingsScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Training - Coming soon!')),
    );
  }

  void _showAddMatchDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Match - Coming soon!')),
    );
  }
}