import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/services/match_convocation_repository.dart';
import 'package:coachmaster/services/match_statistic_repository.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  final String teamId;
  const MatchListScreen({super.key, required this.teamId});

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen> {
  String? selectedMatchId; // For managing convocations/statistics
  String selectedMode = 'convocations'; // 'convocations' or 'statistics'
  List<String> convocations = []; // Selected players for convocations
  Map<String, Map<String, dynamic>> playerStats = {}; // Player statistics
  int goalsFor = 0;
  int goalsAgainst = 0;
  int autoGoals = 0;

  @override
  Widget build(BuildContext context) {
    final matchRepository = ref.watch(matchRepositoryProvider);
    final teamRepository = ref.watch(teamRepositoryProvider);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final convocationRepository = ref.watch(matchConvocationRepositoryProvider);
    final statisticRepository = ref.watch(matchStatisticRepositoryProvider);
    
    final matches = matchRepository.getMatchesForTeam(widget.teamId);
    final team = teamRepository.getTeam(widget.teamId);
    final players = playerRepository.getPlayersForTeam(widget.teamId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sports_soccer, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Matches'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMatchDialog(),
            tooltip: 'Add Match',
          ),
        ],
      ),
      body: matches.isEmpty 
        ? _buildEmptyState()
        : Column(
            children: [
              // Add Match Section
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
                            'Create New Match',
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
                          onPressed: () => _showAddMatchDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Match'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Matches History Section
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
                              'Match History',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final match = matches[index];
                            return _buildMatchCard(match, team, players, convocationRepository, statisticRepository);
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
            Icons.sports_soccer,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Matches Scheduled',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first match to start managing convocations and statistics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddMatchDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create First Match'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match, team, List<Player> players, 
      MatchConvocationRepository convocationRepository, 
      MatchStatisticRepository statisticRepository) {
    // Get convocation data for this match
    final convocationsData = convocationRepository.getConvocationsForMatch(match.id);
    final convocationCount = convocationsData.length;
    
    // Check if match has been completed (has statistics)
    final hasStatistics = statisticRepository.getStatisticsForMatch(match.id).isNotEmpty;
    final isCompleted = match.goalsFor != null && match.goalsAgainst != null;
    final isSelected = selectedMatchId == match.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            // Match Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    match.location,
                                    style: TextStyle(color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteMatch(match);
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
                  
                  const SizedBox(height: 12),
                  
                  // Status Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: convocationCount > 0 ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$convocationCount convocated',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: convocationCount > 0 ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Result: ${match.goalsFor}-${match.goalsAgainst}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      if (hasStatistics) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '📊 Stats saved',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow[800],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                      onPressed: () => _toggleMatchSelection(match.id, 'convocations', convocationRepository),
                      icon: Icon(isSelected && selectedMode == 'convocations' ? Icons.close : Icons.edit_note),
                      label: Text(isSelected && selectedMode == 'convocations' ? 'Close' : 'Convocations'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: convocationCount > 0 
                          ? () => _toggleMatchSelection(match.id, 'statistics', statisticRepository)
                          : null,
                      icon: Icon(isSelected && selectedMode == 'statistics' ? Icons.close : Icons.analytics),
                      label: Text(isSelected && selectedMode == 'statistics' ? 'Close' : 'Match Data'),
                    ),
                  ),
                ],
              ),
            ),

            // Expandable Section
            if (isSelected) ...[
              const Divider(height: 1),
              selectedMode == 'convocations' 
                  ? _buildConvocationManagement(match, players, convocationRepository)
                  : _buildStatisticsManagement(match, players, statisticRepository),
            ],

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildConvocationManagement(Match match, List<Player> players, MatchConvocationRepository convocationRepository) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Convocations vs ${match.opponent}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select players convocated for the match on ${_formatDate(match.date)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          // Select All/None
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: convocations.length == players.length && players.isNotEmpty,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        convocations = players.map((p) => p.id).toList();
                      } else {
                        convocations = [];
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  '⚡ Convocate all (${players.length} players)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Players Grid
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
              final isSelected = convocations.contains(player.id);
              
              return InkWell(
                onTap: () => _togglePlayerConvocation(player.id),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[100],
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${player.firstName} ${player.lastName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700],
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
              onPressed: () => _saveConvocations(match.id, convocationRepository),
              icon: const Icon(Icons.save),
              label: const Text('Save Convocations'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsManagement(Match match, List<Player> players, MatchStatisticRepository statisticRepository) {
    final teamRepository = ref.read(teamRepositoryProvider);
    final team = teamRepository.getTeam(widget.teamId);
    final convocatedPlayerIds = convocations.isNotEmpty 
        ? convocations 
        : ref.read(matchConvocationRepositoryProvider).getConvocationsForMatch(match.id).map((c) => c.playerId).toList();
    
    final convocatedPlayers = players.where((p) => convocatedPlayerIds.contains(p.id)).toList();
    
    if (convocatedPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.orange[50],
        child: Text(
          'No players convocated for this match. Please set convocations first.',
          style: TextStyle(color: Colors.orange[800]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Post-Match Data vs ${match.opponent}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter match result and individual player statistics',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          // Match Result
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: match.isHome 
                        ? '${team?.name ?? 'Team'} Goals'
                        : '${match.opponent} Goals',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: match.isHome ? (match.goalsFor?.toString() ?? goalsFor.toString()) : (match.goalsAgainst?.toString() ?? goalsAgainst.toString()),
                  onChanged: (value) => setState(() {
                    if (match.isHome) {
                      goalsFor = int.tryParse(value) ?? 0;
                    } else {
                      goalsAgainst = int.tryParse(value) ?? 0;
                    }
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: match.isHome 
                        ? '${match.opponent} Goals'
                        : '${team?.name ?? 'Team'} Goals',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: match.isHome ? (match.goalsAgainst?.toString() ?? goalsAgainst.toString()) : (match.goalsFor?.toString() ?? goalsFor.toString()),
                  onChanged: (value) => setState(() {
                    if (match.isHome) {
                      goalsAgainst = int.tryParse(value) ?? 0;
                    } else {
                      goalsFor = int.tryParse(value) ?? 0;
                    }
                  }),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Player Statistics Table
          Text(
            'Player Statistics',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Table Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('Y', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('Min', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          
          // Player Statistics Rows
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: convocatedPlayers.map((player) => _buildPlayerStatRow(player)).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _saveMatchStatistics(match, statisticRepository),
              icon: const Icon(Icons.save),
              label: const Text('Save Match Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatRow(Player player) {
    final stats = playerStats[player.id] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${player.firstName} ${player.lastName}',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                initialValue: stats['goals']?.toString() ?? '0',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(4),
                ),
                onChanged: (value) => _updatePlayerStat(player.id, 'goals', int.tryParse(value) ?? 0),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                initialValue: stats['assists']?.toString() ?? '0',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(4),
                ),
                onChanged: (value) => _updatePlayerStat(player.id, 'assists', int.tryParse(value) ?? 0),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                initialValue: stats['yellow']?.toString() ?? '0',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(4),
                ),
                onChanged: (value) => _updatePlayerStat(player.id, 'yellow', (int.tryParse(value) ?? 0).clamp(0, 2)),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                initialValue: stats['red']?.toString() ?? '0',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(4),
                ),
                onChanged: (value) => _updatePlayerStat(player.id, 'red', (int.tryParse(value) ?? 0).clamp(0, 1)),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                initialValue: stats['minutes']?.toString() ?? '0',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(4),
                ),
                onChanged: (value) => _updatePlayerStat(player.id, 'minutes', (int.tryParse(value) ?? 0).clamp(0, 120)),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                initialValue: stats['rating']?.toString() ?? '6.0',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(4),
                ),
                onChanged: (value) => _updatePlayerStat(player.id, 'rating', (double.tryParse(value) ?? 6.0).clamp(1.0, 10.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMatchDialog() {
    final matchRepository = ref.read(matchRepositoryProvider);
    final teamRepository = ref.read(teamRepositoryProvider);
    final team = teamRepository.getTeam(widget.teamId);
    final formKey = GlobalKey<FormState>();
    String opponent = '';
    DateTime date = DateTime.now();
    String location = '';
    bool isHome = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Match'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Opponent',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onSaved: (value) => opponent = value!,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            date = picked;
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
                            Text('Date: ${_formatDate(date)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onSaved: (value) => location = value!,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Home Match'),
                      subtitle: Text(isHome ? '🏠 Playing at home' : '✈️ Playing away'),
                      value: isHome,
                      onChanged: (value) {
                        setDialogState(() {
                          isHome = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      if (team != null) {
                        final newMatch = Match.create(
                          teamId: widget.teamId,
                          seasonId: team.seasonId,
                          opponent: opponent,
                          date: date,
                          location: location,
                          isHome: isHome,
                        );
                        matchRepository.addMatch(newMatch);
                        ref.invalidate(matchRepositoryProvider);
                        context.pop();
                        
                        // Auto-open convocations for new match
                        setState(() {
                          selectedMatchId = newMatch.id;
                          selectedMode = 'convocations';
                          convocations = [];
                        });
                      }
                    }
                  },
                  child: const Text('Create Match'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteMatch(Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: Text('Are you sure you want to delete the match vs ${match.opponent}?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final matchRepository = ref.read(matchRepositoryProvider);
              final convocationRepository = ref.read(matchConvocationRepositoryProvider);
              final statisticRepository = ref.read(matchStatisticRepositoryProvider);
              
              // Delete related data
              statisticRepository.deleteStatisticsForMatch(match.id);
              final convocationsData = convocationRepository.getConvocationsForMatch(match.id);
              for (final convocation in convocationsData) {
                convocationRepository.deleteConvocation(convocation.id);
              }
              
              // Delete the match
              matchRepository.deleteMatch(match.id);
              
              ref.invalidate(matchRepositoryProvider);
              ref.invalidate(matchConvocationRepositoryProvider);
              ref.invalidate(matchStatisticRepositoryProvider);
              
              context.pop();
              
              // Close management if this match was selected
              if (selectedMatchId == match.id) {
                setState(() {
                  selectedMatchId = null;
                });
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleMatchSelection(String matchId, String mode, dynamic repository) {
    setState(() {
      if (selectedMatchId == matchId && selectedMode == mode) {
        selectedMatchId = null;
        selectedMode = 'convocations';
      } else {
        selectedMatchId = matchId;
        selectedMode = mode;
        
        if (mode == 'convocations') {
          _loadConvocations(matchId, repository as MatchConvocationRepository);
        } else {
          _loadStatistics(matchId, repository as MatchStatisticRepository);
        }
      }
    });
  }

  void _loadConvocations(String matchId, MatchConvocationRepository repository) {
    final convocationsData = repository.getConvocationsForMatch(matchId);
    setState(() {
      convocations = convocationsData.map((c) => c.playerId).toList();
    });
  }

  void _loadStatistics(String matchId, MatchStatisticRepository repository) {
    final statistics = repository.getStatisticsForMatch(matchId);
    final stats = <String, Map<String, dynamic>>{};
    
    for (final stat in statistics) {
      stats[stat.playerId] = {
        'goals': stat.goals,
        'assists': stat.assists,
        'yellow': stat.yellowCards,
        'red': stat.redCards,
        'minutes': stat.minutesPlayed,
        'rating': stat.rating ?? 6.0,
      };
    }
    
    setState(() {
      playerStats = stats;
    });
  }

  void _togglePlayerConvocation(String playerId) {
    setState(() {
      if (convocations.contains(playerId)) {
        convocations.remove(playerId);
      } else {
        convocations.add(playerId);
      }
    });
  }

  void _updatePlayerStat(String playerId, String statName, dynamic value) {
    setState(() {
      if (!playerStats.containsKey(playerId)) {
        playerStats[playerId] = {};
      }
      playerStats[playerId]![statName] = value;
    });
  }

  void _saveConvocations(String matchId, MatchConvocationRepository repository) async {
    // Clear existing convocations
    final existingConvocations = repository.getConvocationsForMatch(matchId);
    for (final convocation in existingConvocations) {
      await repository.deleteConvocation(convocation.id);
    }
    
    // Save new convocations
    for (final playerId in convocations) {
      final convocation = MatchConvocation.create(
        matchId: matchId,
        playerId: playerId,
      );
      await repository.addConvocation(convocation);
    }
    
    // Refresh UI
    ref.invalidate(matchConvocationRepositoryProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convocations saved successfully!')),
      );
    }
  }

  void _saveMatchStatistics(Match match, MatchStatisticRepository repository) async {
    final matchRepository = ref.read(matchRepositoryProvider);
    final playerRepository = ref.read(playerRepositoryProvider);
    
    // Update match result
    final updatedMatch = Match(
      id: match.id,
      teamId: match.teamId,
      seasonId: match.seasonId,
      opponent: match.opponent,
      date: match.date,
      location: match.location,
      isHome: match.isHome,
      goalsFor: match.isHome ? goalsFor : goalsAgainst,
      goalsAgainst: match.isHome ? goalsAgainst : goalsFor,
      result: _calculateMatchResult(match.isHome ? goalsFor : goalsAgainst, match.isHome ? goalsAgainst : goalsFor),
      status: MatchStatus.completed,
      tactics: match.tactics,
    );
    
    await matchRepository.updateMatch(updatedMatch);
    
    // Save player statistics
    final statisticsToSave = <MatchStatistic>[];
    for (final entry in playerStats.entries) {
      final playerId = entry.key;
      final stats = entry.value;
      
      final statistic = MatchStatistic.create(
        matchId: match.id,
        playerId: playerId,
        goals: stats['goals'] ?? 0,
        assists: stats['assists'] ?? 0,
        yellowCards: stats['yellow'] ?? 0,
        redCards: stats['red'] ?? 0,
        minutesPlayed: stats['minutes'] ?? 0,
        rating: stats['rating']?.toDouble() ?? 6.0,
      );
      
      statisticsToSave.add(statistic);
    }
    
    await repository.updateMatchStatistics(match.id, statisticsToSave);
    
    // Update player overall statistics
    final allStatistics = repository.getStatistics();
    final players = playerRepository.getPlayersForTeam(widget.teamId);
    
    for (final player in players) {
      await playerRepository.updatePlayerStatisticsFromMatchStats(player.id, allStatistics);
    }
    
    // Refresh UI
    ref.invalidate(matchRepositoryProvider);
    ref.invalidate(matchStatisticRepositoryProvider);
    ref.invalidate(playerRepositoryProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match statistics saved successfully!')),
      );
    }
  }

  MatchResult _calculateMatchResult(int goalsFor, int goalsAgainst) {
    if (goalsFor > goalsAgainst) return MatchResult.win;
    if (goalsFor < goalsAgainst) return MatchResult.loss;
    return MatchResult.draw;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
