import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class ImageCacheUtils {
  /// Clears the image cache for a given photo path
  /// Works for both web (NetworkImage) and mobile (FileImage)
  static void clearImageCache(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return;
    
    try {
      if (kIsWeb) {
        // For web, clear network image cache
        if (photoPath.startsWith('data:') || 
            photoPath.startsWith('blob:') || 
            photoPath.startsWith('http')) {
          NetworkImage(photoPath).evict();
        }
      } else {
        // For mobile, clear file image cache
        FileImage(File(photoPath)).evict();
      }
    } catch (e) {
      debugPrint('Error clearing image cache for $photoPath: $e');
    }
  }
  
  /// Clears image cache for both old and new photo paths when updating
  static void clearImageCacheForUpdate(String? oldPhotoPath, String? newPhotoPath) {
    clearImageCache(oldPhotoPath);
    clearImageCache(newPhotoPath);
  }
}

/// Notifier to trigger UI rebuilds when player images are updated
class PlayerImageUpdateNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Initial state
  }
  
  void notifyImageUpdate() {
    state++;
  }
}

final playerImageUpdateProvider = NotifierProvider<PlayerImageUpdateNotifier, int>(
  () => PlayerImageUpdateNotifier(),
);