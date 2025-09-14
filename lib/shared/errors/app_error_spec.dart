import 'package:flutter/foundation.dart';

/// 표준화된 스낵바/토스트 표출 스펙
class AppErrorSpec {
  final AppErrorSeverity severity;
  final String message;
  final AppErrorAction? action;
  final AppErrorDuration duration;

  const AppErrorSpec({
    required this.severity,
    required this.message,
    this.action,
    this.duration = AppErrorDuration.normal,
  });

  factory AppErrorSpec.success(String message) => AppErrorSpec(
    severity: AppErrorSeverity.success,
    message: message,
    duration: AppErrorDuration.short,
  );

  factory AppErrorSpec.info(String message) => AppErrorSpec(
    severity: AppErrorSeverity.info,
    message: message,
  );

  factory AppErrorSpec.warn(String message) => AppErrorSpec(
    severity: AppErrorSeverity.warn,
    message: message,
  );

  factory AppErrorSpec.error(String message) => AppErrorSpec(
    severity: AppErrorSeverity.error,
    message: message,
  );
}

enum AppErrorSeverity { success, info, warn, error }

enum AppErrorDuration { short, normal, long, persistent }

class AppErrorAction {
  final String label;
  final VoidCallback? onPressed;
  const AppErrorAction({required this.label, this.onPressed});
}
