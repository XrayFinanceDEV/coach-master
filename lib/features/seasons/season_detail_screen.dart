import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';
import 'package:coachmaster/features/teams/team_list_screen.dart';

class SeasonDetailScreen extends ConsumerWidget {
  final String seasonId;
  const SeasonDetailScreen({super.key, required this.seasonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(seasonStreamProvider(seasonId));

    return seasonAsync.when(
      data: (season) {
        if (season == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Season Not Found')),
            body: const Center(child: Text('Season with given ID not found.')),
          );
        }
        return _buildSeasonDetail(context, ref, season);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading season: $error')),
      ),
    );
  }

  Widget _buildSeasonDetail(BuildContext context, WidgetRef ref, Season season) {
    return Scaffold(
      appBar: AppBar(
        title: Text(season.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditSeasonDialog(context, ref, season);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Season'),
                  content: Text('Are you sure you want to delete ${season.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final seasonRepository = ref.read(seasonRepositoryProvider);
                        await seasonRepository.deleteSeason(season.id);
                        if (context.mounted) {
                          context.pop(); // Close dialog
                          context.go('/seasons'); // Go back to season list
                        }
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
            Text('Start Date: ${season.startDate.toLocal().toIso8601String().split('T').first}', style: Theme.of(context).textTheme.titleMedium),
            Text('End Date: ${season.endDate.toLocal().toIso8601String().split('T').first}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Expanded(
              child: TeamListScreen(seasonId: seasonId),
            )
          ],
        ),
      ),
    );
  }

  void _showEditSeasonDialog(BuildContext context, WidgetRef ref, Season season) {
    final seasonRepository = ref.read(seasonRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String seasonName = season.name;
    DateTime startDate = season.startDate;
    DateTime endDate = season.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Season'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: seasonName,
                  decoration: const InputDecoration(labelText: 'Season Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a season name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    seasonName = value!;
                  },
                ),
                ListTile(
                  title: Text('Start Date: ${startDate.toLocal().toIso8601String().split('T').first}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null && context.mounted) {
                      startDate = pickedDate;
                    }
                  },
                ),
                ListTile(
                  title: Text('End Date: ${endDate.toLocal().toIso8601String().split('T').first}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null && context.mounted) {
                      endDate = pickedDate;
                    }
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
                  final updatedSeason = Season(
                    id: season.id,
                    name: seasonName,
                    startDate: startDate,
                    endDate: endDate,
                  );
                  await seasonRepository.updateSeason(updatedSeason);
                  if (context.mounted) {
                    context.pop();
                  }
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
