import 'package:flutter/material.dart';

import '../../../components/organisms/creation_sheet.dart';
import '../../../components/atoms/app_textfield.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';

Future<void> showDesignNoteCreationSheet(BuildContext context) {
  return showCreationSheet(context, const _DesignNoteCreationSheet());
}

class _DesignNoteCreationSheet extends StatefulWidget {
  const _DesignNoteCreationSheet();

  @override
  State<_DesignNoteCreationSheet> createState() => _DesignNoteCreationSheetState();
}

class _DesignNoteCreationSheetState extends State<_DesignNoteCreationSheet> {
  final _controller = TextEditingController(text: '새로운 노트 이름');
  bool _busy = false;

  bool get _canSubmit => !_busy && _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${_controller.text.trim()}" 노트 생성')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CreationBaseSheet(
      title: '노트 생성',
      onBack: () => Navigator.of(context).pop(),
      rightText: _busy ? '생성중...' : '생성',
      onRightTap: _canSubmit ? _submit : null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              width: 280,
              child: AppTextField(
                controller: _controller,
                textAlign: TextAlign.center,
                autofocus: true,
                style: AppTextFieldStyle.none,
                textStyle: AppTypography.body2.copyWith(
                  color: AppColors.white,
                  height: 1.0,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
