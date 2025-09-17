import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/note.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/features/players/widgets/player_form_bottom_sheet.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'dart:io';

class PlayerDetailScreen extends ConsumerStatefulWidget {
  final String playerId;
  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {

  @override
  Widget build(BuildContext context) {
    // Watch refresh counter to trigger rebuilds when data changes
    ref.watch(refreshCounterProvider);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final player = playerRepository.getPlayer(widget.playerId);

    if (player == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.playerNotFound)),
        body: Center(child: Text(AppLocalizations.of(context)!.playerNotFoundMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('${player.firstName} ${player.lastName}')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => PlayerFormBottomSheet(
                  teamId: player.teamId,
                  player: player,
                  onSaved: () {
                    // Increment refresh counter to trigger UI updates across all screens
                    ref.read(refreshCounterProvider.notifier).increment();
                    // Force rebuild of the detail screen
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.deletePlayer),
                  content: Text(AppLocalizations.of(context)!.deletePlayerConfirm(player.firstName, player.lastName)),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final attendanceRepository = ref.read(trainingAttendanceRepositoryProvider);
                        final noteRepository = ref.read(noteRepositoryProvider);
                        final matchStatisticRepository = ref.read(matchStatisticRepositoryProvider);
                        final matchConvocationRepository = ref.read(matchConvocationRepositoryProvider);
                        
                        // Delete all related data first
                        // Delete training attendances for this player
                        final attendances = attendanceRepository.getAttendancesForPlayer(player.id);
                        for (final attendance in attendances) {
                          await attendanceRepository.deleteAttendance(attendance.id);
                        }
                        
                        // Delete notes for this player
                        await noteRepository.deleteNotesForLinkedItem(player.id, linkedType: 'player');
                        
                        // Delete match statistics for this player
                        final playerStats = matchStatisticRepository.getStatisticsForPlayer(player.id);
                        for (final stat in playerStats) {
                          await matchStatisticRepository.deleteStatistic(stat.id);
                        }
                        
                        // Delete match convocations for this player
                        final convocations = matchConvocationRepository.getConvocationsForPlayer(player.id);
                        for (final convocation in convocations) {
                          await matchConvocationRepository.deleteConvocation(convocation.id);
                        }
                        
                        // Delete the player
                        await playerRepository.deletePlayer(player.id);
                        
                        // Invalidate all related providers
                        ref.invalidate(playerRepositoryProvider);
                        ref.invalidate(playerListProvider);
                        ref.invalidate(trainingAttendanceRepositoryProvider);
                        ref.invalidate(noteRepositoryProvider);
                        ref.invalidate(matchStatisticRepositoryProvider);
                        ref.invalidate(matchConvocationRepositoryProvider);
                        
                        // Increment refresh counter to trigger UI updates
                        ref.read(refreshCounterProvider.notifier).increment();
                        
                        if (context.mounted) {
                          context.pop(); // Close dialog
                          context.go('/players'); // Navigate back to players list
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
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
            // Player Profile Card with Background Image
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  // Background Image/Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: player.photoPath != null && player.photoPath!.isNotEmpty
                          ? null
                          : LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    ),
                    child: player.photoPath != null && player.photoPath!.isNotEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: kIsWeb && (player.photoPath!.startsWith('data:') || 
                                       player.photoPath!.startsWith('blob:') || 
                                       player.photoPath!.startsWith('http'))
                                    ? NetworkImage(player.photoPath!) as ImageProvider
                                    : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider 
                                      : NetworkImage(player.photoPath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Dark overlay for text readability
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            // Show initials when no photo
                            child: Text(
                              '${player.firstName[0]}${player.lastName[0]}',
                              style: const TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  
                  // Stats Badges (Top Right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Goals Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_soccer, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${player.goals}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Assists Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${player.assists}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Player Info (Bottom)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Player Name
                          Text(
                            '${player.firstName} ${player.lastName}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Player Position
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              player.position,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Player Details Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Basic Information Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Basic Information',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(context, Icons.sports, 'Preferred Foot', player.preferredFoot),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, Icons.cake, 'Birth Date', 
                            '${player.birthDate.day}/${player.birthDate.month}/${player.birthDate.year}'),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, Icons.calendar_today, 'Age', 
                            '${DateTime.now().year - player.birthDate.year} years old'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Statistics Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Statistics',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(context, 'Matches', _getMatchesCount(ref, player).toString(), Icons.sports_soccer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(context, 'Goals', player.goals.toString(), Icons.sports_handball),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(context, 'Assists', player.assists.toString(), Icons.gps_fixed),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(context, 'Absences', player.absences.toString(), Icons.cancel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes Section
                  _buildNotesSection(context, ref, player),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, WidgetRef ref, Player player) {
    final noteRepository = ref.watch(noteRepositoryProvider);
    final notes = noteRepository.getNotesForPlayer(player.id);
    
    return Card(
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
                  onPressed: () => _showAddNoteDialog(context, ref, player),
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
                children: notes.map<Widget>((note) => _buildNoteItem(context, ref, note, player)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, WidgetRef ref, Note note, Player player) {
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
                    _showEditNoteDialog(context, ref, note, player);
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

  void _showAddNoteDialog(BuildContext context, WidgetRef ref, Player player) {
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
                'Add a note for ${player.firstName} ${player.lastName}',
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
                      child: Text(AppLocalizations.of(context)!.cancel),
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
                            type: NoteType.player,
                            linkedId: player.id,
                            linkedType: 'player',
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

  void _showEditNoteDialog(BuildContext context, WidgetRef ref, Note note, Player player) {
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
                'Update the note for ${player.firstName} ${player.lastName}',
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
                      child: Text(AppLocalizations.of(context)!.cancel),
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
                      child: Text(AppLocalizations.of(context)!.save),
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
              AppLocalizations.of(context)!.deleteNoteConfirm,
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
                    child: Text(AppLocalizations.of(context)!.cancel),
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
                    child: Text(AppLocalizations.of(context)!.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _getMatchesCount(WidgetRef ref, Player player) {
    try {
      final matchStatisticRepository = ref.read(matchStatisticRepositoryProvider);
      final playerStats = matchStatisticRepository.getStatisticsForPlayer(player.id);
      return playerStats.length;
    } catch (e) {
      return 0;
    }
  }

  // Removed _getTrainingCount method - now using player.absences directly
}
