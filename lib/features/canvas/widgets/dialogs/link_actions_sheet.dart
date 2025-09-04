import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../canvas/models/link_model.dart';

enum LinkAction { navigate, edit, delete }

/// 저장된 링크 탭 시 표시되는 액션 시트
class LinkActionsSheet extends ConsumerWidget {
  final LinkModel link;

  const LinkActionsSheet({super.key, required this.link});

  static Future<LinkAction?> show(BuildContext context, LinkModel link) {
    return showModalBottomSheet<LinkAction>(
      context: context,
      builder: (ctx) => LinkActionsSheet(link: link),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('링크로 이동'),
            onTap: () {
              debugPrint(
                '[LinkActionSheet] navigate linkId=${link.id} '
                'tgtNote=${link.targetNoteId}',
              );
              Navigator.of(context).pop(LinkAction.navigate);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('링크 수정'),
            onTap: () {
              debugPrint('[LinkActionSheet] edit linkId=${link.id}');
              Navigator.of(context).pop(LinkAction.edit);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('링크 삭제'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              debugPrint('[LinkActionSheet] delete linkId=${link.id}');
              Navigator.of(context).pop(LinkAction.delete);
            },
          ),
        ],
      ),
    );
  }
}
