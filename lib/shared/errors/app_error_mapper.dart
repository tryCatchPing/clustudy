import 'package:flutter/foundation.dart';

import 'app_error_spec.dart';

/// 예외(Object)를 표준 스낵바 스펙으로 변환
class AppErrorMapper {
  static AppErrorSpec toSpec(Object error, {StackTrace? st}) {
    final text = (error is Exception || error is Error)
        ? error.toString()
        : String.fromCharCodes('$error'.runes);

    // Format/Validation
    if (error is FormatException) {
      return AppErrorSpec.warn(
        error.message.isNotEmpty ? error.message : '입력 형식이 올바르지 않습니다.',
      );
    }

    // Common heuristics
    final lower = text.toLowerCase();
    if (error is StateError) {
      return AppErrorSpec.warn(
        error.message.isNotEmpty
            ? error.message
            : '요청을 처리할 수 없습니다. 입력을 확인해 주세요.',
      );
    }
    if (lower.contains('already exists')) {
      return AppErrorSpec.error('이미 존재하는 이름입니다. 다른 이름을 입력해 주세요.');
    }
    if (lower.contains('not found')) {
      return AppErrorSpec.warn('대상을 찾을 수 없습니다. 새로고침 후 다시 시도해 주세요.');
    }
    if (lower.contains('cycle detected')) {
      return AppErrorSpec.warn('자기 자신/하위 폴더로 이동할 수 없습니다.');
    }
    if (lower.contains('target folder not found')) {
      return AppErrorSpec.warn('대상 폴더를 찾을 수 없습니다. 같은 Vault 내에서만 이동할 수 있어요.');
    }

    // System/Unknown
    if (kDebugMode) {
      final dbg = text.length > 200 ? '${text.substring(0, 200)}…' : text;
      return AppErrorSpec(
        severity: AppErrorSeverity.error,
        message: '알 수 없는 오류가 발생했어요. ($dbg)',
        duration: AppErrorDuration.persistent,
      );
    }
    return const AppErrorSpec(
      severity: AppErrorSeverity.error,
      message: '알 수 없는 오류가 발생했어요. 잠시 후 다시 시도해 주세요.',
      duration: AppErrorDuration.persistent,
    );
  }
}
