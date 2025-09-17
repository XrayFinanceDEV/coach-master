import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionService {
  static const int targetSizeKB = 500; // Target size ~500KB
  static const int maxWidth = 720; // For 9:16 aspect ratio (720x1280)
  static const int maxHeight = 1280;
  static const int minQuality = 10; // Minimum quality to try
  static const int maxQuality = 95; // Maximum quality to start with

  /// Compresses an image file to approximately 500KB with 9:16 aspect ratio
  static Future<File> compressImageFile(File imageFile) async {
    try {
      if (kDebugMode) {
        print('🖼️ ImageCompression: Starting compression for ${imageFile.path}');
        print('🖼️ ImageCompression: Original size: ${(await imageFile.length() / 1024).toStringAsFixed(1)}KB');
      }

      // Get temporary directory for compressed image
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final compressedPath = path.join(tempDir.path, '${fileName}_compressed.jpg');

      // Start with high quality and reduce if needed
      int quality = maxQuality;
      File? compressedFile;
      
      while (quality >= minQuality) {
        if (kDebugMode) {
          print('🖼️ ImageCompression: Trying quality $quality');
        }

        // Compress the image
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          imageFile.absolute.path,
          minWidth: maxWidth,
          minHeight: maxHeight,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        if (compressedBytes != null) {
          // Write compressed bytes to file
          compressedFile = File(compressedPath);
          await compressedFile.writeAsBytes(compressedBytes);
          
          final compressedSizeKB = compressedBytes.length / 1024;
          
          if (kDebugMode) {
            print('🖼️ ImageCompression: Compressed size: ${compressedSizeKB.toStringAsFixed(1)}KB');
          }

          // Check if we've reached target size or if we're close enough
          if (compressedSizeKB <= targetSizeKB || quality == minQuality) {
            if (kDebugMode) {
              print('🖼️ ImageCompression: ✅ Final size: ${compressedSizeKB.toStringAsFixed(1)}KB (quality: $quality)');
            }
            break;
          }
        }

        // Reduce quality for next iteration
        quality -= 10;
      }

      return compressedFile ?? imageFile; // Return original if compression failed
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCompression: ❌ Error compressing image: $e');
      }
      return imageFile; // Return original file if compression fails
    }
  }

  /// Compresses image data (Uint8List) to approximately 500KB with 9:16 aspect ratio
  static Future<Uint8List> compressImageData(Uint8List imageData) async {
    try {
      if (kDebugMode) {
        print('🖼️ ImageCompression: Starting compression for image data');
        print('🖼️ ImageCompression: Original size: ${(imageData.length / 1024).toStringAsFixed(1)}KB');
      }

      // Start with high quality and reduce if needed
      int quality = maxQuality;
      Uint8List? compressedData;
      
      while (quality >= minQuality) {
        if (kDebugMode) {
          print('🖼️ ImageCompression: Trying quality $quality');
        }

        // Compress the image data
        compressedData = await FlutterImageCompress.compressWithList(
          imageData,
          minWidth: maxWidth,
          minHeight: maxHeight,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        final compressedSizeKB = compressedData.length / 1024;
        
        if (kDebugMode) {
          print('🖼️ ImageCompression: Compressed size: ${compressedSizeKB.toStringAsFixed(1)}KB');
        }

        // Check if we've reached target size or if we're close enough
        if (compressedSizeKB <= targetSizeKB || quality == minQuality) {
          if (kDebugMode) {
            print('🖼️ ImageCompression: ✅ Final size: ${compressedSizeKB.toStringAsFixed(1)}KB (quality: $quality)');
          }
          break;
        }

        // Reduce quality for next iteration
        quality -= 10;
      }

      return compressedData ?? imageData; // Return original if compression failed
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCompression: ❌ Error compressing image data: $e');
      }
      return imageData; // Return original data if compression fails
    }
  }

  /// Resize image to specific aspect ratio (9:16) while maintaining proportions
  static Future<File> resizeToAspectRatio(File imageFile, {double aspectRatio = 9/16}) async {
    try {
      // Read the image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        if (kDebugMode) {
          print('🖼️ ImageCompression: ❌ Could not decode image');
        }
        return imageFile;
      }

      // Calculate new dimensions maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      final currentRatio = newWidth / newHeight;
      
      if (currentRatio > aspectRatio) {
        // Image is too wide, reduce width
        newWidth = (newHeight * aspectRatio).round();
      } else if (currentRatio < aspectRatio) {
        // Image is too tall, reduce height
        newHeight = (newWidth / aspectRatio).round();
      }

      // Ensure we don't exceed maximum dimensions
      if (newWidth > maxWidth || newHeight > maxHeight) {
        final scale = (maxWidth / newWidth).clamp(0.0, maxHeight / newHeight);
        newWidth = (newWidth * scale).round();
        newHeight = (newHeight * scale).round();
      }

      if (kDebugMode) {
        print('🖼️ ImageCompression: Resizing from ${image.width}x$image.height to ${newWidth}x$newHeight');
      }

      // Resize the image
      final resizedImage = img.copyResize(image, width: newWidth, height: newHeight);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(imageFile.path);
      final resizedPath = path.join(tempDir.path, '${fileName}_resized.jpg');
      
      final resizedFile = File(resizedPath);
      await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));
      
      return resizedFile;
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCompression: ❌ Error resizing image: $e');
      }
      return imageFile; // Return original if resizing fails
    }
  }

  /// Get the size of an image file in KB
  static Future<double> getImageSizeKB(File imageFile) async {
    try {
      final bytes = await imageFile.length();
      return bytes / 1024;
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCompression: ❌ Error getting image size: $e');
      }
      return 0.0;
    }
  }

  /// Get the dimensions of an image file
  static Future<Map<String, int>?> getImageDimensions(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image != null) {
        return {
          'width': image.width,
          'height': image.height,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCompression: ❌ Error getting image dimensions: $e');
      }
    }
    return null;
  }

  /// Process image from bytes (web-compatible)
  static Future<Uint8List> processPlayerImageFromBytes(Uint8List imageBytes) async {
    try {
      if (kDebugMode) {
        print('🖼️ ImageCompression: 🔄 Processing player image from bytes (${imageBytes.length} bytes)');
      }

      // Step 1: Decode and resize image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        if (kDebugMode) {
          print('🖼️ ImageCompression: ❌ Could not decode image from bytes');
        }
        return imageBytes;
      }

      // Calculate new dimensions for 9:16 aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      const double aspectRatio = 9 / 16;
      final double currentRatio = newWidth / newHeight;
      
      if (currentRatio > aspectRatio) {
        newWidth = (newHeight * aspectRatio).round();
      } else if (currentRatio < aspectRatio) {
        newHeight = (newWidth / aspectRatio).round();
      }

      // Ensure we don't exceed maximum dimensions
      if (newWidth > maxWidth || newHeight > maxHeight) {
        final scale = (maxWidth / newWidth).clamp(0.0, maxHeight / newHeight);
        newWidth = (newWidth * scale).round();
        newHeight = (newHeight * scale).round();
      }

      if (kDebugMode) {
        print('🖼️ ImageCompression: Resizing from ${image.width}x$image.height to ${newWidth}x$newHeight');
      }

      // Step 2: Resize the image
      final resizedImage = img.copyResize(image, width: newWidth, height: newHeight);
      
      // Step 3: Compress to target size using flutter_image_compress
      final resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 90));
      final compressedBytes = await compressImageData(resizedBytes);

      if (kDebugMode) {
        final finalSizeKB = compressedBytes.length / 1024;
        print('🖼️ ImageCompression: ✅ Processing complete!');
        print('🖼️ ImageCompression: Final size: ${finalSizeKB.toStringAsFixed(1)}KB');
        print('🖼️ ImageCompression: Final dimensions: ${newWidth}x$newHeight');
      }

      return compressedBytes;
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCompression: ❌ Error processing image from bytes: $e');
      }
      return imageBytes; // Return original if processing fails
    }
  }

  /// Complete image processing: resize to 9:16 aspect ratio and compress to ~500KB
  static Future<File> processPlayerImage(File imageFile) async {
    try {
      if (kDebugMode) {
        print('🖼️ ImageCompression: 🔄 Processing player image: ${imageFile.path}');
      }

      // Step 1: Resize to aspect ratio if needed
      final resizedFile = await resizeToAspectRatio(imageFile);
      
      // Step 2: Compress to target size
      final compressedFile = await compressImageFile(resizedFile);
      
      // Clean up temporary resized file if it's different from original
      if (resizedFile.path != imageFile.path && resizedFile.path != compressedFile.path) {
        try {
          await resizedFile.delete();
        } catch (e) {
          if (kDebugMode) {
            print('🖼️ ImageCompression: Could not delete temp file: $e');
          }
        }
      }

      if (kDebugMode) {
        final finalSize = await getImageSizeKB(compressedFile);
        final dimensions = await getImageDimensions(compressedFile);
        print('🖼️ ImageCompression: ✅ Processing complete!');
        print('🖼️ ImageCompression: Final size: ${finalSize.toStringAsFixed(1)}KB');
        if (dimensions != null) {
          print('🖼️ ImageCompression: Final dimensions: ${dimensions['width']}x${dimensions['height']}');
        }
      }

      return compressedFile;
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCompression: ❌ Error processing player image: $e');
      }
      return imageFile; // Return original if processing fails
    }
  }
}