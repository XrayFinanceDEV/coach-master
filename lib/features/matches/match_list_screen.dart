import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/services/match_repository.dart';

class MatchListScreen extends ConsumerWidget {
  final String teamId;
  const MatchListScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchRepository = ref.watch(matchRepositoryProvider);
    final matches = matchRepository.getMatchesForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
      ),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return ListTile(
            title: Text('${match.opponent} (${match.isHome ? 'Home' : 'Away'})'),
            subtitle: Text(match.date.toLocal().toIso8601String().split('T').first),
            onTap: () => context.go('/matches/${match.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMatchDialog(context, ref, teamId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMatchDialog(BuildContext context, WidgetRef ref, String teamId) {
    final matchRepository = ref.read(matchRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String opponent = '';
    DateTime date = DateTime.now();
    String location = '';
    bool isHome = true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Match'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
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
                  // We need the seasonId here. For Phase 1, we'll assume a default or select one.
                  // For now, let's hardcode a dummy seasonId.
                  final newMatch = Match.create(
                    teamId: teamId,
                    seasonId: 'dummy_season_id', // TODO: Replace with actual season selection
                    opponent: opponent,
                    date: date,
                    location: location,
                    isHome: isHome,
                  );
                  matchRepository.addMatch(newMatch);
                  ref.invalidate(matchRepositoryProvider);
                  context.pop();
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
