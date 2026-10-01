import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Preprocessor that converts raw handwriting touch strokes into normalized ML input tensors
class StrokePreprocessor {
  /// Target dimension for ML input image (e.g. 32 for 32x32 or 64 for 64x64)
  final int targetDimension;

  const StrokePreprocessor({this.targetDimension = 32});

  /// Converts user strokes into a 1D Float32List representing a normalized [dimension, dimension, 1] grayscale image tensor (values 0.0 to 1.0)
  Float32List preprocessToImageTensor(List<List<Offset>> strokes, Size canvasSize) {
    final int dim = targetDimension;
    final grid = List<double>.filled(dim * dim, 0.0);

    if (strokes.isEmpty || strokes.every((s) => s.isEmpty) || canvasSize.width <= 0 || canvasSize.height <= 0) {
      return Float32List.fromList(grid);
    }

    // 1. Calculate bounding box of all drawn points
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final stroke in strokes) {
      for (final pt in stroke) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
    }

    final double width = maxX - minX;
    final double height = maxY - minY;

    if (width <= 0 && height <= 0) {
      return Float32List.fromList(grid);
    }

    // 2. Add padding and preserve aspect ratio
    final double maxSide = math.max(width, height);
    final double padding = maxSide * 0.15;
    final double boxSize = maxSide + (padding * 2);

    final double centerX = (minX + maxX) / 2.0;
    final double centerY = (minY + maxY) / 2.0;
    final double originX = centerX - (boxSize / 2.0);
    final double originY = centerY - (boxSize / 2.0);

    // 3. Rasterize strokes onto the 32x32 grid with normalized 1.0-pixel pen radius
    const double gridRadius = 1.0;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      if (stroke.length == 1) {
        final pt = stroke.first;
        final gx = ((pt.dx - originX) / boxSize) * dim;
        final gy = ((pt.dy - originY) / boxSize) * dim;
        _drawCircleOnGrid(grid, dim, gx, gy, gridRadius);
        continue;
      }

      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = stroke[i];
        final p2 = stroke[i + 1];

        final x1 = ((p1.dx - originX) / boxSize) * dim;
        final y1 = ((p1.dy - originY) / boxSize) * dim;
        final x2 = ((p2.dx - originX) / boxSize) * dim;
        final y2 = ((p2.dy - originY) / boxSize) * dim;

        _drawLineOnGrid(grid, dim, x1, y1, x2, y2, gridRadius);
      }
    }

    return Float32List.fromList(grid);
  }

  void _drawLineOnGrid(
    List<double> grid,
    int dim,
    double x1,
    double y1,
    double x2,
    double y2,
    double radius,
  ) {
    final dist = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
    final steps = math.max((dist * 2.5).ceil(), 1);

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = x1 + (x2 - x1) * t;
      final y = y1 + (y2 - y1) * t;
      _drawCircleOnGrid(grid, dim, x, y, radius);
    }
  }

  void _drawCircleOnGrid(
    List<double> grid,
    int dim,
    double cx,
    double cy,
    double radius,
  ) {
    final int minX = math.max(0, (cx - radius - 1).floor());
    final int maxX = math.min(dim - 1, (cx + radius + 1).ceil());
    final int minY = math.max(0, (cy - radius - 1).floor());
    final int maxY = math.min(dim - 1, (cy + radius + 1).ceil());

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final d = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
        if (d <= radius) {
          final intensity = 1.0 - (d / (radius + 0.5)).clamp(0.0, 1.0);
          final idx = y * dim + x;
          grid[idx] = math.min(1.0, grid[idx] + intensity);
        }
      }
    }
  }
}
