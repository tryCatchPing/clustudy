import 'package:flutter/material.dart';

/// 캔버스 임시 배경 표시 위젯
///
/// 캔버스의 배경을 표시합니다.
class BackgroundPlaceholder extends StatelessWidget {
  const BackgroundPlaceholder({
    required this.width,
    required this.height,
    super.key,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'PDF 이미지가 로드될 예정입니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '크기: $width x $height px',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
