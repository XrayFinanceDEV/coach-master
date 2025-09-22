import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for safely handling image loading across web and mobile platforms
class ImageUtils {
  /// Safely create an ImageProvider that handles CORS issues and platform differences
  /// Returns null if the image cannot be safely loaded
  static ImageProvider? getSafeImageProvider(String? photoPath) {
    try {
      if (photoPath == null || photoPath.isEmpty) return null;
      
      if (kIsWeb) {
        // On web, only load images that are safe from CORS issues
        if (photoPath.startsWith('data:') || 
            photoPath.startsWith('blob:') || 
            photoPath.startsWith('http')) {
          return NetworkImage(photoPath);
        }
        return null;
      } else {
        // For Android/iOS, handle both network URLs and local files
        if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
          // Firebase Storage URLs or other network images
          return NetworkImage(photoPath);
        } else if (photoPath.startsWith('data:')) {
          // Base64 data URLs
          return NetworkImage(photoPath);
        } else {
          // Local file paths - safely check file existence
          final file = File(photoPath);
          if (file.existsSync()) {
            return FileImage(file);
          }
          return null;
        }
      }
    } catch (e) {
      // Return null if any error occurs (including CORS errors)
      if (kDebugMode) {
        print('🔴 ImageUtils: Error loading image: $e');
      }
      return null;
    }
  }

  /// Create a safe CircleAvatar with proper fallback handling
  static Widget buildPlayerAvatar({
    required String firstName,
    required String lastName,
    String? photoPath,
    double radius = 24,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
  }) {
    return CircleAvatar(
      key: ValueKey('${firstName}_${lastName}_$photoPath'), // Force rebuild when photo changes
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.withValues(alpha: 0.1),
      backgroundImage: getSafeImageProvider(photoPath),
      child: getSafeImageProvider(photoPath) == null
          ? Text(
              '${firstName.isNotEmpty ? firstName[0] : '?'}${lastName.isNotEmpty ? lastName[0] : '?'}'.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize ?? (radius * 0.5),
                color: textColor ?? Colors.grey[600],
              ),
            )
          : null,
    );
  }

  /// Create a safe Image widget with error handling
  static Widget buildSafeImage({
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    final imageProvider = getSafeImageProvider(imagePath);
    
    if (imageProvider == null) {
      return errorWidget ?? Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
        ),
      );
    }

    return Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('🔴 ImageUtils: Error displaying image: $error');
        }
        return errorWidget ?? Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
          ),
        );
      },
    );
  }

  /// Create a NetworkImage with custom headers to handle CORS
  static ImageProvider createCorsAwareNetworkImage(String url) {
    return NetworkImage(url, headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET',
    });
  }
}