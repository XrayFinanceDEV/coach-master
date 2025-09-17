import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload a player image to Firebase Storage from bytes (web-compatible)
  /// Returns the download URL if successful, null if failed
  static Future<String?> uploadPlayerImageFromBytes(Uint8List imageBytes, String playerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('🔥 FirebaseStorage: ❌ No authenticated user for upload');
        }
        return null;
      }

      if (kDebugMode) {
        print('🔥 FirebaseStorage: 📤 Uploading player image for $playerId (${imageBytes.length} bytes)');
      }

      // Create unique file path: users/{userId}/players/{playerId}/profile.jpg
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'users/${currentUser.uid}/players/$playerId/$fileName';
      
      // Create storage reference
      final storageRef = _storage.ref().child(filePath);
      
      // Upload metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'playerId': playerId,
          'userId': currentUser.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        final fileSizeKB = imageBytes.length / 1024;
        print('🔥 FirebaseStorage: File size: ${fileSizeKB.toStringAsFixed(1)}KB');
        print('🔥 FirebaseStorage: Upload path: $filePath');
      }

      // Upload the data
      final uploadTask = storageRef.putData(imageBytes, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        if (kDebugMode) {
          print('🔥 FirebaseStorage: Upload progress: ${progress.toStringAsFixed(1)}%');
        }
      });

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      
      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadURL = await storageRef.getDownloadURL();
        
        if (kDebugMode) {
          print('🔥 FirebaseStorage: ✅ Upload successful!');
          print('🔥 FirebaseStorage: Download URL: $downloadURL');
        }
        
        return downloadURL;
      } else {
        if (kDebugMode) {
          print('🔥 FirebaseStorage: ❌ Upload failed with state: ${snapshot.state}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: ❌ Upload error: $e');
      }
      return null;
    }
  }

  /// Upload a player image to Firebase Storage
  /// Returns the download URL if successful, null if failed
  static Future<String?> uploadPlayerImage(File imageFile, String playerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('🔥 FirebaseStorage: ❌ No authenticated user for upload');
        }
        return null;
      }

      if (kDebugMode) {
        print('🔥 FirebaseStorage: 📤 Uploading player image for $playerId');
      }

      // Create unique file path: users/{userId}/players/{playerId}/profile.jpg
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'users/${currentUser.uid}/players/$playerId/$fileName';
      
      // Create storage reference
      final storageRef = _storage.ref().child(filePath);
      
      // Upload metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'playerId': playerId,
          'userId': currentUser.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        final fileSizeKB = (await imageFile.length()) / 1024;
        print('🔥 FirebaseStorage: File size: ${fileSizeKB.toStringAsFixed(1)}KB');
        print('🔥 FirebaseStorage: Upload path: $filePath');
      }

      // Upload the file
      final uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        if (kDebugMode) {
          print('🔥 FirebaseStorage: Upload progress: ${progress.toStringAsFixed(1)}%');
        }
      });

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      
      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadURL = await storageRef.getDownloadURL();
        
        if (kDebugMode) {
          print('🔥 FirebaseStorage: ✅ Upload successful!');
          print('🔥 FirebaseStorage: Download URL: $downloadURL');
        }
        
        return downloadURL;
      } else {
        if (kDebugMode) {
          print('🔥 FirebaseStorage: ❌ Upload failed with state: ${snapshot.state}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: ❌ Upload error: $e');
      }
      return null;
    }
  }

  /// Delete a player image from Firebase Storage using its URL
  static Future<bool> deletePlayerImage(String downloadUrl) async {
    try {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: 🗑️ Deleting image: $downloadUrl');
      }

      // Create reference from download URL
      final ref = _storage.refFromURL(downloadUrl);
      
      // Delete the file
      await ref.delete();
      
      if (kDebugMode) {
        print('🔥 FirebaseStorage: ✅ Image deleted successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: ❌ Delete error: $e');
      }
      return false;
    }
  }

  /// Delete all images for a specific player
  static Future<void> deleteAllPlayerImages(String playerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('🔥 FirebaseStorage: ❌ No authenticated user for deletion');
        }
        return;
      }

      if (kDebugMode) {
        print('🔥 FirebaseStorage: 🗑️ Deleting all images for player $playerId');
      }

      // List all files in player's directory
      final playerDir = 'users/${currentUser.uid}/players/$playerId/';
      final listResult = await _storage.ref(playerDir).listAll();
      
      // Delete each file
      for (final item in listResult.items) {
        try {
          await item.delete();
          if (kDebugMode) {
            print('🔥 FirebaseStorage: 🗑️ Deleted ${item.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('🔥 FirebaseStorage: ❌ Error deleting ${item.name}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('🔥 FirebaseStorage: ✅ All player images deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: ❌ Error deleting player images: $e');
      }
    }
  }

  /// Get the size of all images for a user (for storage quota monitoring)
  static Future<int> getUserStorageUsage() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return 0;
      }

      // This is a simplified version - in production you might want to 
      // store metadata about file sizes to avoid downloading all files
      final userDir = 'users/${currentUser.uid}/';
      final listResult = await _storage.ref(userDir).listAll();
      
      int totalSize = 0;
      for (final item in listResult.items) {
        try {
          final metadata = await item.getMetadata();
          totalSize += metadata.size ?? 0;
        } catch (e) {
          if (kDebugMode) {
            print('🔥 FirebaseStorage: Could not get metadata for ${item.name}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('🔥 FirebaseStorage: Total storage usage: ${(totalSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: Error calculating storage usage: $e');
      }
      return 0;
    }
  }

  /// Check if Firebase Storage is available
  static Future<bool> isAvailable() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Try to access storage
      _storage.ref('test').child('ping.txt');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: Storage not available: $e');
      }
      return false;
    }
  }

  /// Clean up old images (keep only the latest 3 per player)
  static Future<void> cleanupOldPlayerImages(String playerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      if (kDebugMode) {
        print('🔥 FirebaseStorage: 🧹 Cleaning up old images for player $playerId');
      }

      final playerDir = 'users/${currentUser.uid}/players/$playerId/';
      final listResult = await _storage.ref(playerDir).listAll();
      
      if (listResult.items.length <= 3) {
        if (kDebugMode) {
          print('🔥 FirebaseStorage: Only ${listResult.items.length} images, no cleanup needed');
        }
        return;
      }

      // Sort by creation time (newest first)
      final sortedItems = <Reference>[];
      for (final item in listResult.items) {
        try {
          await item.getMetadata(); // Ensure metadata is loaded
          sortedItems.add(item);
        } catch (e) {
          if (kDebugMode) {
            print('🔥 FirebaseStorage: Could not get metadata for ${item.name}');
          }
        }
      }

      // Sort by creation time (extract timestamp from filename)
      sortedItems.sort((a, b) {
        try {
          final aTime = _extractTimestampFromFilename(a.name);
          final bTime = _extractTimestampFromFilename(b.name);
          return bTime.compareTo(aTime); // Newest first
        } catch (e) {
          return 0;
        }
      });

      // Delete old images (keep only the first 3)
      for (int i = 3; i < sortedItems.length; i++) {
        try {
          await sortedItems[i].delete();
          if (kDebugMode) {
            print('🔥 FirebaseStorage: 🗑️ Deleted old image: ${sortedItems[i].name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('🔥 FirebaseStorage: ❌ Error deleting ${sortedItems[i].name}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('🔥 FirebaseStorage: ✅ Cleanup complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: ❌ Cleanup error: $e');
      }
    }
  }

  /// Extract timestamp from filename (e.g., "profile_1234567890.jpg" -> 1234567890)
  static int _extractTimestampFromFilename(String filename) {
    try {
      final match = RegExp(r'profile_(\d+)\.jpg').firstMatch(filename);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 FirebaseStorage: Could not extract timestamp from $filename');
      }
    }
    return 0;
  }
}