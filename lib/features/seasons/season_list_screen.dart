import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/core/repository_instances.dart';

class SeasonListScreen extends ConsumerWidget {
  const SeasonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonRepository = ref.watch(seasonRepositoryProvider);
    final seasons = seasonRepository.getSeasons();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Seasons'),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: seasons.length,
        itemBuilder: (context, index) {
          final season = seasons[index];
          return ListTile(
            title: Text(season.name),
            subtitle: Text('${season.startDate.year} - ${season.endDate.year}'),
            onTap: () => context.go('/seasons/${season.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSeasonDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSeasonDialog(BuildContext context, WidgetRef ref) {
    final seasonRepository = ref.read(seasonRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String seasonName = '';
    DateTime startDate = DateTime(DateTime.now().year, 7, 1);
    DateTime endDate = DateTime(DateTime.now().year + 1, 6, 30);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Season'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
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
                    if (pickedDate != null) {
                      // Update state or rebuild dialog if necessary
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
                    if (pickedDate != null) {
                      // Update state or rebuild dialog if necessary
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  final newSeason = Season.create(
                    name: seasonName,
                    startDate: startDate,
                    endDate: endDate,
                  );
                  seasonRepository.addSeason(newSeason);
                  ref.invalidate(seasonRepositoryProvider);
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
