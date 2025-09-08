import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/features/players/player_list_screen.dart';
import 'package:coachmaster/features/trainings/training_list_screen.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamRepository = ref.watch(teamRepositoryProvider);
    final team = teamRepository.getTeam(teamId);

    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Not Found')),
        body: const Center(child: Text('Team with given ID not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.groups, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(team.name)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditTeamDialog(context, ref, team);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Team'),
                  content: Text('Are you sure you want to delete ${team.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        teamRepository.deleteTeam(team.id);
                        ref.invalidate(teamRepositoryProvider);
                        context.pop();
                        context.go('/seasons/${team.seasonId}');
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
            Text('Description: ${team.description ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  const Text('Players in this team:'),
                  Expanded(
                    child: PlayerListScreen(teamId: teamId),
                  ),
                  const Text('Trainings for this team:'),
                  Expanded(
                    child: TrainingListScreen(teamId: teamId),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/teams/${team.id}/matches');
                    },
                    child: const Text('View Matches'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, WidgetRef ref, Team team) {
    final teamRepository = ref.read(teamRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String teamName = team.name;
    String description = team.description ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Team'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: teamName,
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
                  initialValue: description,
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
                  final updatedTeam = Team(
                    id: team.id,
                    seasonId: team.seasonId,
                    name: teamName,
                    description: description,
                    logoPath: team.logoPath,
                  );
                  teamRepository.updateTeam(updatedTeam);
                  ref.invalidate(teamRepositoryProvider);
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
