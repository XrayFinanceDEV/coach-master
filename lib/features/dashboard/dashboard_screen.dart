import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';
import 'package:coachmaster/features/dashboard/widgets/team_statistics_card.dart';
import 'package:coachmaster/features/dashboard/widgets/player_cards_grid.dart';
import 'package:coachmaster/features/dashboard/widgets/leaderboards_section.dart';
import 'package:coachmaster/features/players/widgets/player_form_bottom_sheet.dart';
import 'package:coachmaster/features/trainings/training_detail_screen.dart';
import 'package:coachmaster/features/matches/widgets/match_form_bottom_sheet.dart';
import 'package:coachmaster/widgets/sync_status_widget.dart';

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
    
    final seasons = seasonRepo.getSeasons() as List<Season>;
    if (seasons.isNotEmpty && selectedSeasonId == null) {
      selectedSeasonId = seasons.first.id;
      
      final teams = teamRepo.getTeamsForSeason(selectedSeasonId!) as List<Team>;
      if (teams.isNotEmpty && selectedTeamId == null) {
        selectedTeamId = teams.first.id;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if auth is still initializing - show loading screen instead of accessing repositories
    final authState = ref.watch(firebaseAuthProvider);
    if (authState.isInitializing) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading your dashboard...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Setting up your teams and players',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Watch refresh counter to rebuild when Firebase sync completes
    ref.watch(refreshCounterProvider);

    // Now safe to access repositories
    final seasonRepo = ref.watch(seasonRepositoryProvider);
    final teamRepo = ref.watch(teamRepositoryProvider);

    final seasons = seasonRepo.getSeasons() as List<Season>;
    final teams = selectedSeasonId != null ? teamRepo.getTeamsForSeason(selectedSeasonId!) as List<Team> : <Team>[];

    final selectedSeason = selectedSeasonId != null ? seasonRepo.getSeason(selectedSeasonId!) : null;
    final selectedTeam = selectedTeamId != null ? teamRepo.getTeam(selectedTeamId!) : null;

    // Auto-select defaults if they're not set but data is available
    if (seasons.isNotEmpty && selectedSeasonId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedSeasonId = seasons.first.id;
          // Get teams for the newly selected season
          final seasonTeams = teamRepo.getTeamsForSeason(seasons.first.id) as List<Team>;
          if (seasonTeams.isNotEmpty && selectedTeamId == null) {
            selectedTeamId = seasonTeams.first.id;
          }
        });
      });
    }

    // Get team data for dashboard
    final playerRepo = ref.watch(playerRepositoryProvider);
    final matchRepo = ref.watch(matchRepositoryProvider);
    final players = selectedTeamId != null ? playerRepo.getPlayersForTeam(selectedTeamId!) as List<Player> : <Player>[];
    final matches = selectedTeamId != null ? matchRepo.getMatchesForTeam(selectedTeamId!) as List<Match> : <Match>[];


    final result = Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Image.asset(
                'docs/logo_coachmaster.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Coach Master'),
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
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: SyncStatusWidget()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding for FAB
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (seasons.isEmpty) ...[
              _buildWelcomeMessage(),
            ] else if (selectedTeamId == null || selectedTeam == null) ...[
              // Show loading or team selection state instead of "empty teams"
              if (teams.isEmpty && seasons.isNotEmpty) ...[
                _buildEmptyTeamsMessage(),
              ] else ...[
                // Teams exist but none selected - show loading or selection
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading team data...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (selectedTeam != null && players.isNotEmpty) ...[
              TeamStatisticsCard(
                team: selectedTeam,
                players: players,
                matches: matches,
              ),
              const SizedBox(height: 16),

              PlayerCardsGrid(
                teamId: selectedTeam.id,
                teamName: selectedTeam.name,
              ),
              const SizedBox(height: 16),

              LeaderboardsSection(
                players: players,
                teamId: selectedTeam.id,
              ),
            ] else if (selectedTeam != null && players.isEmpty) ...[
              _buildEmptyPlayersMessage(),
            ],
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
    
    return result;
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
            
            // Add Training button
            _buildSpeedDialChild(
              icon: Icons.fitness_center,
              label: AppLocalizations.of(context)!.addTraining,
              onTap: () => _showAddTrainingDialog(),
            ),
            
            // Add Player button
            _buildSpeedDialChild(
              icon: Icons.person_add,
              label: AppLocalizations.of(context)!.addPlayer,
              onTap: () => _showAddPlayerDialog(),
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: 180,
        child: FilledButton.icon(
          onPressed: () {
            setState(() {
              _isSpeedDialOpen = false;
            });
            onTap();
          },
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  void _showAddPlayerDialog() {
    if (selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team first!')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlayerFormBottomSheet(
        teamId: selectedTeamId!,
        onSaved: () {
          // Refresh dashboard data
          ref.read(refreshCounterProvider.notifier).increment();
          // Navigate to players screen
          context.go('/players');
        },
      ),
    );
  }

  void _showAddTrainingDialog() {
    if (selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team first!')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TrainingFormBottomSheet(
        teamId: selectedTeamId!,
        onSaved: () {
          // Refresh dashboard data
          ref.read(refreshCounterProvider.notifier).increment();
        },
        onTrainingCreated: (trainingId) {
          // Navigate directly to training detail
          context.go('/trainings/$trainingId');
        },
      ),
    );
  }

  void _showAddMatchDialog() {
    if (selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team first!')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MatchFormBottomSheet(
        teamId: selectedTeamId!,
        onSaved: () {
          // Refresh dashboard data
          ref.read(refreshCounterProvider.notifier).increment();
        },
        onMatchCreated: (matchId) {
          // Navigate directly to match detail for convocation management
          context.go('/matches/$matchId');
        },
      ),
    );
  }
}