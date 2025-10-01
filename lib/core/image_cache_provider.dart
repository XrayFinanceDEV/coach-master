import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';

// Use stream provider for real-time image updates
final playerImageProvider = Provider.family<AsyncValue<ImageProvider?>, String>((ref, playerId) {
  final playerAsync = ref.watch(playerStreamProvider(playerId));

  return playerAsync.when(
    data: (player) {
      if (player == null || player.photoPath == null || player.photoPath!.isEmpty) {
        return const AsyncValue.data(null);
      }
      return AsyncValue.data(_getOptimizedImageProvider(player.photoPath!));
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

ImageProvider _getOptimizedImageProvider(String photoPath) {
  if (kIsWeb) {
    if (photoPath.startsWith('data:') ||
        photoPath.startsWith('blob:') ||
        photoPath.startsWith('http')) {
      return NetworkImage(photoPath);
    }
    return NetworkImage('');
  } else {
    return FileImage(File(photoPath));
  }
}

class ImageCacheManager {
  static final Map<String, ImageProvider> _cache = {};
  static const int maxCacheSize = 100;

  static ImageProvider? getCachedImage(String key, String photoPath) {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final image = _getOptimizedImageProvider(photoPath);

    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = image;
    return image;
  }

  static void clearCache() {
    _cache.clear();
  }
}
