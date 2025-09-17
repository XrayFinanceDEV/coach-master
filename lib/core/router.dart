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
import 'package:coachmaster/features/trainings/training_detail_screen.dart';
import 'package:coachmaster/features/matches/match_list_screen.dart';
import 'package:coachmaster/features/matches/match_detail_screen.dart';
import 'package:coachmaster/features/dashboard/dashboard_screen.dart';
import 'package:coachmaster/features/auth/login_screen.dart';
import 'package:coachmaster/features/onboarding/onboarding_screen.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/locale_provider.dart';
import 'package:coachmaster/core/firebase_auth_providers.dart';
import 'package:coachmaster/models/auth_state.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/training.dart';

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
    
    // Get the current team to display players
    final teamRepo = ref.watch(teamRepositoryProvider);
    final seasonRepo = ref.watch(seasonRepositoryProvider);
    
    final seasons = seasonRepo.getSeasons();
    if (seasons.isEmpty) {
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
              Icon(Icons.warning, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('No seasons found. Please create a season first.'),
            ],
          ),
        ),
      );
    }
    
    // Get current season (latest season)
    final currentSeason = seasons.first;
    final teams = teamRepo.getTeamsForSeason(currentSeason.id);
    
    if (teams.isEmpty) {
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
              Text('No teams found. Please create a team first.'),
            ],
          ),
        ),
      );
    }
    
    // Use the first team (in a real app, this would be user-selected)
    final currentTeam = teams.first;
    
    return PlayerListScreen(teamId: currentTeam.id);
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
    ref.watch(refreshCounterProvider);
    
    final trainingRepo = ref.watch(trainingRepositoryProvider);
    final teamRepo = ref.watch(teamRepositoryProvider);
    
    // Get all trainings and group by team
    final allTrainings = trainingRepo.getTrainings();
    final allTeams = teamRepo.getTeams();
    
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
      body: allTrainings.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No training sessions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add training sessions to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allTrainings.length,
              itemBuilder: (context, index) {
                final training = allTrainings[index];
                final team = allTeams.cast<Team?>().firstWhere(
                  (t) => t?.id == training.teamId,
                  orElse: () => null,
                );
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.fitness_center, color: Colors.white),
                    ),
                    title: Text(team?.name ?? 'Unknown Team'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_formatDate(training.date)} • ${_formatTimeRange(training.startTime, training.endTime)}'),
                        Text('📍 ${training.location}'),
                        if (training.objectives.isNotEmpty)
                          Text('🎯 ${training.objectives.join(', ')}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/trainings/${training.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTrainingBottomSheet(context, ref, allTeams),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addTraining),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  String _formatTimeRange(TimeOfDay start, TimeOfDay end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }
  
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showAddTrainingBottomSheet(BuildContext context, WidgetRef ref, List<Team> teams) {
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a team first')),
      );
      return;
    }

    final trainingRepository = ref.read(trainingRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String selectedTeamId = teams.first.id;
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 30);
    String location = '';
    List<String> objectives = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.95,
              minChildSize: 0.5,
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
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        AppLocalizations.of(context)!.trainingSession,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form content
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              children: [
                                
                                // Date Selection
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null && context.mounted) {
                                      setDialogState(() {
                                        selectedDate = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 12),
                                        Text('${AppLocalizations.of(context)!.date}: ${_formatDate(selectedDate)}'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Start Time
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: startTime,
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        startTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time),
                                        const SizedBox(width: 12),
                                        Text('${AppLocalizations.of(context)!.startTime}: ${_formatTime(startTime)}'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // End Time
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: endTime,
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        endTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time),
                                        const SizedBox(width: 12),
                                        Text('${AppLocalizations.of(context)!.endTime}: ${_formatTime(endTime)}'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Location
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.location,
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.required : null,
                                  onSaved: (value) => location = value!,
                                ),
                                const SizedBox(height: 16),
                                
                                // Objectives
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: AppLocalizations.of(context)!.objectives,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onSaved: (value) {
                                    objectives = value!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Bottom buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  
                                  // Store context and localization before async operation
                                  final navigator = Navigator.of(context);
                                  final messenger = ScaffoldMessenger.of(context);
                                  final localizations = AppLocalizations.of(context)!;
                                  
                                  final newTraining = Training.create(
                                    teamId: selectedTeamId,
                                    date: selectedDate,
                                    startTime: startTime,
                                    endTime: endTime,
                                    location: location,
                                    objectives: objectives,
                                  );
                                  
                                  await trainingRepository.addTraining(newTraining);
                                  ref.invalidate(trainingRepositoryProvider);
                                  
                                  // Force rebuild of screen
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  
                                  navigator.pop();
                                  
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('${localizations.trainingSession} aggiunta con successo!')),
                                  );
                                }
                              },
                              child: Text(AppLocalizations.of(context)!.addTraining),
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
      },
    );
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
    final teamRepo = ref.watch(teamRepositoryProvider);
    final seasonRepo = ref.watch(seasonRepositoryProvider);
    
    // Get the current season and team
    final seasons = seasonRepo.getSeasons();
    if (seasons.isEmpty) {
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
              Icon(Icons.warning, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('No seasons found. Please create a season first.'),
            ],
          ),
        ),
      );
    }
    
    // Get current season (latest season)
    final currentSeason = seasons.first;
    final teams = teamRepo.getTeamsForSeason(currentSeason.id);
    
    if (teams.isEmpty) {
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
              Text('No teams found. Please create a team first.'),
            ],
          ),
        ),
      );
    }
    
    // Use the first team (in a real app, this would be user-selected)
    final currentTeam = teams.first;
    
    return MatchListScreen(teamId: currentTeam.id);
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

    try {
      // Clean up any duplicate teams first
      await teamRepo.cleanupDuplicateTeams();
    } catch (e) {
      // If cleanup fails due to corrupted data, clear everything
      print('Settings: Cleanup failed, clearing corrupted data: $e');
      await teamRepo.clearCorruptedData();
    }

    // Look for 2025-26 season or create it if it doesn't exist
    var seasons = seasonRepo.getSeasons();
    if (kDebugMode) {
      print('🔧 Settings: Found ${seasons.length} seasons');
      for (var season in seasons) {
        print('🔧 Settings: Season: ${season.name} (ID: ${season.id})');
      }
    }

    var currentSeason = seasons.cast<Season?>().firstWhere(
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

    final teams = teamRepo.getTeamsForSeason(selectedSeasonId!);
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
    final teamRepo = ref.watch(teamRepositoryProvider);

    if (kDebugMode) {
      print('🔧 Settings: Building UI');
      print('🔧 Settings: selectedSeasonId: $selectedSeasonId');
      print('🔧 Settings: selectedTeamId: $selectedTeamId');
    }

    List<Team> teams = <Team>[];
    try {
      if (selectedSeasonId != null) {
        teams = teamRepo.getTeamsForSeason(selectedSeasonId!);
        if (kDebugMode) {
          print('🔧 Settings: Retrieved ${teams.length} teams for season $selectedSeasonId');
        }
      } else {
        if (kDebugMode) {
          print('🔧 Settings: selectedSeasonId is null, not loading teams');
        }
        teams = <Team>[];
      }
    } catch (e) {
      print('Settings: Error getting teams, returning empty list: $e');
      teams = <Team>[];
    }
    
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
                  
                  if (selectedSeasonId != null) ...[
                    const SizedBox(height: 12),
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
                          value: selectedTeamId,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          hint: Text(AppLocalizations.of(context)!.selectTeam),
                          onChanged: (teamId) {
                            if (teamId == 'CREATE_NEW') {
                              _showCreateTeamDialog(selectedSeasonId!);
                            } else {
                              setState(() {
                                selectedTeamId = teamId;
                              });
                            }
                          },
                          items: [
                            // Filter out duplicate team IDs to prevent dropdown assertion error
                            ...teams.fold<Map<String, Team>>({}, (map, team) {
                              map[team.id] = team; // This will keep only unique IDs
                              return map;
                            }).values.map((team) => DropdownMenuItem<String>(
                              value: team.id,
                              child: Text(team.name),
                            )),
                            const DropdownMenuItem<String>(
                              value: 'CREATE_NEW',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text('Create New Team', style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  if (selectedSeasonId != null && teams.isEmpty) ...[
                    const SizedBox(height: 12),
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
                              'No teams in this season. Create your first team!',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
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
                      // TODO: Implement dark mode toggle
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
                      // TODO: Implement notifications toggle
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
  // Create a stream controller to listen to auth changes
  late final StreamController<AuthState> streamController;
  
  void listener(AuthState? previous, AuthState next) {
    if (!streamController.isClosed) {
      streamController.add(next);
    }
  }
  
  streamController = StreamController<AuthState>();
  ref.listen<AuthState>(firebaseAuthProvider, listener, fireImmediately: true);
  
  ref.onDispose(() {
    if (!streamController.isClosed) {
      streamController.close();
    }
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(streamController.stream),
    redirect: (context, state) {
      final authState = ref.read(firebaseAuthProvider);
      final currentPath = state.matchedLocation;

      if (kDebugMode) {
        print('🚦 Router: currentPath=$currentPath, isAuthenticated=${authState.isAuthenticated}, isFirebaseUser=${authState.isUsingFirebaseAuth}, isLoading=${authState.isLoading}');
      }

      // If auth is still loading, don't redirect yet
      if (authState.isLoading) {
        if (kDebugMode) {
          print('🚦 Router: Auth still loading, staying on current path');
        }
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !currentPath.startsWith('/login')) {
        return '/login';
      }

      // If authenticated, check onboarding status
      if (isAuthenticated) {
        // Check if user is on login page
        if (currentPath.startsWith('/login')) {
          // Check onboarding completion
          final isOnboardingCompleted = ref.read(onboardingStatusProvider);
          if (kDebugMode) {
            print('🚦 Router: Onboarding completed: $isOnboardingCompleted');
          }

          if (!isOnboardingCompleted) {
            if (kDebugMode) {
              print('🚦 Router: Redirecting to onboarding');
            }
            return '/onboarding';
          }

          if (kDebugMode) {
            print('🚦 Router: Redirecting authenticated user from $currentPath to /players');
          }
          return '/players';
        }

        // Check if authenticated user needs onboarding (but not on onboarding page)
        if (currentPath != '/onboarding') {
          final isOnboardingCompleted = ref.read(onboardingStatusProvider);
          if (!isOnboardingCompleted) {
            if (kDebugMode) {
              print('🚦 Router: User needs onboarding, redirecting from $currentPath to /onboarding');
            }
            return '/onboarding';
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
