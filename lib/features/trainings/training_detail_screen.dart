import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/services/training_repository.dart';

class TrainingDetailScreen extends ConsumerWidget {
  final String trainingId;
  const TrainingDetailScreen({super.key, required this.trainingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingRepository = ref.watch(trainingRepositoryProvider);
    final training = trainingRepository.getTraining(trainingId);

    if (training == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Training Not Found')),
        body: const Center(child: Text('Training with given ID not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Training at ${training.location}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Training'),
                  content: const Text('Are you sure you want to delete this training?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        trainingRepository.deleteTraining(training.id);
                        ref.invalidate(trainingRepositoryProvider);
                        context.pop();
                        context.go('/teams/${training.teamId}');
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
            Text('Date: ${training.date.toLocal().toIso8601String().split('T').first}', style: Theme.of(context).textTheme.titleMedium),
            Text('Time: ${training.startTime.format(context)} - ${training.endTime.format(context)}', style: Theme.of(context).textTheme.titleMedium),
            Text('Objectives: ${training.objectives.join(', ')}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            // TODO: Display training attendance
            const Text('Training Attendance (TODO)'),
          ],
        ),
      ),
    );
  }
}
