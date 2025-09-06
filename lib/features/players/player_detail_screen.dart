import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/services/player_repository.dart';
import 'dart:io';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;
  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerRepository = ref.watch(playerRepositoryProvider);
    final player = playerRepository.getPlayer(playerId);

    if (player == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Not Found')),
        body: const Center(child: Text('Player with given ID not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.firstName} ${player.lastName}'),
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
                  title: const Text('Delete Player'),
                  content: Text('Are you sure you want to delete ${player.firstName} ${player.lastName}?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        playerRepository.deletePlayer(player.id);
                        ref.invalidate(playerRepositoryProvider);
                        context.pop();
                        context.go('/teams/${player.teamId}');
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
            if (player.photoPath != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: FileImage(File(player.photoPath!)),
                ),
              ),
            const SizedBox(height: 20),
            Text('Position: ${player.position}', style: Theme.of(context).textTheme.titleMedium),
            Text('Preferred Foot: ${player.preferredFoot}', style: Theme.of(context).textTheme.titleMedium),
            Text('Birth Date: ${player.birthDate.toLocal().toIso8601String().split('T').first}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            // TODO: Display player statistics
            const Text('Player Statistics (TODO)'),
          ],
        ),
      ),
    );
  }
}
