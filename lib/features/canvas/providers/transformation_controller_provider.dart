import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transformation_controller_provider.g.dart';

/// 확대/축소 상태를 관리하는 컨트롤러
///
/// InteractiveViewer와 함께 사용하여 다음을 관리합니다:
/// - 확대/축소 비율 (scale)
/// - 패닝(이동) 상태 (translation)
/// - 변한 매트릭스 (matrix)
@riverpod
TransformationController transformationController(
  Ref ref,
  String noteId,
) {
  final controller = TransformationController();
  ref.onDispose(controller.dispose);
  return controller;
}
