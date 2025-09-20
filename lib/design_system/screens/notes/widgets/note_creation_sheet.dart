import 'package:flutter/material.dart';

import '../../../components/organisms/creation_sheet.dart';
import '../../../components/atoms/app_textfield.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';

Future<void> showDesignNoteCreationSheet(
  BuildContext context, {
  Future<void> Function(String name)? onCreate,
}) {
  return showCreationSheet(
    context,
    _DesignNoteCreationSheet(onCreate: onCreate),
  );
}

class _DesignNoteCreationSheet extends StatefulWidget {
  const _DesignNoteCreationSheet({this.onCreate});

  final Future<void> Function(String name)? onCreate;

  @override
  State<_DesignNoteCreationSheet> createState() =>
      _DesignNoteCreationSheetState();
}

class _DesignNoteCreationSheetState extends State<_DesignNoteCreationSheet> {
  final _controller = TextEditingController();
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
    final name = _controller.text.trim();
    if (widget.onCreate != null) {
      await widget.onCreate!(name);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" 노트 생성')),
        );
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(name);
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
