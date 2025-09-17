import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/models/note.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/features/matches/widgets/convocation_management_bottom_sheet.dart';
import 'package:coachmaster/features/matches/widgets/match_status_form.dart';
import 'package:coachmaster/features/matches/widgets/match_form_bottom_sheet.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _hasShownConvocationSheet = false;

  @override
  Widget build(BuildContext context) {
    // Watch refresh counter to trigger rebuilds when data changes
    ref.watch(refreshCounterProvider);
    
    final matchRepository = ref.watch(matchRepositoryProvider);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final convocationRepository = ref.watch(matchConvocationRepositoryProvider);
    final statisticRepository = ref.watch(matchStatisticRepositoryProvider);
    final teamRepository = ref.watch(teamRepositoryProvider);
    
    final match = matchRepository.getMatch(widget.matchId);

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.matchNotFound)),
        body: Center(child: Text(AppLocalizations.of(context)!.matchNotFoundMessage)),
      );
    }

    final players = playerRepository.getPlayersForTeam(match.teamId);
    final convocations = convocationRepository.getConvocationsForMatch(widget.matchId);
    final statistics = statisticRepository.getStatisticsForMatch(widget.matchId);
    final team = teamRepository.getTeam(match.teamId);
    final convocatedPlayers = players.where((player) => 
        convocations.any((conv) => conv.playerId == player.id)).toList();

    // Auto-open convocation management if no players are convocated and we haven't shown it yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownConvocationSheet && convocations.isEmpty && mounted) {
        _hasShownConvocationSheet = true;
        // Show a brief message before opening convocations
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Select players for this match'),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Delay slightly to let the snackbar show
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showConvocationDialog();
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_soccer, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('${AppLocalizations.of(context)!.matchVs} ${match.opponent}')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditMatchBottomSheet(match),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(match),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            // 1. Match Stats Card (auto-generated from statistics)
            _buildMatchStatsCard(match, team, statistics),
            
            const SizedBox(height: 12),
            
            // 2. Match Status Card 
            _buildMatchStatusCard(match),
            
            const SizedBox(height: 12),
            
            // 3. Edit Convocated Players Button
            _buildConvocationEditCard(convocatedPlayers.length),
            
            const SizedBox(height: 12),
            
            // 4. Notes Section
            _buildNotesSection(context, ref, match),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchStatsCard(Match match, Team? team, List<MatchStatistic> statistics) {
    final totalGoals = statistics.fold<int>(0, (sum, stat) => sum + stat.goals);
    final totalAssists = statistics.fold<int>(0, (sum, stat) => sum + stat.assists);
    final totalYellowCards = statistics.fold<int>(0, (sum, stat) => sum + stat.yellowCards);
    final totalRedCards = statistics.fold<int>(0, (sum, stat) => sum + stat.redCards);

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.matchStatistics,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Match Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        match.isHome ? Icons.home : Icons.flight_takeoff,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.isHome 
                            ? '${team?.name ?? 'Team'} vs ${match.opponent}'
                            : '${match.opponent} vs ${team?.name ?? 'Team'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(_formatDate(match.date)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(match.location)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Auto-generated stats
            if (statistics.isNotEmpty) ...[
              Text(
                AppLocalizations.of(context)!.teamPerformance,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Goals', totalGoals.toString(), Icons.sports_soccer, Colors.green)),
                  Expanded(child: _buildStatItem('Assists', totalAssists.toString(), Icons.trending_up, Colors.blue)),
                  Expanded(child: _buildStatItem('Yellow', totalYellowCards.toString(), Icons.rectangle, Colors.yellow[700]!)),
                  Expanded(child: _buildStatItem('Red', totalRedCards.toString(), Icons.rectangle, Colors.red)),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Statistics will be generated automatically after updating match status',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStatusCard(Match match) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.matchStatus,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    AppLocalizations.of(context)!.status,
                    _getStatusText(match.status),
                    _getStatusColor(match.status),
                  ),
                ),
                const SizedBox(width: 16),
                if (match.status == MatchStatus.completed && 
                    match.goalsFor != null && match.goalsAgainst != null)
                  Expanded(
                    child: _buildStatusItem(
                      AppLocalizations.of(context)!.result,
                      '${match.goalsFor}-${match.goalsAgainst}',
                      _getResultColor(match.result),
                    ),
                  )
                else
                  Expanded(
                    child: _buildStatusItem(
                      AppLocalizations.of(context)!.result,
                      AppLocalizations.of(context)!.toBeDetermined,
                      Colors.grey,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showMatchStatusForm(match),
                icon: const Icon(Icons.sports_score),
                label: Text(match.status == MatchStatus.scheduled 
                  ? AppLocalizations.of(context)!.startMatchStatusForm 
                  : AppLocalizations.of(context)!.updateMatchStatus),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildConvocationEditCard(int convocatedCount) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.convocatedPlayers,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalPlayers,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$convocatedCount',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              AppLocalizations.of(context)!.editConvocationsHelp,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _showConvocationDialog(),
                icon: const Icon(Icons.edit),
                label: Text(AppLocalizations.of(context)!.editConvocatedPlayers),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for colors and status
  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return Colors.blue;
      case MatchStatus.live:
        return Colors.orange;
      case MatchStatus.completed:
        return Colors.green;
    }
  }
  
  String _getStatusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return AppLocalizations.of(context)!.scheduled;
      case MatchStatus.live:
        return AppLocalizations.of(context)!.live;
      case MatchStatus.completed:
        return AppLocalizations.of(context)!.completed;
    }
  }
  
  Color _getResultColor(MatchResult result) {
    switch (result) {
      case MatchResult.win:
        return Colors.green;
      case MatchResult.draw:
        return Colors.orange;
      case MatchResult.loss:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showEditMatchBottomSheet(Match match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MatchFormBottomSheet(
        teamId: match.teamId,
        match: match,
        onSaved: () {
          ref.read(refreshCounterProvider.notifier).increment();
          
          ref.invalidate(matchRepositoryProvider);
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showDeleteDialog(Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMatch),
        content: Text(AppLocalizations.of(context)!.deleteMatchConfirm(match.opponent)),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final matchRepository = ref.read(matchRepositoryProvider);
              final convocationRepository = ref.read(matchConvocationRepositoryProvider);
              final statisticRepository = ref.read(matchStatisticRepositoryProvider);
              final noteRepository = ref.read(noteRepositoryProvider);
              
              // Delete related data
              await statisticRepository.deleteStatisticsForMatch(match.id);
              await convocationRepository.deleteConvocationsForMatch(match.id);
              
              // Delete notes for this match
              await noteRepository.deleteNotesForLinkedItem(match.id, linkedType: 'match');
              
              // Delete the match
              await matchRepository.deleteMatch(match.id);
              
              // Invalidate providers to refresh UI
              ref.invalidate(matchRepositoryProvider);
              ref.invalidate(matchConvocationRepositoryProvider);
              ref.invalidate(matchStatisticRepositoryProvider);
              ref.invalidate(noteRepositoryProvider);
              
              if (context.mounted) {
                context.pop();
                context.go('/matches');
              }
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _showMatchStatusForm(Match match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchStatusForm(
          match: match,
          onCompleted: () {
            ref.invalidate(matchRepositoryProvider);
            ref.invalidate(matchStatisticRepositoryProvider);
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  void _showConvocationDialog() {
    final players = ref.read(playerRepositoryProvider).getPlayersForTeam(ref.read(matchRepositoryProvider).getMatch(widget.matchId)!.teamId);
    final convocations = ref.read(matchConvocationRepositoryProvider).getConvocationsForMatch(widget.matchId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConvocationManagementBottomSheet(
        matchId: widget.matchId,
        players: players,
        convocations: convocations,
        onSaved: () {
          ref.invalidate(matchConvocationRepositoryProvider);
          ref.read(refreshCounterProvider.notifier).increment();
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, WidgetRef ref, Match match) {
    final noteRepository = ref.watch(noteRepositoryProvider);
    final notes = noteRepository.getNotesForMatch(match.id);
    
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
                  onPressed: () => _showAddNoteDialog(context, ref, match),
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                children: notes.map<Widget>((note) => _buildNoteItem(context, ref, note, match)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, WidgetRef ref, Note note, Match match) {
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
                    _showEditNoteDialog(context, ref, note, match);
                  } else if (value == 'delete') {
                    _deleteNote(context, ref, note);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
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

  void _showAddNoteDialog(BuildContext context, WidgetRef ref, Match match) {
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
        minChildSize: 0.3,
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(
                    Icons.note_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.addNote,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Text input
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your note about this match...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
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
                          // Store context before async operation
                          final navigator = Navigator.of(context);
                          
                          final noteRepository = ref.read(noteRepositoryProvider);
                          await noteRepository.createQuickNote(
                            content: controller.text.trim(),
                            type: NoteType.match,
                            linkedId: match.id,
                            linkedType: 'match',
                          );
                          
                          if (mounted) {
                            navigator.pop();
                            setState(() {}); // Refresh to show new note
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

  void _showEditNoteDialog(BuildContext context, WidgetRef ref, Note note, Match match) {
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
        minChildSize: 0.3,
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.editNote,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Text input
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your note about this match...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
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
                          // Store context before async operation
                          final navigator = Navigator.of(context);
                          
                          final noteRepository = ref.read(noteRepositoryProvider);
                          final updatedNote = Note(
                            id: note.id,
                            content: controller.text.trim(),
                            createdAt: note.createdAt,
                            updatedAt: DateTime.now(),
                            type: note.type,
                            linkedId: note.linkedId,
                            linkedType: note.linkedType,
                          );
                          await noteRepository.updateNote(updatedNote);
                          
                          if (mounted) {
                            navigator.pop();
                            setState(() {}); // Refresh to show updated note
                          }
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.updateNote),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNote),
        content: Text(AppLocalizations.of(context)!.deleteNoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              // Store context before async operation
              final navigator = Navigator.of(context);
              
              final noteRepository = ref.read(noteRepositoryProvider);
              await noteRepository.deleteNote(note.id);
              
              if (mounted) {
                navigator.pop();
                setState(() {}); // Refresh to remove deleted note
              }
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}