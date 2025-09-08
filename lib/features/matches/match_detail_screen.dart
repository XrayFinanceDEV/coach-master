import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/core/repository_instances.dart';

class MatchDetailScreen extends ConsumerWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchRepository = ref.watch(matchRepositoryProvider);
    final match = matchRepository.getMatch(matchId);

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Not Found')),
        body: const Center(child: Text('Match with given ID not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Match vs ${match.opponent}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditMatchDialog(context, ref, match);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Match'),
                  content: const Text('Are you sure you want to delete this match?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        matchRepository.deleteMatch(match.id);
                        ref.invalidate(matchRepositoryProvider);
                        context.pop();
                        context.go('/teams/${match.teamId}');
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
            Text('Date: ${match.date.toLocal().toIso8601String().split('T').first}', style: Theme.of(context).textTheme.titleMedium),
            Text('Location: ${match.location}', style: Theme.of(context).textTheme.titleMedium),
            Text('Type: ${match.isHome ? 'Home' : 'Away'}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/matches/${match.id}/statistics', extra: match.teamId);
              },
              child: const Text('View Statistics'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMatchDialog(BuildContext context, WidgetRef ref, Match match) {
    final matchRepository = ref.read(matchRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String opponent = match.opponent;
    DateTime date = match.date;
    String location = match.location;
    bool isHome = match.isHome;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Match'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: opponent,
                    decoration: const InputDecoration(labelText: 'Opponent'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => opponent = value!,
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
                  TextFormField(
                    initialValue: location,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => location = value!,
                  ),
                  SwitchListTile(
                    title: const Text('Home Match'),
                    value: isHome,
                    onChanged: (value) {
                      isHome = value;
                    },
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
                  final updatedMatch = Match(
                    id: match.id,
                    teamId: match.teamId,
                    seasonId: match.seasonId,
                    opponent: opponent,
                    date: date,
                    location: location,
                    isHome: isHome,
                    goalsFor: match.goalsFor,
                    goalsAgainst: match.goalsAgainst,
                    result: match.result,
                    status: match.status,
                    tactics: match.tactics,
                  );
                  matchRepository.updateMatch(updatedMatch);
                  ref.invalidate(matchRepositoryProvider);
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
