import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';

class MatchStatisticListScreen extends ConsumerWidget {
  final String matchId;
  final String teamId; // Required to fetch players for the dropdown

  const MatchStatisticListScreen({super.key, required this.matchId, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchStatisticRepository = ref.watch(matchStatisticRepositoryProvider);
    final statistics = matchStatisticRepository.getStatisticsForMatch(matchId);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final players = playerRepository.getPlayersForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Statistics'),
      ),
      body: ListView.builder(
        itemCount: statistics.length,
        itemBuilder: (context, index) {
          final stat = statistics[index];
          final player = players.firstWhere((p) => p.id == stat.playerId, orElse: () => Player(id: '', teamId: '', firstName: 'Unknown', lastName: 'Player', position: '', preferredFoot: '', birthDate: DateTime.now()));

          return ListTile(
            title: Text('${player.firstName} ${player.lastName}'),
            subtitle: Text('Goals: ${stat.goals}, Assists: ${stat.assists}, Rating: ${stat.rating}'),
            onTap: () => context.go('/matches/$matchId/statistics/${stat.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMatchStatisticDialog(context, ref, matchId, teamId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMatchStatisticDialog(BuildContext context, WidgetRef ref, String matchId, String teamId) {
    final matchStatisticRepository = ref.read(matchStatisticRepositoryProvider);
    final playerRepository = ref.read(playerRepositoryProvider);
    final players = playerRepository.getPlayersForTeam(teamId);
    final formKey = GlobalKey<FormState>();

    String? selectedPlayerId;
    int goals = 0;
    int assists = 0;
    int yellowCards = 0;
    int redCards = 0;
    int minutesPlayed = 0;
    double? rating = 6.0;
    String? position;
    String? notes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Match Statistic'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Player'),
                    initialValue: selectedPlayerId,
                    items: players.map((player) => DropdownMenuItem<String>(value: player.id, child: Text('${player.firstName} ${player.lastName}'))).toList(),
                    validator: (value) => value == null ? 'Required' : null,
                    onChanged: (value) => selectedPlayerId = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Goals'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => goals = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Assists'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => assists = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Yellow Cards'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => yellowCards = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Red Cards'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => redCards = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Minutes Played'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => minutesPlayed = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Rating'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => rating = double.tryParse(value!) ?? 6.0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Position'),
                    onSaved: (value) => position = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Notes'),
                    onSaved: (value) => notes = value,
                  ),
                ],
              ),
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
                  if (selectedPlayerId != null) {
                    final newStat = MatchStatistic.create(
                      matchId: matchId,
                      playerId: selectedPlayerId!,
                      goals: goals,
                      assists: assists,
                      yellowCards: yellowCards,
                      redCards: redCards,
                      minutesPlayed: minutesPlayed,
                      rating: rating,
                      position: position,
                      notes: notes,
                    );
                    matchStatisticRepository.addStatistic(newStat);
                    ref.invalidate(matchStatisticRepositoryProvider);
                    context.pop();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
