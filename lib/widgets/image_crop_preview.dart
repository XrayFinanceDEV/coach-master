import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A widget that allows dragging a square crop area over a 9:16 aspect ratio image
/// to position the crop for square display in player cards
class ImageCropPreview extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final Function(Offset cropOffset)? onCropPositionChanged;
  final double containerHeight;
  final bool showGrid;

  const ImageCropPreview({
    super.key,
    this.imagePath,
    this.imageBytes,
    this.onCropPositionChanged,
    this.containerHeight = 400,
    this.showGrid = true,
  });

  @override
  State<ImageCropPreview> createState() => _ImageCropPreviewState();
}

class _ImageCropPreviewState extends State<ImageCropPreview> {
  Offset _cropOffset = const Offset(0.0, 0.0); // Normalized offset (0.0 to 1.0)
  late Size _imageDisplaySize;
  ui.Image? _loadedImage;
  bool _imageLoaded = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ImageCropPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath || oldWidget.imageBytes != widget.imageBytes) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      ui.Image? image;

      if (widget.imageBytes != null) {
        // Load from bytes (web compatibility)
        final codec = await ui.instantiateImageCodec(widget.imageBytes!);
        final frame = await codec.getNextFrame();
        image = frame.image;
      } else if (widget.imagePath != null && !kIsWeb) {
        // Load from file path (mobile)
        final file = File(widget.imagePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          image = frame.image;
        }
      }

      if (image != null && mounted) {
        setState(() {
          _loadedImage = image;
          _imageLoaded = true;
          // Initialize crop position for optimal portrait framing (30% from top)
          _cropOffset = const Offset(0.0, 0.3);
        });

        // Notify parent of initial crop position
        widget.onCropPositionChanged?.call(_cropOffset);
      }
    } catch (e) {
      if (kDebugMode) {
        print('🖼️ ImageCropPreview: Error loading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_imageLoaded || _loadedImage == null) {
      return Container(
        height: widget.containerHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading image preview...'),
            ],
          ),
        ),
      );
    }

    // Calculate 9:16 aspect ratio display size
    const double aspectRatio = 9.0 / 16.0;
    final double displayWidth = widget.containerHeight * aspectRatio;
    _imageDisplaySize = Size(displayWidth, widget.containerHeight);

    return Container(
      height: widget.containerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: SizedBox(
            width: displayWidth,
            height: widget.containerHeight,
            child: Stack(
              children: [
                // Background image
                _buildImageBackground(),
                // Crop overlay with draggable square
                _buildCropOverlay(),
                // Instructions
                _buildInstructions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageBackground() {
    return Positioned.fill(
      child: _getImageWidget(),
    );
  }

  Widget _getImageWidget() {
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.cover,
        width: _imageDisplaySize.width,
        height: _imageDisplaySize.height,
      );
    } else if (widget.imagePath != null) {
      if (kIsWeb) {
        return Image.network(
          widget.imagePath!,
          fit: BoxFit.cover,
          width: _imageDisplaySize.width,
          height: _imageDisplaySize.height,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } else {
        return Image.file(
          File(widget.imagePath!),
          fit: BoxFit.cover,
          width: _imageDisplaySize.width,
          height: _imageDisplaySize.height,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }
    }
    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildCropOverlay() {
    // Full-width square crop (width = image width, height = image width for perfect square)
    final double cropSize = _imageDisplaySize.width;

    // Calculate the bounds for vertical dragging only (crop square must stay within image)
    final double maxY = _imageDisplaySize.height - cropSize;

    // Convert normalized Y offset to pixel position (X is always 0 for full-width)
    final double cropX = 0.0; // Always full-width
    final double cropY = (_cropOffset.dy * maxY).clamp(0.0, maxY);

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onPanUpdate: (details) {
        // Get the current widget's render box
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box == null) return;

        // Convert global position to local coordinates
        final Offset localPosition = box.globalToLocal(details.globalPosition);

        // Calculate new crop Y position (only vertical movement)
        final double newCropY = localPosition.dy - cropSize / 2;

        // Convert to normalized Y offset (0.0 to 1.0) - X is always 0
        final double newNormalizedY = (newCropY / maxY).clamp(0.0, 1.0);

        setState(() {
          _cropOffset = Offset(0.0, newNormalizedY); // X is always 0 for full-width
        });

        // Notify parent of position change
        widget.onCropPositionChanged?.call(_cropOffset);
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      child: Stack(
        children: [
          // Semi-transparent overlay above crop area
          if (cropY > 0)
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: cropY,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          // Semi-transparent overlay below crop area
          if (cropY + cropSize < _imageDisplaySize.height)
            Positioned(
              left: 0,
              top: cropY + cropSize,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          // Full-width crop area
          Positioned(
            left: cropX,
            top: cropY,
            child: Container(
              width: cropSize,
              height: cropSize,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: _isDragging
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    width: _isDragging ? 4 : 3,
                  ),
                  bottom: BorderSide(
                    color: _isDragging
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    width: _isDragging ? 4 : 3,
                  ),
                ),
                boxShadow: _isDragging ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ] : null,
              ),
              child: Stack(
                children: [
                  // Transparent area - shows the background image through
                  // No image widget here - just transparent

                  // Grid overlay (if enabled)
                  if (widget.showGrid) _buildGrid(cropSize),
                  // Center drag indicator
                  _buildVerticalDragIndicator(cropSize),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GridPainter(color: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildVerticalDragIndicator(double size) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.drag_handle,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'DRAG UP/DOWN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Drag up or down to position the square crop area',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadedImage?.dispose();
    super.dispose();
  }
}

/// Custom painter for drawing grid lines inside the crop area
class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw 3x3 grid (rule of thirds)
    final double thirdX = size.width / 3;
    final double thirdY = size.height / 3;

    // Vertical lines
    canvas.drawLine(Offset(thirdX, 0), Offset(thirdX, size.height), paint);
    canvas.drawLine(Offset(thirdX * 2, 0), Offset(thirdX * 2, size.height), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, thirdY), Offset(size.width, thirdY), paint);
    canvas.drawLine(Offset(0, thirdY * 2), Offset(size.width, thirdY * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}