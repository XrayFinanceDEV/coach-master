import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_cache_utils.dart';
import 'package:coachmaster/core/image_utils.dart';
import 'package:coachmaster/l10n/app_localizations.dart';
import 'package:coachmaster/services/image_crop_service.dart';
import 'package:coachmaster/services/image_compression_service.dart';
import 'package:coachmaster/services/firebase_storage_service.dart';
import 'package:coachmaster/widgets/image_crop_dialog.dart';

class PlayerFormBottomSheet extends ConsumerStatefulWidget {
  final String teamId;
  final Player? player; // null for add mode, Player instance for edit mode
  final VoidCallback? onSaved;

  const PlayerFormBottomSheet({
    super.key,
    required this.teamId,
    this.player,
    this.onSaved,
  });

  @override
  ConsumerState<PlayerFormBottomSheet> createState() => _PlayerFormBottomSheetState();
}

class _PlayerFormBottomSheetState extends ConsumerState<PlayerFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _firstName;
  late String _lastName;
  late String _position;
  late String _preferredFoot;
  late DateTime _birthDate;
  String? _photoPath;

  // Crop preview variables
  String? _tempImagePath;
  Uint8List? _tempImageBytes;
  Offset _cropOffset = const Offset(0.0, 0.3); // Default crop position

  @override
  void initState() {
    super.initState();
    // Initialize form fields with existing player data or defaults
    final player = widget.player;
    _firstName = player?.firstName ?? '';
    _lastName = player?.lastName ?? '';
    _position = player?.position ?? '';
    _preferredFoot = player?.preferredFoot ?? '';
    _birthDate = player?.birthDate ?? DateTime.now();
    _photoPath = player?.photoPath;
  }


  Future<void> _selectPhoto() async {
    try {
      if (kDebugMode) {
        print('🖼️ PlayerForm: Starting image selection for crop dialog...');
      }

      // Step 1: Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        if (kDebugMode) {
          print('🖼️ PlayerForm: User cancelled image selection');
        }
        return;
      }

      // Step 2: Store temporary image data
      if (kIsWeb) {
        _tempImageBytes = await pickedFile.readAsBytes();
        _tempImagePath = null;
      } else {
        _tempImagePath = pickedFile.path;
        _tempImageBytes = null;
      }

      // Step 3: Show crop dialog
      if (mounted) {
        final cropOffset = await showImageCropDialog(
          context: context,
          imagePath: _tempImagePath,
          imageBytes: _tempImageBytes,
        );

        if (cropOffset != null) {
          // User confirmed crop position, now process the image
          _cropOffset = cropOffset;
          await _applyCropAndProcess();
        } else {
          // User cancelled crop dialog
          setState(() {
            _tempImagePath = null;
            _tempImageBytes = null;
          });
        }
      }

      if (kDebugMode) {
        print('🖼️ PlayerForm: Image selection and crop dialog completed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (kDebugMode) {
        print('🖼️ PlayerForm: ❌ Error selecting image: $e');
      }
    }
  }

  Future<void> _applyCropAndProcess() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (kDebugMode) {
        print('🖼️ PlayerForm: Applying crop and processing image...');
      }

      // Generate a temporary player ID if this is a new player
      final playerId = widget.player?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

      // Process the already-selected image with crop positioning
      String? processedImagePath;

      if (kIsWeb && _tempImageBytes != null) {
        // Phase 1: Cropping
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('🔲 Cropping image...'),
                ],
              ),
              duration: Duration(seconds: 20),
            ),
          );
        }

        // Web: process bytes directly
        final croppedBytes = await ImageCropService.applyCropToBytes(_tempImageBytes!, _cropOffset);

        // Phase 2: Compression
        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('📦 Compressing image...'),
                ],
              ),
              duration: Duration(seconds: 15),
            ),
          );
        }

        final compressedBytes = await ImageCompressionService.compressImageData(croppedBytes);

        // Phase 3: Upload
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          if (mounted) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('☁️ Uploading to cloud...'),
                  ],
                ),
                duration: Duration(seconds: 10),
              ),
            );
          }

          processedImagePath = await FirebaseStorageService.uploadPlayerImageFromBytes(
            compressedBytes,
            playerId,
          );
        }

        if (processedImagePath == null) {
          // Fallback: base64 data URL
          final base64String = base64Encode(compressedBytes);
          processedImagePath = 'data:image/jpeg;base64,$base64String';
        }
      } else if (!kIsWeb && _tempImagePath != null) {
        // Phase 1: Cropping
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('🔲 Cropping image...'),
                ],
              ),
              duration: Duration(seconds: 20),
            ),
          );
        }

        // Mobile: process file
        final imageFile = File(_tempImagePath!);
        final croppedFile = await ImageCropService.applyCropToFile(imageFile, _cropOffset);

        // Phase 2: Compression
        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('📦 Compressing image...'),
                ],
              ),
              duration: Duration(seconds: 15),
            ),
          );
        }

        final compressedFile = await ImageCompressionService.compressImageFile(croppedFile);

        // Phase 3: Upload
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          if (mounted) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('☁️ Uploading to cloud...'),
                  ],
                ),
                duration: Duration(seconds: 10),
              ),
            );
          }

          processedImagePath = await FirebaseStorageService.uploadPlayerImage(
            compressedFile,
            playerId,
          );
        }

        processedImagePath ??= compressedFile.path;
      }

      // Clear any loading indicators
      if (mounted) {
        messenger.clearSnackBars();
      }

      if (processedImagePath != null) {
        if (mounted) {
          setState(() {
            _photoPath = processedImagePath;
            _tempImagePath = null;
            _tempImageBytes = null;
          });

          final bool isFirebaseUrl = processedImagePath.startsWith('http');
          messenger.showSnackBar(
            SnackBar(
              content: Text(isFirebaseUrl
                  ? 'Photo cropped, compressed and uploaded successfully!'
                  : 'Photo cropped, compressed and saved locally!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        if (kDebugMode) {
          print('🖼️ PlayerForm: ✅ Image processing completed: $processedImagePath');
          print('🖼️ PlayerForm: Photo path set to: $_photoPath');
        }
      } else {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Image processing failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        if (kDebugMode) {
          print('🖼️ PlayerForm: ❌ Image processing failed');
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (kDebugMode) {
        print('🖼️ PlayerForm: ❌ Error in image processing: $e');
      }
    }
  }


  Future<void> _savePlayer() async {
    if (kDebugMode) {
      print('🖼️ PlayerForm: _savePlayer called');
      print('🖼️ PlayerForm: Form validation: ${_formKey.currentState!.validate()}');
      print('🖼️ PlayerForm: Photo path: $_photoPath');
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (kDebugMode) {
        print('🖼️ PlayerForm: Form saved, player data: $_firstName $_lastName, position: $_position, photo: $_photoPath');
      }

      // Store context-dependent objects before async operations
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final playerRepository = ref.read(playerRepositoryProvider);

      try {
        if (widget.player == null) {
          // Add new player
          final newPlayer = Player.create(
            teamId: widget.teamId,
            firstName: _firstName,
            lastName: _lastName,
            position: _position,
            preferredFoot: _preferredFoot,
            birthDate: _birthDate,
            photoPath: _photoPath,
          );

          if (kDebugMode) {
            print('🖼️ PlayerForm: Creating new player: ${newPlayer.firstName} ${newPlayer.lastName}');
            print('🖼️ PlayerForm: New player photo path: ${newPlayer.photoPath}');
          }

          await playerRepository.addPlayer(newPlayer);

          if (kDebugMode) {
            print('🖼️ PlayerForm: ✅ New player added successfully');
          }
        } else {
          // Update existing player
          final updatedPlayer = Player(
            id: widget.player!.id,
            teamId: widget.player!.teamId,
            firstName: _firstName,
            lastName: _lastName,
            position: _position,
            preferredFoot: _preferredFoot,
            birthDate: _birthDate,
            photoPath: _photoPath,
            medicalInfo: widget.player!.medicalInfo,
            emergencyContact: widget.player!.emergencyContact,
            goals: widget.player!.goals,
            assists: widget.player!.assists,
            yellowCards: widget.player!.yellowCards,
            redCards: widget.player!.redCards,
            totalMinutes: widget.player!.totalMinutes,
            avgRating: widget.player!.avgRating,
            absences: widget.player!.absences,
          );

          if (kDebugMode) {
            print('🖼️ PlayerForm: Updating existing player: ${updatedPlayer.firstName} ${updatedPlayer.lastName}');
            print('🖼️ PlayerForm: Updated player photo path: ${updatedPlayer.photoPath}');
          }

          await playerRepository.updatePlayer(updatedPlayer);

          // Clear image cache if photo was updated
          if (_photoPath != null && _photoPath != widget.player!.photoPath) {
            ImageCacheUtils.clearImageCacheForUpdate(widget.player!.photoPath, _photoPath);
            // Notify other screens to rebuild
            ref.read(playerImageUpdateProvider.notifier).notifyImageUpdate();
          }

          if (kDebugMode) {
            print('🖼️ PlayerForm: ✅ Player updated successfully');
          }
        }

        widget.onSaved?.call();

        if (mounted) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(widget.player == null ? 'Player added successfully!' : 'Player updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('🖼️ PlayerForm: ❌ Error saving player: $e');
        }

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error saving player: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (kDebugMode) {
        print('🖼️ PlayerForm: ❌ Form validation failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isEditMode = widget.player != null;
    
    // Define available positions with their translation keys in logical order (defense to attack)
    final List<Map<String, String>> positions = [
      // Defense
      {'key': 'goalkeeper', 'en': 'Goalkeeper (GK)', 'it': 'Portiere (GK)'},
      {'key': 'defender', 'en': 'Defender (DF)', 'it': 'Difensore (DF)'},
      {'key': 'rightBack', 'en': 'Right-back (RB)', 'it': 'Terzino destro (RB)'},
      {'key': 'leftBack', 'en': 'Left-back (LB)', 'it': 'Terzino sinistro (LB)'},
      
      // Midfield
      {'key': 'defensiveMidfielder', 'en': 'Defending midfielder (DM)', 'it': 'Mediano difensivo (DM)'},
      {'key': 'midfielder', 'en': 'Midfielder (MF)', 'it': 'Centrocampista (MF)'},
      {'key': 'playmaker', 'en': 'Playmaker (PM)', 'it': 'Regista (PM)'},
      {'key': 'rightWinger', 'en': 'Right winger (RW)', 'it': 'Ala destra (RW)'},
      {'key': 'leftWinger', 'en': 'Left winger (LW)', 'it': 'Ala sinistra (LW)'},
      
      // Attack
      {'key': 'attackingMidfielder', 'en': 'Attacking midfielder (AM)', 'it': 'Trequartista (AM)'},
      {'key': 'secondStriker', 'en': 'Second striker (SS)', 'it': 'Seconda punta (SS)'},
      {'key': 'striker', 'en': 'Striker (ST)', 'it': 'Attaccante (ST)'},
    ];
    
    // Define available foot preferences
    final List<Map<String, String>> footPreferences = [
      {'key': 'leftFoot', 'en': 'Left Foot'},
      {'key': 'rightFoot', 'en': 'Right Foot'},
      {'key': 'bothFeet', 'en': 'Both Feet'},
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Text(
              isEditMode 
                ? (localizations?.editPlayer ?? 'Edit Player')
                : (localizations?.addNewPlayer ?? 'Add New Player'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Photo Preview Section
                      if (_photoPath != null && _photoPath!.isNotEmpty) ...[
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImageUtils.buildSafeImage(
                              imagePath: _photoPath,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorWidget: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Photo Selection Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _selectPhoto,
                          icon: const Icon(Icons.photo),
                          label: Text(_photoPath != null && _photoPath!.isNotEmpty
                              ? (localizations?.changePhoto ?? 'Change Photo')
                              : (localizations?.selectPhoto ?? 'Select Photo')),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // First Name
                      TextFormField(
                        initialValue: _firstName,
                        decoration: InputDecoration(
                          labelText: localizations?.firstName ?? 'First Name',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true 
                            ? (localizations?.required ?? 'Required') 
                            : null,
                        onSaved: (value) => _firstName = value ?? '',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Last Name
                      TextFormField(
                        initialValue: _lastName,
                        decoration: InputDecoration(
                          labelText: localizations?.lastName ?? 'Last Name',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty == true 
                            ? (localizations?.required ?? 'Required') 
                            : null,
                        onSaved: (value) => _lastName = value ?? '',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Position Dropdown
                      Builder(
                        builder: (context) {
                          // Create dropdown items based on locale
                          final currentLocale = Localizations.localeOf(context).languageCode;
                          final dropdownItems = positions.map<DropdownMenuItem<String>>((pos) {
                            String displayName;
                            
                            // Use Italian names for Italian locale, English for others
                            if (currentLocale == 'it' && pos.containsKey('it')) {
                              displayName = pos['it']!;
                            } else {
                              displayName = pos['en']!;
                            }
                            
                            return DropdownMenuItem<String>(
                              value: displayName,
                              child: Text(displayName),
                            );
                          }).toList();
                          
                          // Check if current position exists in dropdown items
                          final currentPositionExists = _position.isNotEmpty && 
                              dropdownItems.any((item) => item.value == _position);
                          
                          // If current position doesn't exist, add it as a temporary item
                          if (!currentPositionExists && _position.isNotEmpty) {
                            dropdownItems.insert(0, DropdownMenuItem<String>(
                              value: _position,
                              child: Text('$_position (current)'),
                            ));
                          }
                          
                          return DropdownButtonFormField<String>(
                            initialValue: _position.isEmpty ? null : _position,
                            decoration: InputDecoration(
                              labelText: localizations?.position ?? 'Position',
                              border: const OutlineInputBorder(),
                            ),
                            items: dropdownItems,
                            onChanged: (String? newValue) {
                              setState(() {
                                _position = newValue ?? '';
                              });
                            },
                            onSaved: (String? value) => _position = value ?? '',
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Preferred Foot Dropdown
                      Builder(
                        builder: (context) {
                          // Create dropdown items
                          final dropdownItems = footPreferences.map<DropdownMenuItem<String>>((foot) {
                            final key = foot['key']!;
                            String displayName;
                            
                            // Get localized foot preference name
                            switch (key) {
                              case 'leftFoot':
                                displayName = localizations?.leftFoot ?? foot['en']!;
                                break;
                              case 'rightFoot':
                                displayName = localizations?.rightFoot ?? foot['en']!;
                                break;
                              case 'bothFeet':
                                displayName = localizations?.bothFeet ?? foot['en']!;
                                break;
                              default:
                                displayName = foot['en']!;
                            }
                            
                            return DropdownMenuItem<String>(
                              value: displayName,
                              child: Text(displayName),
                            );
                          }).toList();
                          
                          // Check if current foot preference exists in dropdown items
                          final currentFootExists = _preferredFoot.isNotEmpty && 
                              dropdownItems.any((item) => item.value == _preferredFoot);
                          
                          // If current foot preference doesn't exist, add it as a temporary item
                          if (!currentFootExists && _preferredFoot.isNotEmpty) {
                            dropdownItems.insert(0, DropdownMenuItem<String>(
                              value: _preferredFoot,
                              child: Text('$_preferredFoot (current)'),
                            ));
                          }
                          
                          return DropdownButtonFormField<String>(
                            initialValue: _preferredFoot.isEmpty ? null : _preferredFoot,
                            decoration: InputDecoration(
                              labelText: localizations?.preferredFoot ?? 'Preferred Foot',
                              border: const OutlineInputBorder(),
                            ),
                            items: dropdownItems,
                            onChanged: (String? newValue) {
                              setState(() {
                                _preferredFoot = newValue ?? '';
                              });
                            },
                            onSaved: (String? value) => _preferredFoot = value ?? '',
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Birth Date
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _birthDate,
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              _birthDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: localizations?.birthDate ?? 'Birth Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(localizations?.cancel ?? 'Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: _savePlayer,
                              child: Text(isEditMode 
                                  ? (localizations?.save ?? 'Save')
                                  : (localizations?.add ?? 'Add')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}