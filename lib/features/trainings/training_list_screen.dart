import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/services/training_attendance_repository.dart';
import 'package:coachmaster/features/trainings/training_detail_screen.dart';

class TrainingListScreen extends ConsumerStatefulWidget {
  final String teamId;
  const TrainingListScreen({super.key, required this.teamId});

  @override
  ConsumerState<TrainingListScreen> createState() => _TrainingListScreenState();
}

class _TrainingListScreenState extends ConsumerState<TrainingListScreen> {
  String? selectedTrainingId; // For managing attendance
  Map<String, List<String>> absentPlayersByTraining = {}; // Cache of absent players

  @override
  Widget build(BuildContext context) {
    final trainingRepository = ref.watch(trainingRepositoryProvider);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final attendanceRepository = ref.watch(trainingAttendanceRepositoryProvider);
    
    final trainings = trainingRepository.getTrainingsForTeam(widget.teamId);
    final players = playerRepository.getPlayersForTeam(widget.teamId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Training Sessions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTrainingDialog(),
            tooltip: 'Add Training',
          ),
        ],
      ),
      body: trainings.isEmpty 
        ? _buildEmptyState()
        : Column(
            children: [
              // Add Training Section
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Create New Training',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showAddTrainingDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Training Session'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Training History Section
              Expanded(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Training History',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: trainings.length,
                          itemBuilder: (context, index) {
                            final training = trainings[index];
                            return _buildTrainingCard(training, players, attendanceRepository);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Training Sessions Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first training session to start tracking attendance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddTrainingDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create First Training'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(Training training, List<Player> players, TrainingAttendanceRepository attendanceRepository) {
    // Get attendance data for this training
    final attendances = attendanceRepository.getAttendancesForTraining(training.id);
    final absentCount = attendances.where((a) => a.status == TrainingAttendanceStatus.absent).length;
    final isAttendanceManaged = selectedTrainingId == training.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            // Training Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(training.date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              training.location,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: absentCount > 0 ? Colors.red[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$absentCount absent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: absentCount > 0 ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteTraining(training);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (selectedTrainingId == training.id) {
                            selectedTrainingId = null;
                          } else {
                            selectedTrainingId = training.id;
                            _loadAttendanceForTraining(training.id, attendanceRepository);
                          }
                        });
                      },
                      icon: Icon(isAttendanceManaged ? Icons.close : Icons.edit_note),
                      label: Text(isAttendanceManaged ? 'Close' : 'Manage Attendance'),
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Management Section (Expandable)
            if (isAttendanceManaged) ...[
              const Divider(height: 1),
              _buildAttendanceManagement(training, players, attendanceRepository),
            ],

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceManagement(Training training, List<Player> players, TrainingAttendanceRepository attendanceRepository) {
    final absentPlayers = absentPlayersByTraining[training.id] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Manage attendance for ${_formatDate(training.date)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Players Grid with Checkboxes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 4,
            ),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isAbsent = absentPlayers.contains(player.id);
              
              return InkWell(
                onTap: () => _togglePlayerAbsence(training.id, player.id),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAbsent ? Colors.red[100] : Colors.green[100],
                    border: Border.all(
                      color: isAbsent ? Colors.red[300]! : Colors.green[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAbsent ? Icons.cancel : Icons.check_circle,
                        color: isAbsent ? Colors.red[700] : Colors.green[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${player.firstName} ${player.lastName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isAbsent ? Colors.red[800] : Colors.green[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _saveAttendance(training.id, attendanceRepository),
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTrainingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TrainingFormBottomSheet(
        teamId: widget.teamId,
        onSaved: () {
          // Refresh the training list
          ref.invalidate(trainingRepositoryProvider);
          setState(() {});
        },
        onTrainingCreated: (trainingId) {
          // Navigate directly to training detail
          context.go('/trainings/$trainingId');
        },
      ),
    );
  }

  void _deleteTraining(Training training) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training'),
        content: Text('Are you sure you want to delete the training session on ${_formatDate(training.date)}?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final trainingRepository = ref.read(trainingRepositoryProvider);
              final attendanceRepository = ref.read(trainingAttendanceRepositoryProvider);
              final noteRepository = ref.read(noteRepositoryProvider);
              
              // Delete related data
              await attendanceRepository.deleteAttendancesForTraining(training.id);
              
              // Delete notes for this training
              await noteRepository.deleteNotesForLinkedItem(training.id, linkedType: 'training');
              
              // Delete the training
              await trainingRepository.deleteTraining(training.id);
              
              // Invalidate providers to refresh UI
              ref.invalidate(trainingRepositoryProvider);
              ref.invalidate(trainingAttendanceRepositoryProvider);
              ref.invalidate(noteRepositoryProvider);
              
              // Close attendance management if this training was selected
              if (selectedTrainingId == training.id) {
                setState(() {
                  selectedTrainingId = null;
                });
              }
              
              // Force a rebuild to ensure UI updates
              if (mounted) {
                setState(() {});
              }
              
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _loadAttendanceForTraining(String trainingId, TrainingAttendanceRepository attendanceRepository) {
    final attendances = attendanceRepository.getAttendancesForTraining(trainingId);
    final absentPlayerIds = attendances
        .where((a) => a.status == TrainingAttendanceStatus.absent)
        .map((a) => a.playerId)
        .toList();
    
    setState(() {
      absentPlayersByTraining[trainingId] = absentPlayerIds;
    });
  }

  void _togglePlayerAbsence(String trainingId, String playerId) {
    setState(() {
      final currentAbsent = absentPlayersByTraining[trainingId] ?? [];
      if (currentAbsent.contains(playerId)) {
        absentPlayersByTraining[trainingId] = currentAbsent.where((id) => id != playerId).toList();
      } else {
        absentPlayersByTraining[trainingId] = [...currentAbsent, playerId];
      }
    });
  }

  void _saveAttendance(String trainingId, TrainingAttendanceRepository attendanceRepository) async {
    final playerRepository = ref.read(playerRepositoryProvider);
    final players = playerRepository.getPlayersForTeam(widget.teamId);
    final absentPlayerIds = absentPlayersByTraining[trainingId] ?? [];
    
    // Create attendance records for all players
    final attendanceRecords = players.map((player) {
      final status = absentPlayerIds.contains(player.id) 
          ? TrainingAttendanceStatus.absent 
          : TrainingAttendanceStatus.present;
      
      return TrainingAttendance.create(
        trainingId: trainingId,
        playerId: player.id,
        status: status,
      );
    }).toList();

    // Clear existing attendance for this training
    final existingAttendances = attendanceRepository.getAttendancesForTraining(trainingId);
    for (final attendance in existingAttendances) {
      await attendanceRepository.deleteAttendance(attendance.id);
    }

    // Save new attendance records
    for (final attendance in attendanceRecords) {
      await attendanceRepository.addAttendance(attendance);
    }

    // Update player absence statistics
    for (final player in players) {
      final allAttendances = attendanceRepository.getAttendancesForPlayer(player.id);
      await playerRepository.updatePlayerAbsences(player.id, allAttendances);
    }

    // Refresh the UI
    ref.invalidate(trainingAttendanceRepositoryProvider);
    ref.invalidate(playerRepositoryProvider);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully!')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
