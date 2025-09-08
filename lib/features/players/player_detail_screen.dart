import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_cache_utils.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PlayerDetailScreen extends ConsumerStatefulWidget {
  final String playerId;
  const PlayerDetailScreen({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {

  String _getMimeType(String fileName) {
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

  Future<String?> _saveImagePermanently(XFile imageFile) async {
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
  Widget build(BuildContext context) {
    final playerRepository = ref.watch(playerRepositoryProvider);
    final player = playerRepository.getPlayer(widget.playerId);

    if (player == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Not Found')),
        body: const Center(child: Text('Player with given ID not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text('${player.firstName} ${player.lastName}')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditPlayerDialog(context, ref, player);
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Player Profile Card with Background Image
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  // Background Image/Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: player.photoPath != null && player.photoPath!.isNotEmpty
                          ? null
                          : LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    ),
                    child: player.photoPath != null && player.photoPath!.isNotEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: kIsWeb && (player.photoPath!.startsWith('data:') || 
                                       player.photoPath!.startsWith('blob:') || 
                                       player.photoPath!.startsWith('http'))
                                    ? NetworkImage(player.photoPath!) as ImageProvider
                                    : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider 
                                      : NetworkImage(player.photoPath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Dark overlay for text readability
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            // Show initials when no photo
                            child: Text(
                              '${player.firstName[0]}${player.lastName[0]}',
                              style: const TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  
                  // Stats Badges (Top Right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Goals Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_soccer, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${player.goals}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Assists Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.assist_walker, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${player.assists}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Player Info (Bottom)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Player Name
                          Text(
                            '${player.firstName} ${player.lastName}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Player Position
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              player.position,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Player Details Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Basic Information Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Basic Information',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(context, Icons.sports, 'Preferred Foot', player.preferredFoot),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, Icons.cake, 'Birth Date', 
                            '${player.birthDate.day}/${player.birthDate.month}/${player.birthDate.year}'),
                          const SizedBox(height: 12),
                          _buildInfoRow(context, Icons.calendar_today, 'Age', 
                            '${DateTime.now().year - player.birthDate.year} years old'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Statistics Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Statistics',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(context, 'Matches', '0', Icons.sports_soccer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(context, 'Goals', '0', Icons.sports_handball),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(context, 'Assists', '0', Icons.trending_up),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(context, 'Training', '0', Icons.fitness_center),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlayerDialog(BuildContext context, WidgetRef ref, Player player) {
    final playerRepository = ref.read(playerRepositoryProvider);
    final formKey = GlobalKey<FormState>();
    String firstName = player.firstName;
    String lastName = player.lastName;
    String position = player.position;
    String preferredFoot = player.preferredFoot;
    DateTime birthDate = player.birthDate;
    String? photoPath = player.photoPath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
          title: const Text('Edit Player'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: firstName,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => firstName = value!,
                  ),
                  TextFormField(
                    initialValue: lastName,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => lastName = value!,
                  ),
                  TextFormField(
                    initialValue: position,
                    decoration: const InputDecoration(labelText: 'Position'),
                    onSaved: (value) => position = value!,
                  ),
                  TextFormField(
                    initialValue: preferredFoot,
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
                        setDialogState(() {
                          birthDate = picked;
                        });
                      }
                    },
                  ),
                  // Photo Preview Section
                  if (photoPath != null && photoPath!.isNotEmpty) ...[
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? (photoPath!.startsWith('data:') || photoPath!.startsWith('blob:') || photoPath!.startsWith('http')
                                ? Image.network(
                                    photoPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.error, color: Colors.red),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                                  ))
                            : Image.file(
                                File(photoPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Dialog preview image error: $error, path: $photoPath');
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85, // Compress to reduce file size
                        );
                        
                        if (pickedFile != null) {
                          // Validate file format
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
                          
                          // Validate file size (2MB = 2 * 1024 * 1024 bytes)
                          final int fileSize = await pickedFile.length();
                          const int maxSizeBytes = 2 * 1024 * 1024; // 2MB
                          
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
                          
                          // File is valid, save it permanently and update the photo path
                          final String? permanentPath = await _saveImagePermanently(pickedFile);
                          
                          if (permanentPath != null) {
                            setDialogState(() {
                              photoPath = permanentPath;
                            });
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
                    label: Text(photoPath != null && photoPath!.isNotEmpty ? 'Change Photo' : 'Select Photo'),
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
                  final updatedPlayer = Player(
                    id: player.id,
                    teamId: player.teamId,
                    firstName: firstName,
                    lastName: lastName,
                    position: position,
                    preferredFoot: preferredFoot,
                    birthDate: birthDate,
                    photoPath: photoPath,
                    medicalInfo: player.medicalInfo,
                    emergencyContact: player.emergencyContact,
                    goals: player.goals,
                    assists: player.assists,
                    yellowCards: player.yellowCards,
                    redCards: player.redCards,
                    totalMinutes: player.totalMinutes,
                    avgRating: player.avgRating,
                    absences: player.absences,
                  );
                  playerRepository.updatePlayer(updatedPlayer);
                  
                  // Clear image cache if photo was updated
                  if (photoPath != null && photoPath != player.photoPath) {
                    ImageCacheUtils.clearImageCacheForUpdate(player.photoPath, photoPath);
                    // Notify other screens to rebuild
                    ref.read(playerImageUpdateProvider.notifier).notifyImageUpdate();
                  }
                  
                  // Force multiple invalidations to ensure all consumers refresh
                  ref.invalidate(playerRepositoryProvider);
                  
                  // Pop dialog first
                  context.pop();
                  
                  // Small delay to ensure UI has time to process the update
                  Future.delayed(const Duration(milliseconds: 100), () {
                    // Force another invalidation after dialog closes
                    ref.invalidate(playerRepositoryProvider);
                    
                    // Force local widget rebuild like training screen
                    if (mounted) {
                      setState(() {});
                    }
                    
                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Player updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
