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
    final teamsAsync = ref.watch(teamsForSeasonStreamProvider(seasonId));

    return teamsAsync.when(
      data: (teams) => Scaffold(
        appBar: AppBar(
          title: const Text('Teams'),
        ),
        body: teams.isEmpty
            ? const Center(child: Text('No teams found. Add one to get started!'))
            : ListView.builder(
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return ListTile(
                    title: Text(team.name),
                    subtitle: team.description != null ? Text(team.description!) : null,
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
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Teams')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Teams')),
        body: Center(child: Text('Error loading teams: $error')),
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final newTeam = Team.create(
                    name: teamName,
                    seasonId: seasonId,
                    description: description,
                  );
                  await teamRepository.addTeam(newTeam);

                  // Stream will auto-update, no manual refresh needed

                  if (context.mounted) {
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
