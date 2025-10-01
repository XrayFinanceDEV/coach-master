import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';
import 'package:coachmaster/core/selected_team_provider.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';
import 'package:coachmaster/features/dashboard/widgets/team_statistics_card.dart';
import 'package:coachmaster/features/dashboard/widgets/player_cards_grid.dart';
import 'package:coachmaster/features/dashboard/widgets/leaderboards_section.dart';
import 'package:coachmaster/features/players/widgets/player_form_bottom_sheet.dart';
import 'package:coachmaster/features/matches/widgets/match_form_bottom_sheet.dart';
// Legacy sync_manager removed - using Firestore-only architecture now

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSpeedDialOpen = false;
  bool _isRefreshing = false;

  Future<void> _forceRefreshData() async {
    setState(() => _isRefreshing = true);

    try {
      final authState = ref.read(firebaseAuthProvider);

      if (authState.isUsingFirebaseAuth) {
        // Firestore streams automatically sync data in real-time
        // No manual download needed - just wait a moment for streams to update
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.dataSyncedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorSyncingData}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
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
                AppLocalizations.of(context)!.loadingDashboard,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.settingUpTeams,
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

    // Trigger auto-select if needed
    ref.watch(autoSelectTeamProvider);

    // Use the stream-based selected team provider
    final selectedTeamAsync = ref.watch(selectedTeamStreamProvider);

    return selectedTeamAsync.when(
      data: (selectedTeam) => _buildDashboardContent(selectedTeam),
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(child: Text('${AppLocalizations.of(context)!.error}: $error')),
      ),
    );
  }

  Widget _buildDashboardContent(Team? selectedTeam) {
    final selectedTeamId = selectedTeam?.id;

    // Watch streams for players and matches
    final playersAsync = selectedTeamId != null
        ? ref.watch(playersForTeamStreamProvider(selectedTeamId))
        : const AsyncValue<List<Player>>.data([]);
    final matchesAsync = selectedTeamId != null
        ? ref.watch(matchesForTeamStreamProvider(selectedTeamId))
        : const AsyncValue<List<Match>>.data([]);

    return playersAsync.when(
      data: (players) => matchesAsync.when(
        data: (matches) => _buildScaffold(selectedTeam, players, matches),
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Center(child: Text('Error loading matches: $error')),
        ),
      ),
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(child: Text('Error loading players: $error')),
      ),
    );
  }

  Widget _buildScaffold(Team? selectedTeam, List<Player> players, List<Match> matches) {
    return Scaffold(
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
            if (selectedTeam != null) ...[
              const Text(' — '),
              Text(
                selectedTeam.name,
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
          // Sync/Refresh button for Firebase users
          if (ref.watch(firebaseAuthProvider).isUsingFirebaseAuth)
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              onPressed: _isRefreshing ? null : _forceRefreshData,
              tooltip: AppLocalizations.of(context)!.syncData,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding for FAB
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (selectedTeam == null) ...[
              _buildWelcomeMessage(),
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
      floatingActionButton: _buildSpeedDial(selectedTeam),
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

  Widget _buildSpeedDial(Team? selectedTeam) {
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
    final selectedTeamId = ref.read(selectedTeamIdProvider);

    if (selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectTeamFirst)),
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
        teamId: selectedTeamId,
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
    final selectedTeamId = ref.read(selectedTeamIdProvider);

    if (selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectTeamFirst)),
      );
      return;
    }

    // Navigate to trainings screen where user can add training
    context.go('/trainings');
  }

  void _showAddMatchDialog() {
    final selectedTeamId = ref.read(selectedTeamIdProvider);

    if (selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectTeamFirst)),
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
        teamId: selectedTeamId,
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