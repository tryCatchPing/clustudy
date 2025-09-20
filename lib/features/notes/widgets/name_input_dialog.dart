import 'package:flutter/material.dart';

Future<String?> showNameInputDialog({
  required BuildContext context,
  required String title,
  required String hintText,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameInputDialog(
      title: title,
      hintText: hintText,
      confirmLabel: confirmLabel,
    ),
  );
}

class _NameInputDialog extends StatefulWidget {
  const _NameInputDialog({
    required this.title,
    required this.hintText,
    required this.confirmLabel,
  });

  final String title;
  final String hintText;
  final String confirmLabel;

  @override
  State<_NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<_NameInputDialog> {
  late final TextEditingController _controller;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final input = _controller.text.trim();
    if (input.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: widget.hintText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
