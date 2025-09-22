import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for applying crop positioning to images before compression
class ImageCropService {
  /// Applies crop positioning to an image file and returns the cropped file
  /// cropOffset: normalized offset (0.0 to 1.0) where to position the square crop
  static Future<File> applyCropToFile(File imageFile, Offset cropOffset) async {
    try {
      if (kDebugMode) {
        print('🔲 ImageCrop: Applying crop to ${imageFile.path}');
        print('🔲 ImageCrop: Crop offset: ${cropOffset.dx}, ${cropOffset.dy}');
      }

      // Read and decode the image
      final imageBytes = await imageFile.readAsBytes();
      final croppedBytes = await applyCropToBytes(imageBytes, cropOffset);

      // Save cropped image to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final croppedPath = path.join(tempDir.path, '${fileName}_cropped.jpg');

      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(croppedBytes);

      if (kDebugMode) {
        print('🔲 ImageCrop: ✅ Crop applied successfully to ${croppedFile.path}');
      }

      return croppedFile;
    } catch (e) {
      if (kDebugMode) {
        print('🔲 ImageCrop: ❌ Error applying crop: $e');
      }
      return imageFile; // Return original file if cropping fails
    }
  }

  /// Applies crop positioning to image bytes and returns cropped bytes
  /// cropOffset: normalized offset (0.0 to 1.0) where to position the square crop
  static Future<Uint8List> applyCropToBytes(Uint8List imageBytes, Offset cropOffset) async {
    try {
      if (kDebugMode) {
        print('🔲 ImageCrop: Applying crop to image bytes');
        print('🔲 ImageCrop: Original size: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
      }

      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        if (kDebugMode) {
          print('🔲 ImageCrop: ❌ Could not decode image');
        }
        return imageBytes;
      }

      if (kDebugMode) {
        print('🔲 ImageCrop: Original dimensions: ${image.width}x${image.height}');
      }

      // Calculate full-width square crop dimensions and position
      final int cropSize = image.width; // Always full width
      final int maxY = image.height - cropSize; // Only Y can vary

      // Full-width crop (X is always 0, only Y position matters)
      final int cropX = 0;
      final int cropY = (cropOffset.dy * maxY).round().clamp(0, maxY);

      if (kDebugMode) {
        print('🔲 ImageCrop: Crop size: ${cropSize}x$cropSize');
        print('🔲 ImageCrop: Crop position: ($cropX, $cropY)');
      }

      // Extract the square crop
      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropSize,
        height: cropSize,
      );

      // Encode as JPEG
      final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage, quality: 95));

      if (kDebugMode) {
        print('🔲 ImageCrop: ✅ Cropped size: ${(croppedBytes.length / 1024).toStringAsFixed(1)}KB');
        print('🔲 ImageCrop: Final dimensions: ${croppedImage.width}x${croppedImage.height}');
      }

      return croppedBytes;
    } catch (e) {
      if (kDebugMode) {
        print('🔲 ImageCrop: ❌ Error applying crop to bytes: $e');
      }
      return imageBytes; // Return original bytes if cropping fails
    }
  }

  /// Gets the crop information for preview purposes
  /// Returns crop rectangle in pixels for the given image dimensions
  static Map<String, dynamic> getCropInfo(int imageWidth, int imageHeight, Offset cropOffset) {
    final int cropSize = imageWidth; // Always full width
    final int maxY = imageHeight - cropSize; // Only Y can vary

    final int cropX = 0; // Always 0 for full-width
    final int cropY = (cropOffset.dy * maxY).round().clamp(0, maxY);

    return {
      'cropX': cropX,
      'cropY': cropY,
      'cropSize': cropSize,
      'originalWidth': imageWidth,
      'originalHeight': imageHeight,
    };
  }

  /// Validates if the crop offset is within acceptable bounds
  /// For full-width cropping, only Y offset matters (X is always 0)
  static bool isValidCropOffset(Offset cropOffset) {
    return cropOffset.dx == 0.0 && // X must be 0 for full-width crop
           cropOffset.dy >= 0.0 &&
           cropOffset.dy <= 1.0;
  }

  /// Calculates the optimal crop offset to center on detected face area
  /// This is a placeholder for future face detection integration
  static Offset calculateOptimalCropOffset(int imageWidth, int imageHeight) {
    // For now, return position that works well for portrait photos
    // Slightly above center (30% from top) for better face framing
    // TODO: Integrate with face detection API in the future
    return const Offset(0.0, 0.3); // X=0 (full-width), Y=0.3 (30% from top)
  }

  /// Applies smart crop positioning for automatic face centering
  /// Currently uses a simple heuristic, can be enhanced with ML face detection
  static Future<Uint8List> applySmartCrop(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Use optimal crop offset (centered slightly above middle)
      final optimalOffset = calculateOptimalCropOffset(image.width, image.height);
      return await applyCropToBytes(imageBytes, optimalOffset);
    } catch (e) {
      if (kDebugMode) {
        print('🔲 ImageCrop: ❌ Error in smart crop: $e');
      }
      return imageBytes;
    }
  }
}