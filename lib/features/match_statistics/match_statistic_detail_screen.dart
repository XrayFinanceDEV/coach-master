import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/core/repository_instances.dart';

class MatchStatisticDetailScreen extends ConsumerWidget {
  final String statisticId;
  const MatchStatisticDetailScreen({super.key, required this.statisticId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchStatisticRepository = ref.watch(matchStatisticRepositoryProvider);
    final statistic = matchStatisticRepository.getStatistic(statisticId);

    if (statistic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistic Not Found')),
        body: const Center(child: Text('Statistic with given ID not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Statistic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditMatchStatisticDialog(context, ref, statistic);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Statistic'),
                  content: const Text('Are you sure you want to delete this statistic?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        matchStatisticRepository.deleteStatistic(statistic.id);
                        ref.invalidate(matchStatisticRepositoryProvider);
                        context.pop();
                        context.go('/matches/${statistic.matchId}');
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goals: ${statistic.goals}', style: Theme.of(context).textTheme.titleMedium),
            Text('Assists: ${statistic.assists}', style: Theme.of(context).textTheme.titleMedium),
            Text('Yellow Cards: ${statistic.yellowCards}', style: Theme.of(context).textTheme.titleMedium),
            Text('Red Cards: ${statistic.redCards}', style: Theme.of(context).textTheme.titleMedium),
            Text('Minutes Played: ${statistic.minutesPlayed}', style: Theme.of(context).textTheme.titleMedium),
            Text('Rating: ${statistic.rating}', style: Theme.of(context).textTheme.titleMedium),
            Text('Position: ${statistic.position ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
            Text('Notes: ${statistic.notes ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  void _showEditMatchStatisticDialog(BuildContext context, WidgetRef ref, MatchStatistic statistic) {
    final matchStatisticRepository = ref.read(matchStatisticRepositoryProvider);
    final formKey = GlobalKey<FormState>();

    int goals = statistic.goals;
    int assists = statistic.assists;
    int yellowCards = statistic.yellowCards;
    int redCards = statistic.redCards;
    int minutesPlayed = statistic.minutesPlayed;
    double? rating = statistic.rating;
    String? position = statistic.position;
    String? notes = statistic.notes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Match Statistic'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: goals.toString(),
                    decoration: const InputDecoration(labelText: 'Goals'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => goals = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    initialValue: assists.toString(),
                    decoration: const InputDecoration(labelText: 'Assists'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => assists = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    initialValue: yellowCards.toString(),
                    decoration: const InputDecoration(labelText: 'Yellow Cards'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => yellowCards = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    initialValue: redCards.toString(),
                    decoration: const InputDecoration(labelText: 'Red Cards'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => redCards = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    initialValue: minutesPlayed.toString(),
                    decoration: const InputDecoration(labelText: 'Minutes Played'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => minutesPlayed = int.tryParse(value!) ?? 0,
                  ),
                  TextFormField(
                    initialValue: rating?.toString() ?? '6.0',
                    decoration: const InputDecoration(labelText: 'Rating'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => rating = double.tryParse(value!) ?? 6.0,
                  ),
                  TextFormField(
                    initialValue: position,
                    decoration: const InputDecoration(labelText: 'Position'),
                    onSaved: (value) => position = value,
                  ),
                  TextFormField(
                    initialValue: notes,
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
                  final updatedStatistic = MatchStatistic(
                    id: statistic.id,
                    matchId: statistic.matchId,
                    playerId: statistic.playerId,
                    goals: goals,
                    assists: assists,
                    yellowCards: yellowCards,
                    redCards: redCards,
                    minutesPlayed: minutesPlayed,
                    rating: rating,
                    position: position,
                    notes: notes,
                  );
                  matchStatisticRepository.updateStatistic(updatedStatistic);
                  ref.invalidate(matchStatisticRepositoryProvider);
                  context.pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
