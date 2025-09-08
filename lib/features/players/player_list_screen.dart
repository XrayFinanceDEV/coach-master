import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_cache_utils.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';

class PlayerListScreen extends ConsumerWidget {
  final String teamId;
  const PlayerListScreen({super.key, required this.teamId});

  static String _getMimeType(String fileName) {
    final String ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg'; // default fallback
    }
  }

  static Future<String?> _saveImagePermanently(XFile imageFile) async {
    try {
      if (kIsWeb) {
        // On web, convert to base64 data URL for permanent storage
        final bytes = await imageFile.readAsBytes();
        final String base64String = base64Encode(bytes);
        final String mimeType = _getMimeType(imageFile.name);
        final String dataUrl = 'data:$mimeType;base64,$base64String';
        debugPrint('✅ Web image converted to data URL (${bytes.length} bytes)');
        return dataUrl;
      }
      
      // Get the app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      
      // Create a players directory if it doesn't exist
      final Directory playersDir = Directory('$appDocPath/players');
      if (!await playersDir.exists()) {
        await playersDir.create(recursive: true);
      }
      
      // Generate a unique filename using timestamp and original extension
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String permanentPath = '${playersDir.path}/$fileName';
      
      // Copy the file to permanent location
      final File sourceFile = File(imageFile.path);
      final File permanentFile = await sourceFile.copy(permanentPath);
      
      // Verify the file was copied successfully
      if (await permanentFile.exists()) {
        final int fileSize = await permanentFile.length();
        debugPrint('✅ Image saved successfully: $permanentPath ($fileSize bytes)');
        return permanentFile.path;
      } else {
        debugPrint('❌ Failed to save image file');
        return null;
      }
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final playerRepository = ref.watch(playerRepositoryProvider);
    // Watch for image updates to force rebuilds
    ref.watch(playerImageUpdateProvider);
    final players = playerRepository.getPlayersForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.players ?? 'Players'),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  key: ValueKey('${player.id}-${player.photoPath}'), // Force rebuild when photo changes
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: player.photoPath != null && player.photoPath!.isNotEmpty
                      ? (kIsWeb && (player.photoPath!.startsWith('data:') || player.photoPath!.startsWith('blob:') || player.photoPath!.startsWith('http'))
                          ? NetworkImage(player.photoPath!) as ImageProvider
                          : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider : null))
                      : null,
                  child: player.photoPath == null || player.photoPath!.isEmpty ||
                      (kIsWeb && !player.photoPath!.startsWith('data:') && !player.photoPath!.startsWith('blob:') && !player.photoPath!.startsWith('http'))
                      ? Text(
                          '${player.firstName[0]}${player.lastName[0]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  '${player.firstName} ${player.lastName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      player.position,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (player.goals > 0 || player.assists > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${player.goals} goals • ${player.assists} assists',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () => context.go('/players/${player.id}'),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPlayerDialog(context, ref, teamId, localizations);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref, String teamId, AppLocalizations? localizations) {
    final playerRepository = ref.read(playerRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String firstName = '';
    String lastName = '';
    String position = '';
    String preferredFoot = '';
    DateTime birthDate = DateTime.now();
    String? photoPath;
    
    // Define available positions with their translation keys
    final List<Map<String, String>> positions = [
      {'key': 'goalkeeper', 'en': 'Goalkeeper'},
      {'key': 'centerBack', 'en': 'Center Back'},
      {'key': 'leftBack', 'en': 'Left Back'},
      {'key': 'rightBack', 'en': 'Right Back'},
      {'key': 'defensiveMidfielder', 'en': 'Defensive Midfielder'},
      {'key': 'centralMidfielder', 'en': 'Central Midfielder'},
      {'key': 'attackingMidfielder', 'en': 'Attacking Midfielder'},
      {'key': 'leftWinger', 'en': 'Left Winger'},
      {'key': 'rightWinger', 'en': 'Right Winger'},
      {'key': 'striker', 'en': 'Striker'},
    ];
    
    // Define available foot preferences
    final List<Map<String, String>> footPreferences = [
      {'key': 'leftFoot', 'en': 'Left Foot'},
      {'key': 'rightFoot', 'en': 'Right Foot'},
      {'key': 'bothFeet', 'en': 'Both Feet'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentLocalizations = AppLocalizations.of(context);
            
            return AlertDialog(
              title: Text(currentLocalizations?.addNewPlayer ?? 'Add New Player'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: currentLocalizations?.firstName ?? 'First Name'),
                        validator: (value) => value!.isEmpty ? (currentLocalizations?.required ?? 'Required') : null,
                        onSaved: (value) => firstName = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: currentLocalizations?.lastName ?? 'Last Name'),
                        validator: (value) => value!.isEmpty ? (currentLocalizations?.required ?? 'Required') : null,
                        onSaved: (value) => lastName = value!,
                      ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: currentLocalizations?.position ?? 'Position',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      initialValue: position.isEmpty ? null : position,
                      items: positions.map<DropdownMenuItem<String>>((pos) {
                        final key = pos['key']!;
                        String displayName;
                        
                        // Get localized position name using reflection-like approach
                        switch (key) {
                          case 'goalkeeper':
                            displayName = currentLocalizations?.goalkeeper ?? pos['en']!;
                            break;
                          case 'centerBack':
                            displayName = currentLocalizations?.centerBack ?? pos['en']!;
                            break;
                          case 'leftBack':
                            displayName = currentLocalizations?.leftBack ?? pos['en']!;
                            break;
                          case 'rightBack':
                            displayName = currentLocalizations?.rightBack ?? pos['en']!;
                            break;
                          case 'defensiveMidfielder':
                            displayName = currentLocalizations?.defensiveMidfielder ?? pos['en']!;
                            break;
                          case 'centralMidfielder':
                            displayName = currentLocalizations?.centralMidfielder ?? pos['en']!;
                            break;
                          case 'attackingMidfielder':
                            displayName = currentLocalizations?.attackingMidfielder ?? pos['en']!;
                            break;
                          case 'leftWinger':
                            displayName = currentLocalizations?.leftWinger ?? pos['en']!;
                            break;
                          case 'rightWinger':
                            displayName = currentLocalizations?.rightWinger ?? pos['en']!;
                            break;
                          case 'striker':
                            displayName = currentLocalizations?.striker ?? pos['en']!;
                            break;
                          default:
                            displayName = pos['en']!;
                        }
                        
                        return DropdownMenuItem<String>(
                          value: displayName,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        position = newValue ?? '';
                      },
                      onSaved: (String? value) => position = value ?? '',
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: currentLocalizations?.preferredFoot ?? 'Preferred Foot',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      initialValue: preferredFoot.isEmpty ? null : preferredFoot,
                      items: footPreferences.map<DropdownMenuItem<String>>((foot) {
                        final key = foot['key']!;
                        String displayName;
                        
                        // Get localized foot preference name
                        switch (key) {
                          case 'leftFoot':
                            displayName = currentLocalizations?.leftFoot ?? foot['en']!;
                            break;
                          case 'rightFoot':
                            displayName = currentLocalizations?.rightFoot ?? foot['en']!;
                            break;
                          case 'bothFeet':
                            displayName = currentLocalizations?.bothFeet ?? foot['en']!;
                            break;
                          default:
                            displayName = foot['en']!;
                        }
                        
                        return DropdownMenuItem<String>(
                          value: displayName,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        preferredFoot = newValue ?? '';
                      },
                      onSaved: (String? value) => preferredFoot = value ?? '',
                    ),
                  ),
                      ListTile(
                        title: Text('${currentLocalizations?.birthDate ?? 'Birth Date'}: ${birthDate.toLocal().toIso8601String().split('T').first}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: birthDate,
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              birthDate = picked;
                            });
                          }
                        },
                          ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            
                            if (pickedFile != null) {
                              final String fileName = pickedFile.name.toLowerCase();
                              final List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
                              final bool isValidFormat = allowedExtensions.any((ext) => fileName.endsWith('.$ext'));
                              
                              if (!isValidFormat) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a valid image format (JPG, PNG, WEBP)'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                                return;
                              }
                              
                              final int fileSize = await pickedFile.length();
                              const int maxSizeBytes = 2 * 1024 * 1024;
                              
                              if (fileSize > maxSizeBytes) {
                                if (context.mounted) {
                                  final double fileSizeMB = fileSize / (1024 * 1024);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Image is too large (${fileSizeMB.toStringAsFixed(1)}MB). Please select an image smaller than 2MB.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                                return;
                              }
                              
                              final String? permanentPath = await _saveImagePermanently(pickedFile);
                              
                              if (permanentPath != null) {
                                photoPath = permanentPath;
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to save photo. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Photo selected successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error selecting photo: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.photo),
                        label: Text(currentLocalizations?.selectPhoto ?? 'Select Photo'),
                      ),
                ],
              ),
            ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(currentLocalizations?.cancel ?? 'Cancel'),
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
                  child: Text(currentLocalizations?.add ?? 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
