import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'dart:io';

class TrainingDetailScreen extends ConsumerStatefulWidget {
  final String trainingId;
  const TrainingDetailScreen({super.key, required this.trainingId});

  @override
  ConsumerState<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends ConsumerState<TrainingDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final trainingRepository = ref.watch(trainingRepositoryProvider);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final attendanceRepository = ref.watch(trainingAttendanceRepositoryProvider);
    final training = trainingRepository.getTraining(widget.trainingId);

    if (training == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations?.trainingNotFound ?? 'Training Not Found')),
        body: Center(child: Text(localizations?.trainingNotFoundMessage ?? 'Training with given ID not found.')),
      );
    }

    final players = playerRepository.getPlayersForTeam(training.teamId);
    final attendances = attendanceRepository.getAttendancesForTraining(widget.trainingId);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(localizations?.trainingSession ?? 'Training Session')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditTrainingDialog(context, ref, training);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(localizations?.deleteTraining ?? 'Delete Training'),
                  content: Text(localizations?.deleteTrainingConfirm ?? 'Are you sure you want to delete this training?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(localizations?.cancel ?? 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        trainingRepository.deleteTraining(training.id);
                        ref.invalidate(trainingRepositoryProvider);
                        context.pop();
                        context.go('/trainings');
                      },
                      child: Text(localizations?.delete ?? 'Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and Location
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(training.date),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            '${training.startTime.format(context)} - ${training.endTime.format(context)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              training.location,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Objectives Section
            if (training.objectives.isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_objects, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          localizations?.trainingObjectives ?? 'Training Objectives',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...training.objectives.map((objective) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              objective,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],

            // Attendance Section
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.how_to_reg, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${localizations?.attendance ?? 'Attendance'} (${_getAttendanceStats(players, attendances)})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (players.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              localizations?.noPlayersInTeam ?? 'No players in this team',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: players.map((player) {
                          final attendance = attendances.cast<TrainingAttendance?>().firstWhere(
                            (a) => a?.playerId == player.id,
                            orElse: () => null,
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _buildPlayerAttendanceRow(player, attendance, localizations),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getAttendanceStats(List<Player> players, List<TrainingAttendance> attendances) {
    final present = attendances.where((a) => a.status == TrainingAttendanceStatus.present).length;
    return '$present/${players.length}';
  }

  Widget _buildPlayerAttendanceRow(Player player, TrainingAttendance? attendance, AppLocalizations? localizations) {
    final fullName = '${player.firstName} ${player.lastName}'.trim();
    final isPresent = attendance?.status == TrainingAttendanceStatus.present;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          key: ValueKey(player.photoPath), // Force rebuild when photo changes
          radius: 24,
          backgroundColor: isPresent 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.errorContainer,
          backgroundImage: player.photoPath != null && player.photoPath!.isNotEmpty
              ? (kIsWeb && (player.photoPath!.startsWith('data:') || player.photoPath!.startsWith('blob:') || player.photoPath!.startsWith('http'))
                  ? NetworkImage(player.photoPath!) as ImageProvider
                  : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider : null))
              : null,
          child: player.photoPath == null || player.photoPath!.isEmpty ||
              (kIsWeb && !player.photoPath!.startsWith('data:') && !player.photoPath!.startsWith('blob:') && !player.photoPath!.startsWith('http'))
              ? Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPresent 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          fullName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              player.position,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isPresent 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isPresent ? (localizations?.present ?? 'Present') : (localizations?.absent ?? 'Absent'),
                  style: TextStyle(
                    color: isPresent 
                        ? Colors.green 
                        : Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: isPresent,
          onChanged: (value) {
            final attendanceRepository = ref.read(trainingAttendanceRepositoryProvider);
            final status = value ? TrainingAttendanceStatus.present : TrainingAttendanceStatus.absent;
            
            if (attendance != null) {
              final updatedAttendance = TrainingAttendance(
                id: attendance.id,
                playerId: player.id,
                trainingId: widget.trainingId,
                status: status,
                reason: attendance.reason,
                arrivalTime: attendance.arrivalTime,
              );
              attendanceRepository.updateAttendance(updatedAttendance);
            } else {
              final newAttendance = TrainingAttendance.create(
                playerId: player.id,
                trainingId: widget.trainingId,
                status: status,
              );
              attendanceRepository.addAttendance(newAttendance);
            }
            ref.invalidate(trainingAttendanceRepositoryProvider);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showEditTrainingDialog(BuildContext context, WidgetRef ref, Training training) {
    final localizations = AppLocalizations.of(context);
    final trainingRepository = ref.read(trainingRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String location = training.location;
    DateTime date = training.date;
    TimeOfDay startTime = training.startTime;
    TimeOfDay endTime = training.endTime;
    List<String> objectives = training.objectives;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations?.editTraining ?? 'Edit Training'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: location,
                    decoration: InputDecoration(labelText: localizations?.location ?? 'Location'),
                    validator: (value) => value!.isEmpty ? (localizations?.required ?? 'Required') : null,
                    onSaved: (value) => location = value!,
                  ),
                  ListTile(
                    title: Text('Date: ${date.toLocal().toIso8601String().split('T').first}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        date = picked;
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Start Time: ${startTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        startTime = picked;
                      }
                    },
                  ),
                  ListTile(
                    title: Text('End Time: ${endTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        endTime = picked;
                      }
                    },
                  ),
                  TextFormField(
                    initialValue: objectives.join(', '),
                    decoration: const InputDecoration(labelText: 'Objectives (comma-separated)'),
                    onSaved: (value) => objectives = value!.split(',').map((e) => e.trim()).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final updatedTraining = Training(
                    id: training.id,
                    teamId: training.teamId,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    location: location,
                    objectives: objectives,
                  );
                  trainingRepository.updateTraining(updatedTraining);
                  ref.invalidate(trainingRepositoryProvider);
                  context.pop();
                }
              },
              child: Text(localizations?.save ?? 'Save'),
            ),
          ],
        );
      },
    );
  }
}
