import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';

class MatchStatisticListScreen extends ConsumerWidget {
  final String matchId;
  final String teamId; // Required to fetch players for the dropdown

  const MatchStatisticListScreen({super.key, required this.matchId, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsForMatchStreamProvider(matchId));
    final playersAsync = ref.watch(playersForTeamStreamProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Statistics'),
      ),
      body: statisticsAsync.when(
        data: (statistics) => playersAsync.when(
          data: (players) => ListView.builder(
            itemCount: statistics.length,
            itemBuilder: (context, index) {
              final stat = statistics[index];
              final player = players.firstWhere(
                (p) => p.id == stat.playerId,
                orElse: () => Player(
                  id: '',
                  teamId: '',
                  firstName: 'Unknown',
                  lastName: 'Player',
                  position: '',
                  preferredFoot: '',
                  birthDate: DateTime.now()
                )
              );

              return ListTile(
                title: Text('${player.firstName} ${player.lastName}'),
                subtitle: Text('Goals: ${stat.goals}, Assists: ${stat.assists}, Rating: ${stat.rating}'),
                onTap: () => context.go('/matches/$matchId/statistics/${stat.id}'),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error loading players: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading statistics: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMatchStatisticDialog(context, ref, matchId, teamId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMatchStatisticDialog(BuildContext context, WidgetRef ref, String matchId, String teamId) async {
    final matchStatisticRepository = ref.read(matchStatisticRepositoryProvider);
    final playerRepository = ref.read(playerRepositoryProvider);
    final players = await playerRepository.getPlayersForTeam(teamId);
    final formKey = GlobalKey<FormState>();

    if (!context.mounted) return;

    String? selectedPlayerId;
    int goals = 0;
    int assists = 0;
    int yellowCards = 0;
    int redCards = 0;
    int minutesPlayed = 0;
    double? rating = 6.0;

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
              onPressed: () async {
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
                    );
                    await matchStatisticRepository.addStatistic(newStat);
                    if (context.mounted) {
                      context.pop();
                    }
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
