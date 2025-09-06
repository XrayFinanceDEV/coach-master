import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/services/training_repository.dart';

class TrainingListScreen extends ConsumerWidget {
  final String teamId;
  const TrainingListScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingRepository = ref.watch(trainingRepositoryProvider);
    final trainings = trainingRepository.getTrainingsForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainings'),
      ),
      body: ListView.builder(
        itemCount: trainings.length,
        itemBuilder: (context, index) {
          final training = trainings[index];
          return ListTile(
            title: Text(training.location),
            subtitle: Text(training.date.toLocal().toIso8601String().split('T').first),
            onTap: () => context.go('/trainings/${training.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTrainingDialog(context, ref, teamId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTrainingDialog(BuildContext context, WidgetRef ref, String teamId) {
    final trainingRepository = ref.read(trainingRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String location = '';
    DateTime date = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now();
    List<String> objectives = [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Training'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => location = value!,
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
                  ListTile(
                    title: Text('Start Time: ${startTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        startTime = picked;
                      }
                    },
                  ),
                  ListTile(
                    title: Text('End Time: ${endTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        endTime = picked;
                      }
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Objectives (comma-separated)'),
                    onSaved: (value) => objectives = value!.split(',').map((e) => e.trim()).toList(),
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
                  final newTraining = Training.create(
                    teamId: teamId,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    location: location,
                    objectives: objectives,
                  );
                  trainingRepository.addTraining(newTraining);
                  ref.invalidate(trainingRepositoryProvider);
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
