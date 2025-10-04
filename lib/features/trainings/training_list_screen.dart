import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';
import 'package:coachmaster/features/trainings/training_detail_screen.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

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
    final trainingsAsync = ref.watch(trainingsForTeamStreamProvider(widget.teamId));
    final playersAsync = ref.watch(playersForTeamStreamProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.trainingsTitle),
          ],
        ),
      ),
      body: trainingsAsync.when(
        data: (trainings) {
          if (trainings.isEmpty) {
            return _buildEmptyState();
          }

          return playersAsync.when(
            data: (players) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trainings.length,
              itemBuilder: (context, index) {
                final training = trainings[index];
                return _buildTrainingCard(training, players);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading players: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading trainings: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTrainingDialog(),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addTraining),
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
            AppLocalizations.of(context)!.noTrainingsScheduled,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createFirstTrainingToStart,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddTrainingDialog(),
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createFirstTraining),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingCard(Training training, List<Player> players) {
    final attendancesAsync = ref.watch(attendancesForTrainingStreamProvider(training.id));
    final isAttendanceManaged = selectedTrainingId == training.id;

    return attendancesAsync.when(
      data: (attendances) => _buildTrainingCardContent(training, players, attendances, isAttendanceManaged),
      loading: () => _buildTrainingCardLoading(training),
      error: (error, stack) => _buildTrainingCardContent(training, players, [], isAttendanceManaged),
    );
  }

  Widget _buildTrainingCardLoading(Training training) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatDate(training.date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCardContent(Training training, List<Player> players, List<TrainingAttendance> attendances, bool isAttendanceManaged) {
    final absentCount = attendances.where((a) => a.status == TrainingAttendanceStatus.absent).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.go('/trainings/${training.id}'),
          borderRadius: BorderRadius.circular(12),
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
                        AppLocalizations.of(context)!.absences(absentCount),
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
            ],
          ),
        ),
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
          // Streams auto-update, no manual refresh needed
        },
        onTrainingCreated: (trainingId) {
          // Streams auto-update, no manual refresh needed
        },
      ),
    );
  }

  void _deleteTraining(Training training) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while deleting
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteTraining),
            content: Text(AppLocalizations.of(context)!.deleteTrainingConfirm),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => context.pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: isDeleting ? null : () async {
                  setState(() => isDeleting = true);

                  try {
                    final trainingRepository = ref.read(trainingRepositoryProvider);
                    final attendanceRepository = ref.read(trainingAttendanceRepositoryProvider);
                    final noteRepository = ref.read(noteRepositoryProvider);
                    final playerRepository = ref.read(playerRepositoryProvider);

                    // Get attendance records before deletion for stats refresh
                    final attendances = await attendanceRepository.getAttendancesForTraining(training.id);

                    // Delete related data
                    await attendanceRepository.deleteAttendancesForTraining(training.id);

                    // Delete notes for this training
                    await noteRepository.deleteNotesForLinkedItem(training.id, linkedType: 'training');

                    // Delete the training
                    await trainingRepository.deleteTraining(training.id);

                    // Refresh player stats for all affected players
                    final playersAsync = ref.read(playersForTeamStreamProvider(widget.teamId));
                    playersAsync.whenData((players) async {
                      final allAttendances = await attendanceRepository.getAttendances();
                      for (final attendance in attendances) {
                        if (players.any((p) => p.id == attendance.playerId)) {
                          await playerRepository.updatePlayerAbsences(
                            attendance.playerId,
                            allAttendances,
                          );
                        }
                      }
                    });

                    // Close attendance management if this training was selected
                    if (selectedTrainingId == training.id && mounted) {
                      this.setState(() {
                        selectedTrainingId = null;
                      });
                    }

                    // Streams auto-update UI
                    if (context.mounted) {
                      context.pop();
                    }
                  } catch (e) {
                    setState(() => isDeleting = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
