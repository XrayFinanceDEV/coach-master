import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/features/seasons/season_list_screen.dart';
import 'package:coachmaster/features/seasons/season_detail_screen.dart';
import 'package:coachmaster/features/teams/team_detail_screen.dart';
import 'package:coachmaster/features/players/player_detail_screen.dart';
import 'package:coachmaster/features/players/player_list_screen.dart';
import 'package:coachmaster/features/trainings/training_list_screen.dart';
import 'package:coachmaster/features/trainings/training_detail_screen.dart';
import 'package:coachmaster/features/matches/match_list_screen.dart';
import 'package:coachmaster/features/matches/match_detail_screen.dart';
import 'package:coachmaster/features/dashboard/dashboard_screen.dart';
import 'package:coachmaster/features/auth/login_screen.dart';
import 'package:coachmaster/features/onboarding/onboarding_screen.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/locale_provider.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';
import 'package:coachmaster/core/app_initialization.dart';
import 'package:coachmaster/core/selected_team_provider.dart';
import 'package:coachmaster/models/auth_state.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/services/analytics_service.dart';

// GoRouter refresh stream to listen to auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (dynamic data) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Enhanced Dashboard Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const DashboardScreen();
}

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});
  
  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch refresh counter to rebuild when teams are created/updated
    ref.watch(refreshCounterProvider);

    // Trigger auto-select if needed
    ref.watch(autoSelectTeamProvider);

    // Use the globally selected team
    final selectedTeam = ref.watch(selectedTeamProvider);

    if (selectedTeam == null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.players),
            ],
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_add, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('No team selected. Please create or select a team.'),
            ],
          ),
        ),
      );
    }

    // Use team ID directly without waiting for team object
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    return PlayerListScreen(teamId: selectedTeamId ?? '');
  }
}

class TrainingsScreen extends ConsumerStatefulWidget {
  const TrainingsScreen({super.key});
  @override
  ConsumerState<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends ConsumerState<TrainingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Trigger auto-select if needed
    ref.watch(autoSelectTeamProvider);

    // Use the globally selected team
    final selectedTeam = ref.watch(selectedTeamProvider);

