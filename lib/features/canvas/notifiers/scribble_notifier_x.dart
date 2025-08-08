import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/scribble.dart';

/// [ScribbleNotifier]에 대한 확장 메서드를 제공합니다.
extension ScribbleNotifierX on ScribbleNotifier {
  /// 현재 스케치를 이미지로 렌더링하여 다이얼로그로 표시합니다.
  ///
  /// [context]는 빌드 컨텍스트입니다.
  void showImage(BuildContext context) async {
    final image = renderImage();
    if (!context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generated Image'),
        content: SizedBox.expand(
          child: FutureBuilder(
            future: image,
            builder: (context, snapshot) => snapshot.hasData
                ? Image.memory(snapshot.data!.buffer.asUint8List())
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: context.pop,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// 현재 스케치를 JSON 형식으로 변환하여 다이얼로그로 표시합니다.
  ///
  /// [context]는 빌드 컨텍스트입니다.
  void showJson(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sketch as JSON'),
        content: SizedBox.expand(
          child: SelectableText(
            jsonEncode(currentSketch.toJson()),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: context.pop,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}