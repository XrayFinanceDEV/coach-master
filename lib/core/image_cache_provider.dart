import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/repository_instances.dart';

final playerImageProvider = Provider.family<ImageProvider?, String>((ref, playerId) {
  final playerRepo = ref.watch(playerRepositoryProvider);
  final player = playerRepo.getPlayer(playerId);
  
  if (player?.photoPath == null || player!.photoPath!.isEmpty) {
    return null;
  }
  
  return _getOptimizedImageProvider(player.photoPath!);
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