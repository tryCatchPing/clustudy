// features/notes/widgets/note_creation_sheet.dart
import 'package:flutter/material.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../design_system/components/atoms/app_textfield.dart';

class NoteCreationSheet extends StatefulWidget {
  const NoteCreationSheet({
    super.key,
    required this.onCreate,          // (name) async
  });

  final Future<void> Function(String name) onCreate;

  @override
  State<NoteCreationSheet> createState() => _NoteCreationSheetState();
}

class _NoteCreationSheetState extends State<NoteCreationSheet> {
  final _c = TextEditingController(text: '새로운 노트 이름');
  bool _busy = false;

  bool get _canSubmit => !_busy && _c.text.trim().isNotEmpty;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final name = _c.text.trim();
    setState(() => _busy = true);
    try {
      await widget.onCreate(name);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreationBaseSheet(
      title: '노트 생성',
      onBack: () => Navigator.of(context).pop(),
      rightText: _busy ? '생성중...' : '생성',
      onRightTap: _canSubmit ? () => _submit() : null, // 버튼 비활성화 지원
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 미리보기 사각형 (레퍼런스 스샷처럼)
            Container(
              width: 150,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            SizedBox(
              width: 280,
              child: AppTextField(
                controller: _c,
                textAlign: TextAlign.center,
                autofocus: true,
                style: AppTextFieldStyle.none, // 다크 시트에서는 none이 깔끔
                textStyle: AppTypography.body2.copyWith(
                  color: AppColors.background,
                  height: 1.0,
                ),
                onSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}), // 버튼 활성 갱신
              ),
            ),
          ],
        ),
      ),
    );
  }
}
