import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:coachmaster/widgets/image_crop_preview.dart';

/// Full-screen dialog for cropping images with proper gesture handling
class ImageCropDialog extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final Function(Offset cropOffset) onCropConfirmed;
  final VoidCallback onCropCancelled;

  const ImageCropDialog({
    super.key,
    this.imagePath,
    this.imageBytes,
    required this.onCropConfirmed,
    required this.onCropCancelled,
  });

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  Offset _cropOffset = const Offset(0.0, 0.3); // Default crop position

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text(
            'Position Crop Area',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCropCancelled();
            },
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onCropConfirmed(_cropOffset);
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'APPLY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Instructions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.crop,
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Position the crop area on the player\'s face',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Drag up or down to adjust the square crop position',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[300],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Crop preview
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate appropriate height based on available space
                      final availableHeight = constraints.maxHeight;
                      final containerHeight = availableHeight > 0 ? availableHeight : 400.0;

                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ImageCropPreview(
                            imagePath: widget.imagePath,
                            imageBytes: widget.imageBytes,
                            containerHeight: containerHeight,
                            showGrid: true,
                            onCropPositionChanged: (offset) {
                              setState(() {
                                _cropOffset = offset;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Action buttons
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onCropCancelled();
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onCropConfirmed(_cropOffset);
                          },
                          icon: const Icon(Icons.crop),
                          label: const Text('Apply Crop'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the crop dialog
Future<Offset?> showImageCropDialog({
  required BuildContext context,
  String? imagePath,
  Uint8List? imageBytes,
}) async {
  Offset? result;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return ImageCropDialog(
        imagePath: imagePath,
        imageBytes: imageBytes,
        onCropConfirmed: (offset) {
          result = offset;
        },
        onCropCancelled: () {
          result = null;
        },
      );
    },
  );

  return result;
}