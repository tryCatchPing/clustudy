import 'package:flutter/material.dart';

import '../errors/app_error_spec.dart';

class AppSnackBar {
  static void show(BuildContext context, AppErrorSpec spec) {
    final (bg, icon) = _style(spec.severity);
    final dur = _duration(spec.duration);
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(spec.message)),
        ],
      ),
      backgroundColor: bg,
      duration: dur,
      action: spec.action == null
          ? null
          : SnackBarAction(
              label: spec.action!.label,
              textColor: Colors.white,
              onPressed: spec.action!.onPressed ?? () {},
            ),
      behavior: SnackBarBehavior.fixed,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static (Color, IconData) _style(AppErrorSeverity s) {
    switch (s) {
      case AppErrorSeverity.success:
        return (Colors.green[700]!, Icons.check_circle);
      case AppErrorSeverity.info:
        return (Colors.blue[700]!, Icons.info_outline);
      case AppErrorSeverity.warn:
        return (Colors.orange[800]!, Icons.warning_amber_outlined);
      case AppErrorSeverity.error:
        return (Colors.red[700]!, Icons.error_outline);
    }
  }

  static Duration _duration(AppErrorDuration d) {
    switch (d) {
      case AppErrorDuration.short:
        return const Duration(seconds: 2);
      case AppErrorDuration.normal:
        return const Duration(seconds: 4);
      case AppErrorDuration.long:
        return const Duration(seconds: 8);
      case AppErrorDuration.persistent:
        return const Duration(days: 1); // 사용자가 닫을 때까지 사실상 유지
    }
  }
}
