import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coachmaster/services/image_compression_service.dart';
import 'package:coachmaster/services/firebase_storage_service.dart';
import 'package:coachmaster/models/player.dart';

class PlayerImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Complete workflow: Pick -> Compress -> Upload -> Return URL
  /// This method handles the entire image workflow for player photos
  static Future<String?> pickAndProcessPlayerImage(String playerId) async {
    try {
      if (kDebugMode) {
        print('🖼️ PlayerImage: Starting image workflow for player $playerId');
      }

      // Step 1: Pick image from gallery or camera
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080, // Initial max width to reduce picker load
        maxHeight: 1920, // Initial max height for 9:16 ratio
        imageQuality: 90, // High quality for initial pick
      );

      if (pickedFile == null) {
        if (kDebugMode) {
          print('🖼️ PlayerImage: User cancelled image selection');
        }
        return null;
      }

      if (kDebugMode) {
        print('🖼️ PlayerImage: Image picked: ${pickedFile.path}');
      }

      // Step 2: Process the image (compress and resize)
      if (kIsWeb) {
        // On web, work with bytes directly and upload without creating temp files
        final imageBytes = await pickedFile.readAsBytes();
        final processedBytes = await ImageCompressionService.processPlayerImageFromBytes(imageBytes);
        
        // Step 3: Upload to Firebase Storage directly (if user is authenticated)
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          if (kDebugMode) {
            print('🖼️ PlayerImage: Uploading to Firebase Storage...');
          }

          final downloadUrl = await FirebaseStorageService.uploadPlayerImageFromBytes(
            processedBytes,
            playerId,
          );

          if (downloadUrl != null) {
            if (kDebugMode) {
              print('🖼️ PlayerImage: ✅ Complete workflow finished successfully');
              print('🖼️ PlayerImage: Download URL: $downloadUrl');
            }
            
            return downloadUrl;
          } else {
            if (kDebugMode) {
              print('🖼️ PlayerImage: ❌ Upload failed, using base64 fallback');
            }
            // Fallback: return base64 data URL for web
            final base64String = base64Encode(processedBytes);
            return 'data:image/jpeg;base64,$base64String';
          }
        } else {
          if (kDebugMode) {
            print('🖼️ PlayerImage: No authenticated user, using base64 data URL');
          }
          // No authentication: return base64 data URL
          final base64String = base64Encode(processedBytes);
          return 'data:image/jpeg;base64,$base64String';
        }
      } else {
        // Mobile: use file-based processing
        final imageFile = File(pickedFile.path);
        final processedFile = await ImageCompressionService.processPlayerImage(imageFile);

        // Step 3: Upload to Firebase Storage (if user is authenticated)
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          if (kDebugMode) {
            print('🖼️ PlayerImage: Uploading to Firebase Storage...');
          }

          final downloadUrl = await FirebaseStorageService.uploadPlayerImage(
            processedFile, 
            playerId,
          );

          if (downloadUrl != null) {
            // Clean up temporary files
            await _cleanupTempFiles([processedFile]);
            
            if (kDebugMode) {
              print('🖼️ PlayerImage: ✅ Complete workflow finished successfully');
              print('🖼️ PlayerImage: Download URL: $downloadUrl');
            }
            
            return downloadUrl;
          } else {
            if (kDebugMode) {
              print('🖼️ PlayerImage: ❌ Upload failed, falling back to local file');
            }
            // Fallback: return local file path if upload fails
            return processedFile.path;
          }
        } else {
          if (kDebugMode) {
            print('🖼️ PlayerImage: No authenticated user, using local storage');
          }
          // No authentication: return local file path
          return processedFile.path;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ PlayerImage: ❌ Error in image workflow: $e');
      }
      return null;
    }
  }

  /// Pick and process multiple images (for future use)
  static Future<List<String>> pickAndProcessMultipleImages(String playerId, {int maxImages = 5}) async {
    try {
      if (kDebugMode) {
        print('🖼️ PlayerImage: Starting multiple image workflow for player $playerId');
      }

      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFiles.isEmpty) {
        if (kDebugMode) {
          print('🖼️ PlayerImage: No images selected');
        }
        return [];
      }

      // Limit to maxImages
      final limitedFiles = pickedFiles.take(maxImages).toList();
      final urls = <String>[];

      for (int i = 0; i < limitedFiles.length; i++) {
        final pickedFile = limitedFiles[i];
        if (kDebugMode) {
          print('🖼️ PlayerImage: Processing image ${i + 1}/${limitedFiles.length}');
        }

        final imageFile = File(pickedFile.path);
        final processedFile = await ImageCompressionService.processPlayerImage(imageFile);

        // Upload to Firebase Storage
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final downloadUrl = await FirebaseStorageService.uploadPlayerImage(
            processedFile, 
            playerId,
          );
          
          if (downloadUrl != null) {
            urls.add(downloadUrl);
          }
        } else {
          urls.add(processedFile.path);
        }
      }

      if (kDebugMode) {
        print('🖼️ PlayerImage: ✅ Processed ${urls.length}/${limitedFiles.length} images');
      }

      return urls;
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ PlayerImage: ❌ Error in multiple image workflow: $e');
      }
      return [];
    }
  }

  /// Update player photo and handle old image cleanup
  static Future<Player?> updatePlayerPhoto(Player player, String newPhotoPath) async {
    try {
      if (kDebugMode) {
        print('🖼️ PlayerImage: Updating photo for ${player.firstName} ${player.lastName}');
      }

      // Clean up old image if it's a Firebase Storage URL
      if (player.photoPath != null && player.photoPath!.startsWith('http')) {
        await FirebaseStorageService.deletePlayerImage(player.photoPath!);
      }

      // Create updated player with new photo
      final updatedPlayer = Player(
        id: player.id,
        teamId: player.teamId,
        firstName: player.firstName,
        lastName: player.lastName,
        position: player.position,
        preferredFoot: player.preferredFoot,
        birthDate: player.birthDate,
        photoPath: newPhotoPath,
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

      if (kDebugMode) {
        print('🖼️ PlayerImage: ✅ Player photo updated successfully');
      }

      return updatedPlayer;
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ PlayerImage: ❌ Error updating player photo: $e');
      }
      return null;
    }
  }

  /// Remove player photo and clean up storage
  static Future<Player?> removePlayerPhoto(Player player) async {
    try {
      if (kDebugMode) {
        print('🖼️ PlayerImage: Removing photo for ${player.firstName} ${player.lastName}');
      }

      // Clean up image if it's a Firebase Storage URL
      if (player.photoPath != null && player.photoPath!.startsWith('http')) {
        await FirebaseStorageService.deletePlayerImage(player.photoPath!);
      }

      // Create updated player without photo
      final updatedPlayer = Player(
        id: player.id,
        teamId: player.teamId,
        firstName: player.firstName,
        lastName: player.lastName,
        position: player.position,
        preferredFoot: player.preferredFoot,
        birthDate: player.birthDate,
        photoPath: null, // Remove photo
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

      if (kDebugMode) {
        print('🖼️ PlayerImage: ✅ Player photo removed successfully');
      }

      return updatedPlayer;
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ PlayerImage: ❌ Error removing player photo: $e');
      }
      return null;
    }
  }

  /// Clean up all images for a player (called when deleting player)
  static Future<void> cleanupPlayerImages(String playerId) async {
    try {
      if (kDebugMode) {
        print('🖼️ PlayerImage: Cleaning up all images for player $playerId');
      }

      await FirebaseStorageService.deleteAllPlayerImages(playerId);

      if (kDebugMode) {
        print('🖼️ PlayerImage: ✅ All player images cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ PlayerImage: ❌ Error cleaning up player images: $e');
      }
    }
  }

  /// Check if an image path is a web URL (Firebase Storage)
  static bool isWebUrl(String? imagePath) {
    if (imagePath == null) return false;
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  /// Check if an image path is a local file
  static bool isLocalFile(String? imagePath) {
    if (imagePath == null) return false;
    return !isWebUrl(imagePath) && !imagePath.startsWith('data:');
  }

  /// Check if an image path is base64 data
  static bool isBase64Data(String? imagePath) {
    if (imagePath == null) return false;
    return imagePath.startsWith('data:');
  }

  /// Get image display widget based on path type
  static ImageProvider? getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    try {
      if (isWebUrl(imagePath)) {
        // Firebase Storage URL or other web URL
        return NetworkImage(imagePath);
      } else if (isBase64Data(imagePath)) {
        // Base64 data URL
        return NetworkImage(imagePath);
      } else if (isLocalFile(imagePath)) {
        // Local file path
        if (!kIsWeb) {
          // For Android/iOS, handle both network URLs and local files
          if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
            // Firebase Storage URLs or other network images
            return NetworkImage(imagePath);
          } else {
            // Local file paths - safely check file existence
            final file = File(imagePath);
            if (file.existsSync()) {
              return FileImage(file);
            }
            return null;
          }
        } else {
          // On web, treat as network image
          return NetworkImage(imagePath);
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 PlayerImageService: Error loading image: $e');
      }
      return null;
    }
  }

  /// Clean up temporary files
  static Future<void> _cleanupTempFiles(List<File> files) async {
    for (final file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
          if (kDebugMode) {
            print('🖼️ PlayerImage: 🗑️ Cleaned up temp file: ${file.path}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('🖼️ PlayerImage: Could not delete temp file ${file.path}: $e');
        }
      }
    }
  }

  /// Get storage usage summary for user
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return {
          'authenticated': false,
          'totalSize': 0,
          'totalSizeMB': 0.0,
          'available': false,
        };
      }

      final totalBytes = await FirebaseStorageService.getUserStorageUsage();
      final isAvailable = await FirebaseStorageService.isAvailable();

      return {
        'authenticated': true,
        'totalSize': totalBytes,
        'totalSizeMB': totalBytes / 1024 / 1024,
        'available': isAvailable,
      };
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ PlayerImage: Error getting storage info: $e');
      }
      return {
        'authenticated': false,
        'totalSize': 0,
        'totalSizeMB': 0.0,
        'available': false,
        'error': e.toString(),
      };
    }
  }
}