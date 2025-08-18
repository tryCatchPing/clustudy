/// 정규화 사각형을 표현합니다.
///
/// 좌표는 0..1 범위이며, 항상 x0 < x1, y0 < y1 조건을 만족해야 합니다.
class RectNorm {
  /// 좌측 경계의 x 좌표 (0..1)
  final double x0;
  /// 상단 경계의 y 좌표 (0..1)
  final double y0;
  /// 우측 경계의 x 좌표 (0..1)
  final double x1;
  /// 하단 경계의 y 좌표 (0..1)
  final double y1;

  /// 경계 좌표 [x0], [y0], [x1], [y1]로 사각형을 생성합니다.
  ///
  /// 좌표는 0..1 범위를 가정하며, 필요 시 [normalized] 또는 [assertValid]로 정규화/검증하세요.
  const RectNorm({required this.x0, required this.y0, required this.x1, required this.y1});

  /// 좌표를 0..1 범위로 클램프하고, 경계가 뒤집힌 경우 교환하여 유효한 사각형을 돌려줍니다.
  RectNorm normalized() {
    double nx0 = x0.clamp(0.0, 1.0);
    double ny0 = y0.clamp(0.0, 1.0);
    double nx1 = x1.clamp(0.0, 1.0);
    double ny1 = y1.clamp(0.0, 1.0);
    if (nx0 > nx1) {
      final t = nx0;
      nx0 = nx1;
      nx1 = t;
    }
    if (ny0 > ny1) {
      final t = ny0;
      ny0 = ny1;
      ny1 = t;
    }
    return RectNorm(x0: nx0, y0: ny0, x1: nx1, y1: ny1);
  }

  /// 사각형이 조건을 만족하는지 검증합니다. 실패 시 [ArgumentError]를 던집니다.
  void assertValid() {
    if (x0 < 0 || x1 > 1 || y0 < 0 || y1 > 1) {
      throw ArgumentError('RectNorm out of bounds');
    }
    if (!(x0 < x1 && y0 < y1)) {
      throw ArgumentError('RectNorm must satisfy x0<x1 and y0<y1');
    }
  }
}
