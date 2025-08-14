/// 정규화 사각형 (0..1 범위, x0 < x1, y0 < y1)
class RectNorm {
  final double x0;
  final double y0;
  final double x1;
  final double y1;

  const RectNorm({required this.x0, required this.y0, required this.x1, required this.y1});

  RectNorm normalized() {
    double nx0 = x0.clamp(0.0, 1.0);
    double ny0 = y0.clamp(0.0, 1.0);
    double nx1 = x1.clamp(0.0, 1.0);
    double ny1 = y1.clamp(0.0, 1.0);
    if (nx0 > nx1) {
      final t = nx0; nx0 = nx1; nx1 = t;
    }
    if (ny0 > ny1) {
      final t = ny0; ny0 = ny1; ny1 = t;
    }
    return RectNorm(x0: nx0, y0: ny0, x1: nx1, y1: ny1);
  }

  void assertValid() {
    if (x0 < 0 || x1 > 1 || y0 < 0 || y1 > 1) {
      throw ArgumentError('RectNorm out of bounds');
    }
    if (!(x0 < x1 && y0 < y1)) {
      throw ArgumentError('RectNorm must satisfy x0<x1 and y0<y1');
    }
  }
}


