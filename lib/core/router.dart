import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:coachmaster/features/seasons/season_list_screen.dart';
import 'package:coachmaster/features/seasons/season_detail_screen.dart';
import 'package:coachmaster/features/teams/team_detail_screen.dart';
import 'package:coachmaster/features/players/player_detail_screen.dart';
import 'package:coachmaster/features/trainings/training_detail_screen.dart';
import 'package:coachmaster/features/matches/match_list_screen.dart';
import 'package:coachmaster/features/matches/match_detail_screen.dart';
import 'package:coachmaster/features/dashboard/dashboard_screen.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training.dart';

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
    final playerRepo = ref.watch(playerRepositoryProvider);
    final allPlayers = playerRepo.getPlayers();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Players'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header with player count
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.groups,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Players',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${allPlayers.length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Players list
          Expanded(
            child: allPlayers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No players yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add players from the Home screen',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allPlayers.length,
                    itemBuilder: (context, index) {
                      final player = allPlayers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            key: ValueKey(player.photoPath),
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            backgroundImage: player.photoPath != null && player.photoPath!.isNotEmpty
                                ? (kIsWeb && (player.photoPath!.startsWith('data:') || player.photoPath!.startsWith('blob:') || player.photoPath!.startsWith('http'))
                                    ? NetworkImage(player.photoPath!) as ImageProvider
                                    : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider : null))
                                : null,
                            child: player.photoPath == null || player.photoPath!.isEmpty ||
                                (kIsWeb && !player.photoPath!.startsWith('data:') && !player.photoPath!.startsWith('blob:') && !player.photoPath!.startsWith('http'))
                                ? Text(
                                    player.firstName[0] + player.lastName[0],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            '${player.firstName} ${player.lastName}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            player.position,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onTap: () => context.go('/players/${player.id}'),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlayerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Player'),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context) {
    final teamRepo = ref.read(teamRepositoryProvider);
    final teams = teamRepo.getTeams();
    
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a team first')),
      );
      return;
    }

    final playerRepository = ref.read(playerRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String firstName = '';
    String lastName = '';
    String position = 'Midfielder';
    String preferredFoot = 'Both';
    String selectedTeamId = teams.first.id;
    DateTime birthDate = DateTime.now().subtract(const Duration(days: 365 * 18));

    final positions = [
      'Goalkeeper', 'Defender', 'Midfielder', 'Forward',
      'Centre-back', 'Full-back', 'Wing-back', 'Defensive midfielder',
      'Central midfielder', 'Attacking midfielder', 'Winger', 'Striker'
    ];

    final feet = ['Left', 'Right', 'Both'];

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
                        'Add New Player',
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
                                // Team Selection
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Team',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: selectedTeamId,
                                  items: teams.map((team) => DropdownMenuItem(
                                    value: team.id,
                                    child: Text(team.name),
                                  )).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedTeamId = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'First Name',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) => value!.isEmpty ? 'Required' : null,
                                        onSaved: (value) => firstName = value!,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Last Name',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) => value!.isEmpty ? 'Required' : null,
                                        onSaved: (value) => lastName = value!,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Position',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: position,
                                  items: positions.map((pos) => DropdownMenuItem(
                                    value: pos,
                                    child: Text(pos),
                                  )).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      position = value ?? 'Midfielder';
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Preferred Foot',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: preferredFoot,
                                  items: feet.map((foot) => DropdownMenuItem(
                                    value: foot,
                                    child: Text(foot),
                                  )).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      preferredFoot = value ?? 'Both';
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: birthDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
                                      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        birthDate = picked;
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
                                        Text('Birth Date: ${_formatBirthDate(birthDate)}'),
                                      ],
                                    ),
                                  ),
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
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  
                                  final newPlayer = Player.create(
                                    teamId: selectedTeamId,
                                    firstName: firstName,
                                    lastName: lastName,
                                    position: position,
                                    preferredFoot: preferredFoot,
                                    birthDate: birthDate,
                                  );
                                  
                                  playerRepository.addPlayer(newPlayer);
                                  ref.invalidate(playerRepositoryProvider);
                                  Navigator.of(context).pop();
                                  
                                  // Force rebuild
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$firstName $lastName added successfully!')),
                                  );
                                }
                              },
                              child: const Text('Add Player'),
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

  String _formatBirthDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
            const Text('Training Sessions'),
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
        label: const Text('Add Training'),
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
    String? selectedTeamId = teams.first.id;
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 19, minute: 30);
    String location = '';
    List<String> objectives = [];
    String coachNotes = '';

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
                        'Add Training Session',
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
                                // Team Selection
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Team',
                                    border: OutlineInputBorder(),
                                  ),
                                  initialValue: selectedTeamId,
                                  items: teams.map((team) => DropdownMenuItem(
                                    value: team.id,
                                    child: Text(team.name),
                                  )).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedTeamId = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Date Selection
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
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
                                        Text('Date: ${_formatDate(selectedDate)}'),
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
                                        Text('Start Time: ${_formatTime(startTime)}'),
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
                                        Text('End Time: ${_formatTime(endTime)}'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Location
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Location',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value!.isEmpty ? 'Required' : null,
                                  onSaved: (value) => location = value!,
                                ),
                                const SizedBox(height: 16),
                                
                                // Objectives
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Objectives (comma-separated)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSaved: (value) {
                                    objectives = value!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Coach Notes
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Coach Notes (optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  onSaved: (value) => coachNotes = value ?? '',
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
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  formKey.currentState!.save();
                                  
                                  final newTraining = Training.create(
                                    teamId: selectedTeamId!,
                                    date: selectedDate,
                                    startTime: startTime,
                                    endTime: endTime,
                                    location: location,
                                    objectives: objectives,
                                    coachNotes: coachNotes.isEmpty ? null : coachNotes,
                                  );
                                  
                                  trainingRepository.addTraining(newTraining);
                                  ref.invalidate(trainingRepositoryProvider);
                                  Navigator.of(context).pop();
                                  
                                  // Force rebuild of screen
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Training session added successfully!')),
                                  );
                                }
                              },
                              child: const Text('Add Training'),
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

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Matches Screen')));
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

  void _loadCurrentSelections() {
    final seasonRepo = ref.read(seasonRepositoryProvider);
    final teamRepo = ref.read(teamRepositoryProvider);
    
    final seasons = seasonRepo.getSeasons();
    if (seasons.isNotEmpty) {
      selectedSeasonId = seasons.first.id;
      
      final teams = teamRepo.getTeamsForSeason(selectedSeasonId!);
      if (teams.isNotEmpty) {
        selectedTeamId = teams.first.id;
      }
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final seasonRepo = ref.watch(seasonRepositoryProvider);
    final teamRepo = ref.watch(teamRepositoryProvider);
    
    final seasons = seasonRepo.getSeasons();
    final teams = selectedSeasonId != null ? teamRepo.getTeamsForSeason(selectedSeasonId!) : <Team>[];
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Settings'),
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
                        'Team Management',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Season Selection
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
                        value: selectedSeasonId,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        hint: const Text('Select Season'),
                        onChanged: (seasonId) {
                          setState(() {
                            selectedSeasonId = seasonId;
                            selectedTeamId = null;
                          });
                          if (seasonId != null) {
                            final newTeams = teamRepo.getTeamsForSeason(seasonId);
                            if (newTeams.isNotEmpty) {
                              setState(() {
                                selectedTeamId = newTeams.first.id;
                              });
                            }
                          }
                        },
                        items: seasons.map((season) => DropdownMenuItem(
                          value: season.id,
                          child: Text('Season ${season.name}'),
                        )).toList(),
                      ),
                    ),
                  ),
                  
                  if (selectedSeasonId != null && teams.isNotEmpty) ...[
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
                          hint: const Text('Select Team'),
                          onChanged: (teamId) {
                            setState(() {
                              selectedTeamId = teamId;
                            });
                          },
                          items: teams.map((team) => DropdownMenuItem(
                            value: team.id,
                            child: Text(team.name),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Management Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/seasons'),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Manage Seasons'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedTeamId != null 
                              ? () => context.go('/teams/$selectedTeamId')
                              : null,
                          icon: const Icon(Icons.groups),
                          label: const Text('Manage Teams'),
                        ),
                      ),
                    ],
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
                        'Language & Preferences',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Language Selection
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
                      child: DropdownButton<String>(
                        value: 'en',
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                Text('🇺🇸', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 12),
                                Text('English'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'it',
                            child: Row(
                              children: [
                                Text('🇮🇹', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 12),
                                Text('Italiano'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'es',
                            child: Row(
                              children: [
                                Text('🇪🇸', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 12),
                                Text('Español'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'fr',
                            child: Row(
                              children: [
                                Text('🇫🇷', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 12),
                                Text('Français'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'de',
                            child: Row(
                              children: [
                                Text('🇩🇪', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 12),
                                Text('Deutsch'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          // TODO: Implement language change functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Language changed to: $value')),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Additional preference toggles
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
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
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive match and training reminders'),
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
  return GoRouter(
    initialLocation: '/home',
    routes: [
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