    if (selectedTeam == null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.trainingSessions),
            ],
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_add, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('No team selected. Please create or select a team.'),
            ],
          ),
        ),
      );
    }

    // Use team ID directly without waiting for team object
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    return TrainingListScreen(teamId: selectedTeamId ?? '');
  }
}

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});
  
  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  @override
  Widget build(BuildContext context) {
    // Trigger auto-select if needed
    ref.watch(autoSelectTeamProvider);

    // Use the globally selected team
    final selectedTeam = ref.watch(selectedTeamProvider);

    if (selectedTeam == null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.sports_soccer, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Matches'),
            ],
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_add, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('No team selected. Please create or select a team.'),
            ],
          ),
        ),
      );
    }

    // Use team ID directly without waiting for team object
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    return MatchListScreen(teamId: selectedTeamId ?? '');
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? selectedSeasonId;
  String? selectedTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSelections();
    });
  }

  void _loadCurrentSelections() async {
    final seasonRepo = ref.read(seasonRepositoryProvider);
    final teamRepo = ref.read(teamRepositoryProvider);

    if (kDebugMode) {
      print('🔧 Settings: Loading current selections');
      print('🔧 Settings: Season repo type: ${seasonRepo.runtimeType}');
      print('🔧 Settings: Team repo type: ${teamRepo.runtimeType}');
    }

    // Look for 2025-26 season or create it if it doesn't exist
    var seasons = await seasonRepo.getSeasons();
    if (kDebugMode) {
      print('🔧 Settings: Found ${seasons.length} seasons');
      for (var season in seasons) {
        print('🔧 Settings: Season: ${season.name} (ID: ${season.id})');
      }
    }

    // Find the season that has teams (prioritize seasons with teams)
    Season? currentSeason;
    for (var season in seasons.where((s) => s.name == '2025-26')) {
      final teamsInSeason = await teamRepo.getTeamsForSeason(season.id);
      if (kDebugMode) {
        print('🔧 Settings: Season ${season.id} has ${teamsInSeason.length} teams');
      }
      if (teamsInSeason.isNotEmpty) {
        currentSeason = season;
        if (kDebugMode) {
          print('🔧 Settings: Selected season with teams: ${season.id}');
        }
        break;
      }
    }

    // If no season with teams found, pick the first one
    currentSeason ??= seasons.cast<Season?>().firstWhere(
      (s) => s?.name == '2025-26',
      orElse: () => null,
    );

    if (kDebugMode) {
      print('🔧 Settings: Current season found: ${currentSeason?.name}');
    }

    if (currentSeason == null) {
      // Create the default 2025-26 season
      currentSeason = Season.create(
        name: '2025-26',
        startDate: DateTime(2025, 7, 1), // July 1, 2025
        endDate: DateTime(2026, 6, 30),  // June 30, 2026
      );
      await seasonRepo.addSeason(currentSeason);
      if (kDebugMode) {
        print('🔧 Settings: Created new season: ${currentSeason.name} (ID: ${currentSeason.id})');
      }
    }

    selectedSeasonId = currentSeason.id;
    if (kDebugMode) {
      print('🔧 Settings: Set selectedSeasonId to: $selectedSeasonId');
    }

    final teams = await teamRepo.getTeamsForSeason(selectedSeasonId!);
    if (kDebugMode) {
      print('🔧 Settings: Found ${teams.length} teams for season');
      for (var team in teams) {
        print('🔧 Settings: Team: ${team.name} (ID: ${team.id})');
      }
    }

    if (teams.isNotEmpty) {
      selectedTeamId = teams.first.id;
      if (kDebugMode) {
        print('🔧 Settings: Set selectedTeamId to: $selectedTeamId');
      }
    }

    if (mounted) {
      setState(() {});
      if (kDebugMode) {
        print('🔧 Settings: UI updated - selectedSeasonId: $selectedSeasonId, selectedTeamId: $selectedTeamId');
      }
    }
  }

  Future<void> _confirmDeleteTeam(BuildContext context, Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team.name}"? This will also delete all players, trainings, matches, and statistics for this team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamRepo = ref.read(teamRepositoryProvider);
        await teamRepo.deleteTeam(team.id);

        // TODO: Also delete related data (players, trainings, matches, etc.)
        // This should be handled by the repository or a cleanup service

        // Increment refresh counter to trigger UI rebuilds
        ref.read(refreshCounterProvider.notifier).increment();

        // If the deleted team was selected, clear the selection
        if (selectedTeamId == team.id) {
          setState(() {
            selectedTeamId = null;
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Team "${team.name}" deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCreateTeamDialog(String seasonId) {
    final teamRepository = ref.read(teamRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String teamName = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.groups,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create New Team',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Form
                  Form(
                    key: formKey,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_soccer),
                      ),
                      validator: (value) => value!.isEmpty ? 'Team name is required' : null,
                      onSaved: (value) => teamName = value!,
                      autofocus: true,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              
                              // Store context before async operation
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              
                              final newTeam = Team.create(
                                name: teamName,
                                seasonId: seasonId,
                              );
                              
                              await teamRepository.addTeam(newTeam);
                              
                              // Increment refresh counter to trigger UI rebuilds across the app
                              ref.read(refreshCounterProvider.notifier).increment();
                              
                              // Update UI with new team
                              setState(() {
                                selectedTeamId = newTeam.id;
                              });
                              
                              if (mounted) {
                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Team "$teamName" created successfully!')),
                                );
                              }
                            }
                          },
                          child: const Text('Create Team'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🔧 Settings: Building UI');
      print('🔧 Settings: selectedSeasonId: $selectedSeasonId');
      print('🔧 Settings: selectedTeamId: $selectedTeamId');
    }

    // Show ALL teams regardless of season
    final teamsAsync = ref.watch(teamsStreamProvider);

    return teamsAsync.when(
      data: (teams) => _buildSettingsScaffold(context, teams),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        if (kDebugMode) {
          print('Settings: Error loading teams: $error');
        }
        return _buildSettingsScaffold(context, <Team>[]);
      },
    );
  }

  Widget _buildSettingsScaffold(BuildContext context, List<Team> teams) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.settings),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Team Management Section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.teamManagement,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Season Display (non-editable)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: 'current',
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onChanged: null, // Disabled dropdown
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'current',
                            child: Row(
                              children: [
                                Icon(Icons.sports_soccer, size: 16),
                                SizedBox(width: 8),
                                Text('Season 2025-26', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'future',
                            enabled: false,
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text(
                                  'Season 2026-27', 
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '(Coming Soon)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Teams List with select and delete options
                  if (teams.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No teams yet. Create your first team!',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Your Teams (tap to select)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...teams.map((team) {
                      // Check if this team is currently selected
                      final isSelected = ref.watch(selectedTeamIdProvider) == team.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.groups,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            team.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isSelected ? 'Active Team' : 'Tap to select',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[600],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteTeam(context, team),
                          ),
                          onTap: () async {
                            // Select this team globally
                            await ref.read(selectedTeamIdProvider.notifier).selectTeam(team.id);

                            // Update local state for UI refresh
                            setState(() {
                              selectedTeamId = team.id;
                            });

                            // Show confirmation
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Switched to team "${team.name}"'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 12),

                  // Create New Team Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (selectedSeasonId != null) {
                          _showCreateTeamDialog(selectedSeasonId!);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create New Team'),
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Language & Preferences Section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.languageAndPreferences,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Language Selection
                  Consumer(
                    builder: (context, ref, child) {
                      final currentLocale = ref.watch(localeProvider);
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentLocale.languageCode,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            items: const [
                              DropdownMenuItem<String>(
                                value: 'en',
                                child: Row(
                                  children: [
                                    Text('🇺🇸', style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 12),
                                    Text('English'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<String>(
                                value: 'it',
                                child: Row(
                                  children: [
                                    Text('🇮🇹', style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 12),
                                    Text('Italiano'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(localeProvider.notifier).setLocale(Locale(value));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Language changed to: $value')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Additional preference toggles
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.darkMode),
                    subtitle: Text(AppLocalizations.of(context)!.useDarkTheme),
                    value: false,
                    onChanged: (value) {
                      // Dark mode toggle placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dark mode toggle - Coming soon!')),
                      );
                    },
                  ),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!.notifications),
                    subtitle: Text(AppLocalizations.of(context)!.receiveReminders),
                    value: true,
                    onChanged: (value) {
                      // Notifications toggle placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications toggle - Coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Account Section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // User Information Display
                  Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(firebaseAuthProvider);
                      final currentUser = authState.firebaseUser;
                      
                      if (currentUser != null) {
                        // Determine authentication method
                        String authMethod = 'Email/Password';
                        IconData authIcon = Icons.email;
                        Color authColor = Colors.blue;
                        
                        // Check if it's a Google account (common Google domains or if display name exists)
                        final email = currentUser.email ?? '';
                        final displayName = currentUser.displayName ?? '';
                        if (email.endsWith('@gmail.com') || displayName.isNotEmpty) {
                          authMethod = 'Google Sign-In';
                          authIcon = Icons.login;
                          authColor = Colors.red;
                        }
                        
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    authIcon,
                                    color: authColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    authMethod,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: authColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                email,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (displayName.isNotEmpty && displayName != email) ...[
                                const SizedBox(height: 4),
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          // Store context before async operation
                          final authNotifier = ref.read(firebaseAuthProvider.notifier);
                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          
                          await authNotifier.signOut();
                          
                          if (context.mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Logged out successfully')),
                            );
                            // Navigation will be handled by the auth state change in router
                          }
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
  }
}

// Stateful navigation shell for persistent bottom navigation bar
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({Key? key, required this.navigationShell}) : super(key: key ?? const ValueKey('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Players'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Trainings'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (int index) => _onTap(context, index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Create a stream controller to listen to auth and onboarding changes
  late final StreamController<String> streamController;

  void authListener(AuthState? previous, AuthState next) {
    if (!streamController.isClosed) {
      streamController.add('auth_change_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  void onboardingListener(AsyncValue<bool>? previous, AsyncValue<bool> next) {
    if (!streamController.isClosed) {
      streamController.add('onboarding_change_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  streamController = StreamController<String>();
  ref.listen<AuthState>(firebaseAuthProvider, authListener, fireImmediately: true);
  ref.listen<AsyncValue<bool>>(onboardingStatusProvider, onboardingListener, fireImmediately: true);

  ref.onDispose(() {
    if (!streamController.isClosed) {
      streamController.close();
    }
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(streamController.stream),
    observers: [AnalyticsService.observer],
    redirect: (context, state) {
      final authState = ref.read(firebaseAuthProvider);
      final currentPath = state.matchedLocation;

      if (kDebugMode) {
        print('🚦 Router: currentPath=$currentPath, isAuthenticated=${authState.isAuthenticated}, isFirebaseUser=${authState.isUsingFirebaseAuth}, isLoading=${authState.isLoading}, isInitializing=${authState.isInitializing}');
      }

      // If auth is still loading or initializing, don't redirect yet
      if (authState.isLoading) {
        if (kDebugMode) {
          print('🚦 Router: Auth still loading, staying on current path');
        }
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;
      final isFullyReady = authState.isFullyReady;

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !currentPath.startsWith('/login')) {
        return '/login';
      }

      // If authenticated, check if fully ready before redirecting
      if (isAuthenticated) {
        // Check if user is on login page and fully ready to navigate
        if (currentPath.startsWith('/login')) {
          // Only proceed if fully initialized
          if (!isFullyReady) {
            if (kDebugMode) {
              print('🚦 Router: User authenticated but still initializing, staying on login');
            }
            return null; // Stay on login screen while loading
          }

          // Check if user has teams (simple onboarding check)
          final hasTeamsAsync = ref.read(onboardingStatusProvider);

          // If still loading, stay on login screen
          if (hasTeamsAsync.isLoading) {
            if (kDebugMode) {
              print('🚦 Router: Still checking for teams, staying on login');
            }
            return null; // Stay on login while checking
          }

          final hasTeams = hasTeamsAsync.when(
            data: (value) => value,
            loading: () => false, // Should never hit this due to check above
            error: (_, __) => false,
          );

          if (kDebugMode) {
            print('🚦 Router: User has teams: $hasTeams');
          }

          if (!hasTeams) {
            if (kDebugMode) {
              print('🚦 Router: No teams found, redirecting to onboarding');
            }
            return '/onboarding';
          }

          if (kDebugMode) {
            print('🚦 Router: User has teams, redirecting to players');
          }
          return '/players';
        }

        // Check if authenticated user has teams (but not on onboarding page)
        if (currentPath != '/onboarding') {
          final hasTeamsAsync = ref.read(onboardingStatusProvider);

          // If still loading, don't redirect yet
          if (hasTeamsAsync.isLoading) {
            if (kDebugMode) {
              print('🚦 Router: Still checking for teams, staying on $currentPath');
            }
            return null; // Stay on current path while checking
          }

          final hasTeams = hasTeamsAsync.when(
            data: (value) => value,
            loading: () => false, // Should never hit this due to check above
            error: (_, __) => false,
          );

          if (!hasTeams) {
            if (kDebugMode) {
              print('🚦 Router: User has no teams, redirecting from $currentPath to /onboarding');
            }
            return '/onboarding';
          }
        }

        // For Firebase users, ensure they don't access data-dependent screens too early
        if (authState.isUsingFirebaseAuth && authState.isInitializing) {
          // If user tries to access data screens while still initializing, keep them on login
          final dataRoutes = ['/home', '/players', '/trainings', '/matches', '/settings'];
          if (dataRoutes.any((route) => currentPath.startsWith(route))) {
            if (kDebugMode) {
              print('🚦 Router: Preventing access to $currentPath while initializing, redirecting to login');
            }
            return '/login';
          }
        }
      }

      return null; // No redirect needed
    },
    routes: [
      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Onboarding route
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          // Players Branch
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/players',
                builder: (context, state) => const PlayersScreen(),
                routes: [
                  GoRoute(
                    path: ':playerId',
                    builder: (context, state) => PlayerDetailScreen(
                      playerId: state.pathParameters['playerId']!,
                    ),
                  ),
                ]),
          ]),
          // Trainings Branch
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/trainings',
                builder: (context, state) => const TrainingsScreen(),
                routes: [
                  GoRoute(
                    path: ':trainingId',
                    builder: (context, state) => TrainingDetailScreen(
                      trainingId: state.pathParameters['trainingId']!,
                    ),
                  ),
                ]),
          ]),
          // Matches Branch
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/matches',
                builder: (context, state) => const MatchesScreen(),
                routes: [
                  GoRoute(
                    path: ':matchId',
                    builder: (context, state) => MatchDetailScreen(
                      matchId: state.pathParameters['matchId']!,
                    ),
                  ),
                ]),
          ]),
          // Settings Branch with Seasons and Teams
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
                path: '/seasons',
                builder: (context, state) => const SeasonListScreen(),
                routes: [
                  GoRoute(
                    path: ':seasonId',
                    builder: (context, state) => SeasonDetailScreen(
                      seasonId: state.pathParameters['seasonId']!,
                    ),
                  ),
                ]),
            GoRoute(
                path: '/teams/:teamId',
                builder: (context, state) => TeamDetailScreen(
                      teamId: state.pathParameters['teamId']!,
                    ),
                routes: [
                  GoRoute(
                    path: 'matches',
                    builder: (context, state) => MatchListScreen(
                      teamId: state.pathParameters['teamId']!,
                    ),
                  ),
                ]),
          ]),
        ],
      ),
    ],
  );
});
