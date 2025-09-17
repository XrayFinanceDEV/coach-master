import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/services/base_match_convocation_repository.dart';
import 'package:coachmaster/services/base_match_statistic_repository.dart';
import 'package:coachmaster/features/matches/widgets/match_form_bottom_sheet.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  final String teamId;
  const MatchListScreen({super.key, required this.teamId});

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  @override
  Widget build(BuildContext context) {
    final matchRepository = ref.watch(matchRepositoryProvider);
    final teamRepository = ref.watch(teamRepositoryProvider);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final convocationRepository = ref.watch(matchConvocationRepositoryProvider);
    final statisticRepository = ref.watch(matchStatisticRepositoryProvider);
    
    final matches = (matchRepository.getMatchesForTeam(widget.teamId) as List<Match>)
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date, newest first
    final team = teamRepository.getTeam(widget.teamId);
    final players = playerRepository.getPlayersForTeam(widget.teamId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_soccer, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.matches),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMatchBottomSheet,
            tooltip: AppLocalizations.of(context)!.addMatch,
          ),
        ],
      ),
      body: matches.isEmpty 
        ? _buildEmptyState()
        : Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _buildMatchCard(match, team, players, convocationRepository, statisticRepository);
                  },
                ),
              ),
              
              // Add Match button at bottom
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _showAddMatchBottomSheet,
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.addMatch),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
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
            Icons.sports_soccer,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noMatchesScheduled,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createFirstMatchToStart,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddMatchBottomSheet,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createFirstMatch),
          ),
        ],
      ),
    );
  }


  Widget _buildMatchCard(Match match, team, List<Player> players, 
      BaseMatchConvocationRepository convocationRepository, 
      BaseMatchStatisticRepository statisticRepository) {
    // Get convocation data for this match
    final convocationsData = convocationRepository.getConvocationsForMatch(match.id);
    final convocationCount = convocationsData.length;
    
    // Check if match has been completed (has statistics)
    final hasStatistics = statisticRepository.getStatisticsForMatch(match.id).isNotEmpty;
    final isCompleted = match.status == MatchStatus.completed;

    return InkWell(
      onTap: () => _showMatchDetail(match),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      match.isHome ? Icons.home : Icons.flight_takeoff,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.isHome 
                            ? '${team?.name ?? 'Team'} vs ${match.opponent}'
                            : '${match.opponent} vs ${team?.name ?? 'Team'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(match.date),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                match.location,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted && match.goalsFor != null && match.goalsAgainst != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getResultColor(match.result).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getResultColor(match.result)),
                      ),
                      child: Text(
                        '${match.goalsFor}-${match.goalsAgainst}',
                        style: TextStyle(
                          color: _getResultColor(match.result),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditMatchBottomSheet(match);
                      } else if (value == 'delete') {
                        _deleteMatch(match);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.delete),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status Row
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: convocationCount > 0 ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group,
                          size: 14,
                          color: convocationCount > 0 ? Colors.green[700] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$convocationCount ${AppLocalizations.of(context)!.convocated}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: convocationCount > 0 ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(match.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(match.status),
                          size: 14,
                          color: _getStatusColor(match.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(match.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(match.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasStatistics)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.analytics, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.statsSaved,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
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
  
  IconData _getStatusIcon(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return Icons.schedule;
      case MatchStatus.live:
        return Icons.play_circle;
      case MatchStatus.completed:
        return Icons.check_circle;
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
  
  void _showMatchDetail(Match match) {
    context.push('/matches/${match.id}');
  }
  
  void _showAddMatchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MatchFormBottomSheet(
        teamId: widget.teamId,
        onSaved: () {
          ref.invalidate(matchRepositoryProvider);
          if (mounted) {
            setState(() {});
          }
        },
        onMatchCreated: (matchId) {
          // Navigate directly to match detail for convocation management
          context.go('/matches/$matchId');
        },
      ),
    );
  }
  
  void _showEditMatchBottomSheet(Match match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MatchFormBottomSheet(
        teamId: widget.teamId,
        match: match,
        onSaved: () {
          ref.invalidate(matchRepositoryProvider);
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _deleteMatch(Match match) {
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
              
              // Force a rebuild to ensure UI updates
              if (mounted) {
                setState(() {});
              }
              
              if (context.mounted) {
                context.pop();
              }
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}