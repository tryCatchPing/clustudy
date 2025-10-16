import 'package:flutter/material.dart';

import '../../design_system/components/organisms/confirm_dialog.dart';
import '../../design_system/components/organisms/rename_dialog.dart';
import '../../design_system/screens/folder/widgets/folder_creation_sheet.dart';
import '../../design_system/screens/notes/widgets/note_creation_sheet.dart';
import '../../design_system/screens/vault/widgets/vault_creation_sheet.dart';
import '../errors/app_error_spec.dart';
import '../widgets/app_snackbar.dart';

Future<void> showDesignVaultCreationFlow({
  required BuildContext context,
  required Future<AppErrorSpec> Function(String name) onSubmit,
}) async {
  final rootContext = context;
  await showDesignVaultCreationSheet(
    context,
    onCreate: (name) async {
      final spec = await onSubmit(name);
      if (!rootContext.mounted) return;
      AppSnackBar.show(rootContext, spec);
    },
  );
}

Future<void> showDesignFolderCreationFlow({
  required BuildContext context,
  required Future<AppErrorSpec> Function(String name) onSubmit,
}) async {
  final rootContext = context;
  await showDesignFolderCreationSheet(
    context,
    onCreate: (name) async {
      final spec = await onSubmit(name);
      if (!rootContext.mounted) return;
      AppSnackBar.show(rootContext, spec);
    },
  );
}

Future<void> showDesignNoteCreationFlow({
  required BuildContext context,
  required Future<AppErrorSpec> Function(String name) onSubmit,
}) async {
  final rootContext = context;
  await showDesignNoteCreationSheet(
    context,
    onCreate: (name) async {
      final spec = await onSubmit(name);
      if (!rootContext.mounted) return;
      AppSnackBar.show(rootContext, spec);
    },
  );
}

Future<String?> showDesignRenameDialogTrimmed({
  required BuildContext context,
  required String title,
  required String initial,
}) async {
  final result = await showRenameDialog(
    context,
    title: title,
    initial: initial,
  );
  final trimmed = result?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

Future<bool> showDesignConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool destructive = false,
  Widget? leading,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    destructive: destructive,
    leading: leading,
  );
  return confirmed ?? false;
}
