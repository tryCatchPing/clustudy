import 'package:flutter/material.dart';

/// 색상 버튼 위젯
///
/// 캔버스에서 사용할 색상 버튼을 생성합니다.
class NoteEditorColorButton extends StatelessWidget {
  /// [NoteEditorColorButton]의 생성자.
  ///
  /// [color]는 버튼의 배경 색상입니다.
  /// [isActive]는 버튼이 활성화 상태인지 여부입니다.
  /// [onPressed]는 버튼 클릭 시 호출될 콜백 함수입니다.
  /// [outlineColor]는 버튼의 테두리 색상입니다. (선택 사항)
  /// [child]는 버튼 내부에 표시될 위젯입니다. (선택 사항)
  /// [tooltip]은 버튼에 대한 툴팁 텍스트입니다. (선택 사항)
  const NoteEditorColorButton({
    required this.color,
    required this.isActive,
    required this.onPressed,
    this.outlineColor,
    this.child,
    this.tooltip,
    super.key,
  });

  /// 버튼의 배경 색상.
  final Color color;

  /// 버튼의 테두리 색상. (선택 사항)
  final Color? outlineColor;

  /// 버튼이 활성화 상태인지 여부.
  final bool isActive;

  /// 버튼 클릭 시 호출될 콜백 함수.
  final VoidCallback onPressed;

  /// 버튼 내부에 표시될 위젯. (선택 사항)
  final Icon? child;

  /// 버튼에 대한 툴팁 텍스트. (선택 사항)
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: 36,
      height: 36,
      duration: kThemeAnimationDuration,
      decoration: ShapeDecoration(
        shape: CircleBorder(
          side: BorderSide(
            color: switch (isActive) {
              true => outlineColor ?? color,
              false => Colors.transparent,
            },
            width: 2,
          ),
        ),
      ),
      child: IconButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: const CircleBorder(),
          side: isActive
              ? const BorderSide(color: Colors.white, width: 2)
              : const BorderSide(color: Colors.transparent),
          minimumSize: const Size(32, 32), // 기본 48x48에서 32x32로 축소 (2/3)
          padding: const EdgeInsets.all(4), // 패딩 축소
        ),
        onPressed: onPressed,
        icon: child ?? const SizedBox(),
        tooltip: tooltip,
      ),
    );
  }
}