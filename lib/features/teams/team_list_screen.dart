import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/core/repository_instances.dart';

class TeamListScreen extends ConsumerWidget {
  final String seasonId;
  const TeamListScreen({super.key, required this.seasonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamRepository = ref.watch(teamRepositoryProvider);
    final teams = teamRepository.getTeamsForSeason(seasonId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
      ),
      body: ListView.builder(
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return ListTile(
            title: Text(team.name),
            onTap: () => context.go('/teams/${team.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTeamDialog(context, ref, seasonId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, WidgetRef ref, String seasonId) {
    final teamRepository = ref.read(teamRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String teamName = '';
    String description = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Team'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Team Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a team name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    teamName = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (value) {
                    description = value!;
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
                  final newTeam = Team.create(
                    name: teamName,
                    seasonId: seasonId,
                    description: description,
                  );
                  teamRepository.addTeam(newTeam);
                  
                  // Increment refresh counter to trigger UI rebuilds across the app
                  ref.read(refreshCounterProvider.notifier).increment();
                  
                  ref.invalidate(teamRepositoryProvider);
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
