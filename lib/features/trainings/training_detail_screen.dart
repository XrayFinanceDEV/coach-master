import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/models/note.dart';
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
                      onPressed: () async {
                        final attendanceRepository = ref.read(trainingAttendanceRepositoryProvider);
                        final noteRepository = ref.read(noteRepositoryProvider);
                        
                        // Delete related data first
                        await attendanceRepository.deleteAttendancesForTraining(training.id);
                        await noteRepository.deleteNotesForLinkedItem(training.id, linkedType: 'training');
                        
                        // Delete the training
                        await trainingRepository.deleteTraining(training.id);
                        
                        // Invalidate all related providers
                        ref.invalidate(trainingRepositoryProvider);
                        ref.invalidate(trainingAttendanceRepositoryProvider);
                        ref.invalidate(noteRepositoryProvider);
                        
                        if (context.mounted) {
                          context.pop(); // Close dialog
                          context.go('/trainings'); // Navigate back to training list
                        }
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
                      const SizedBox(height: 16),
                      // Attendance Stats in Header
                      Row(
                        children: [
                          const Icon(Icons.how_to_reg, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            '${localizations?.attendance ?? 'Attendance'}: ${_getAttendanceStats(players, attendances)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showEditObjectivesDialog(context, ref, training),
                        icon: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (training.objectives.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No objectives set',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap edit to add objectives',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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

            // Notes Section
            _buildNotesSection(context, ref, training),

            // Player List (like Players screen)
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
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final attendance = attendances.cast<TrainingAttendance?>().firstWhere(
                      (a) => a?.playerId == player.id,
                      orElse: () => null,
                    );
                    return _buildPlayerAttendanceCard(player, attendance, localizations);
                  },
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

  Widget _buildPlayerAttendanceCard(Player player, TrainingAttendance? attendance, AppLocalizations? localizations) {
    final fullName = '${player.firstName} ${player.lastName}'.trim();
    final isPresent = attendance?.status == TrainingAttendanceStatus.present;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Toggle attendance on tap
            final attendanceRepository = ref.read(trainingAttendanceRepositoryProvider);
            final newStatus = !isPresent ? TrainingAttendanceStatus.present : TrainingAttendanceStatus.absent;
            
            if (attendance != null) {
              final updatedAttendance = TrainingAttendance(
                id: attendance.id,
                playerId: player.id,
                trainingId: widget.trainingId,
                status: newStatus,
                reason: attendance.reason,
                arrivalTime: attendance.arrivalTime,
              );
              attendanceRepository.updateAttendance(updatedAttendance);
            } else {
              final newAttendance = TrainingAttendance.create(
                playerId: player.id,
                trainingId: widget.trainingId,
                status: newStatus,
              );
              attendanceRepository.addAttendance(newAttendance);
            }
            ref.invalidate(trainingAttendanceRepositoryProvider);
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Player Avatar
                CircleAvatar(
                  key: ValueKey('${player.id}-${player.photoPath}'),
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
                          '${player.firstName[0]}${player.lastName[0]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            player.position,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                ),
                
                // Attendance Switch
                Switch(
                  value: isPresent,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, WidgetRef ref, Training training) {
    final noteRepository = ref.watch(noteRepositoryProvider);
    final notes = noteRepository.getNotesForTraining(training.id);
    
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.notes,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showAddNoteDialog(context, ref, training),
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notes.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.noNotesYet,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to add a note',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: notes.map((note) => _buildNoteItem(context, ref, note, training)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, WidgetRef ref, Note note, Training training) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditNoteDialog(context, ref, note, training);
                  } else if (value == 'delete') {
                    _deleteNote(context, ref, note);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year} ${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref, Training training) {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
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
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(Icons.note_add, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.addNote,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Add a note for this training session',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              // Note input field
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Note',
                  hintText: 'Enter your note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 4,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
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
                        if (controller.text.trim().isNotEmpty) {
                          final noteRepository = ref.read(noteRepositoryProvider);
                          await noteRepository.createQuickNote(
                            content: controller.text.trim(),
                            type: NoteType.training,
                            linkedId: training.id,
                            linkedType: 'training',
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            setState(() {}); // Refresh the UI
                          }
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.addNote),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, WidgetRef ref, Note note, Training training) {
    final controller = TextEditingController(text: note.content);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
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
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.editNote,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Update the note for this training session',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              
              // Note input field
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Note',
                  hintText: 'Enter your note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 4,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
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
                        if (controller.text.trim().isNotEmpty) {
                          final noteRepository = ref.read(noteRepositoryProvider);
                          final updatedNote = note.copyWith(content: controller.text.trim());
                          await noteRepository.updateNote(updatedNote);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            setState(() {}); // Refresh the UI
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteNote(BuildContext context, WidgetRef ref, Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header with warning icon
            Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.deleteNote,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Warning message
            Text(
              'Are you sure you want to delete this note? This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Note preview (truncated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                note.content.length > 100 
                    ? '${note.content.substring(0, 100)}...'
                    : note.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
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
                      final noteRepository = ref.read(noteRepositoryProvider);
                      await noteRepository.deleteNote(note.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        setState(() {}); // Refresh the UI
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditObjectivesDialog(BuildContext context, WidgetRef ref, Training training) {
    final controller = TextEditingController(text: training.objectives.join(', '));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Objectives'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter objectives separated by commas...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final trainingRepository = ref.read(trainingRepositoryProvider);
              final objectives = controller.text.trim().isNotEmpty
                  ? controller.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                  : <String>[];
              
              final updatedTraining = Training(
                id: training.id,
                teamId: training.teamId,
                date: training.date,
                startTime: training.startTime,
                endTime: training.endTime,
                location: training.location,
                objectives: objectives,
                coachNotes: training.coachNotes,
              );
              
              trainingRepository.updateTraining(updatedTraining);
              ref.invalidate(trainingRepositoryProvider);
              
              if (context.mounted) {
                Navigator.of(context).pop();
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  void _showEditTrainingDialog(BuildContext context, WidgetRef ref, Training training) {
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TrainingFormBottomSheet(
        training: training,
        teamId: training.teamId,
        onSaved: () {
          // Force rebuild of the detail screen
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}

class TrainingFormBottomSheet extends ConsumerStatefulWidget {
  final Training? training; // null for add mode, Training instance for edit mode
  final String teamId;
  final VoidCallback? onSaved;

  const TrainingFormBottomSheet({
    super.key,
    this.training,
    required this.teamId,
    this.onSaved,
  });

  @override
  ConsumerState<TrainingFormBottomSheet> createState() => _TrainingFormBottomSheetState();
}

class _TrainingFormBottomSheetState extends ConsumerState<TrainingFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _location;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<String> _objectives;

  bool get isEditMode => widget.training != null;

  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing training data or defaults
    final training = widget.training;
    _location = training?.location ?? '';
    _date = training?.date ?? DateTime.now();
    _startTime = training?.startTime ?? const TimeOfDay(hour: 18, minute: 0);
    _endTime = training?.endTime ?? const TimeOfDay(hour: 20, minute: 0);
    _objectives = training?.objectives ?? [];
  }

  Future<void> _saveTraining() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final trainingRepository = ref.read(trainingRepositoryProvider);
      
      if (isEditMode) {
        // Update existing training (preserve coachNotes since we removed the field)
        final updatedTraining = Training(
          id: widget.training!.id,
          teamId: widget.teamId,
          date: _date,
          startTime: _startTime,
          endTime: _endTime,
          location: _location,
          objectives: _objectives,
          coachNotes: widget.training!.coachNotes, // Preserve existing coach notes
        );
        trainingRepository.updateTraining(updatedTraining);
      } else {
        // Create new training
        final newTraining = Training.create(
          teamId: widget.teamId,
          date: _date,
          startTime: _startTime,
          endTime: _endTime,
          location: _location,
          objectives: _objectives,
        );
        trainingRepository.addTraining(newTraining);
      }
      
      ref.invalidate(trainingRepositoryProvider);
      
      if (mounted) {
        Navigator.of(context).pop();
        if (widget.onSaved != null) {
          widget.onSaved!();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
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
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Row(
              children: [
                Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  isEditMode 
                      ? (localizations?.editTraining ?? 'Edit Training')
                      : 'Add Training',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Location field
                    TextFormField(
                      initialValue: _location,
                      decoration: InputDecoration(
                        labelText: localizations?.location ?? 'Location',
                        hintText: 'e.g., Main Field, Gym A',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? (localizations?.required ?? 'Required') : null,
                      onSaved: (value) => _location = value!,
                    ),
                    const SizedBox(height: 16),
                    
                    // Date picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _date = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(_date),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _startTime,
                              );
                              if (picked != null) {
                                setState(() {
                                  _startTime = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Start Time',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _startTime.format(context),
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _endTime,
                              );
                              if (picked != null) {
                                setState(() {
                                  _endTime = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'End Time',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _endTime.format(context),
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Objectives field
                    TextFormField(
                      initialValue: _objectives.join(', '),
                      decoration: InputDecoration(
                        labelText: 'Objectives',
                        hintText: 'Passing, Shooting, Conditioning (comma-separated)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      onSaved: (value) {
                        _objectives = value?.trim().isNotEmpty ?? false
                            ? value!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                            : <String>[];
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(localizations?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveTraining,
                    child: Text(isEditMode 
                        ? (localizations?.save ?? 'Save')
                        : 'Create Training'),
                  ),
                ),
              ],
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
}
