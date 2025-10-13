import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/organisms/item_actions.dart';
import '../../../canvas/models/link_model.dart';

enum LinkAction { navigate, edit, delete }

/// 저장된 링크 탭 시 표시되는 액션 시트 (앵커 기준 우측 표시, 공간 부족 시 좌측)
class LinkActionsSheet extends ConsumerWidget {
  final LinkModel link;

  const LinkActionsSheet({super.key, required this.link});

  /// 클릭/탭 지점의 글로벌 좌표(anchorGlobal)를 받아 그 지점 근처에 시트를 띄웁니다.
  /// 시트를 닫을 때까지 대기한 뒤 사용자가 선택한 액션을 반환합니다. (없으면 null)
  static Future<LinkAction?> show(
    BuildContext context,
    LinkModel link, {
    required Offset anchorGlobal,
    String? displayTitle,
  }) async {
    final name = (displayTitle?.trim().isNotEmpty == true)
        ? displayTitle!.trim()
        : ((link.label?.trim().isNotEmpty == true) ? link.label!.trim() : '링크');

    final completer = Completer<LinkAction?>();

    final sheetFuture = showItemActionsNear(
      context,
      anchorGlobal: anchorGlobal,
      handlers: ItemActionHandlers(
        onMove: () async {
          if (!completer.isCompleted) completer.complete(LinkAction.navigate);
        },
        onRename: () async {
          if (!completer.isCompleted) completer.complete(LinkAction.edit);
        },
        onDelete: () async {
          if (!completer.isCompleted) completer.complete(LinkAction.delete);
        },
      ),
      moveLabel: '$name 이동',
      renameLabel: '$name 링크 수정',
      deleteLabel: '$name 링크 삭제',
    );

    // 시트가 닫힌 직후 한 프레임 뒤에도 선택이 없다면 null로 완료
    unawaited(
      sheetFuture.then((_) async {
        await Future<void>.delayed(Duration.zero);
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }),
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 사용되지 않지만, 기존 구조 유지
    return const SizedBox.shrink();
  }
}
