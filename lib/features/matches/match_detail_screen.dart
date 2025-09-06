import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/services/match_repository.dart';

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
              // TODO: Implement edit functionality
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
            // TODO: Display match statistics
            const Text('Match Statistics (TODO)'),
          ],
        ),
      ),
    );
  }
}
