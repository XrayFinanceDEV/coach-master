import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/services/player_repository.dart';
import 'package:image_picker/image_picker.dart';

class PlayerListScreen extends ConsumerWidget {
  final String teamId;
  const PlayerListScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerRepository = ref.watch(playerRepositoryProvider);
    final players = playerRepository.getPlayersForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
      ),
      body: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return ListTile(
            title: Text('${player.firstName} ${player.lastName}'),
            subtitle: Text(player.position),
            onTap: () => context.go('/players/${player.id}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPlayerDialog(context, ref, teamId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref, String teamId) {
    final playerRepository = ref.read(playerRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String firstName = '';
    String lastName = '';
    String position = '';
    String preferredFoot = '';
    DateTime birthDate = DateTime.now();
    String? photoPath;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Player'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => firstName = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => lastName = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Position'),
                    onSaved: (value) => position = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Preferred Foot'),
                    onSaved: (value) => preferredFoot = value!,
                  ),
                  ListTile(
                    title: Text('Birth Date: ${birthDate.toLocal().toIso8601String().split('T').first}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: birthDate,
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        birthDate = picked;
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        photoPath = pickedFile.path;
                      }
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text('Select Photo'),
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
                  final newPlayer = Player.create(
                    teamId: teamId,
                    firstName: firstName,
                    lastName: lastName,
                    position: position,
                    preferredFoot: preferredFoot,
                    birthDate: birthDate,
                    photoPath: photoPath,
                  );
                  playerRepository.addPlayer(newPlayer);
                  ref.invalidate(playerRepositoryProvider);
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
