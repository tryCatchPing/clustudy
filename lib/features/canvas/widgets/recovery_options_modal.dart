import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/services/pdf_recovery_service.dart';

/// 파일 손상 감지 시 표시되는 복구 옵션 모달
///
/// 손상 유형에 따라 다른 복구 옵션을 제공합니다:
/// - 이미지 파일 누락: 재렌더링, 필기만 보기, 노트 삭제
/// - PDF 파일 누락: 필기만 보기, 노트 삭제
/// - 둘 다 누락: 노트 삭제만 가능
class RecoveryOptionsModal extends StatelessWidget {
  /// [RecoveryOptionsModal]의 생성자.
  ///
  /// [corruptionType]은 감지된 손상 유형입니다.
  /// [noteTitle]은 손상된 노트의 제목입니다.
  /// [onRerender]는 재렌더링 버튼을 눌렀을 때 호출되는 콜백 함수입니다.
  /// [onSketchOnly]는 필기만 보기 버튼을 눌렀을 때 호출되는 콜백 함수입니다.
  /// [onDelete]는 노트 삭제 버튼을 눌렀을 때 호출되는 콜백 함수입니다.
  const RecoveryOptionsModal({
    required this.corruptionType,
    required this.noteTitle,
    required this.onRerender,
    required this.onSketchOnly,
    required this.onDelete,
    super.key,
  });

  /// 감지된 손상 유형.
  final CorruptionType corruptionType;

  /// 손상된 노트의 제목.
  final String noteTitle;

  /// 재렌더링 버튼을 눌렀을 때 호출되는 콜백 함수.
  final VoidCallback onRerender;

  /// 필기만 보기 버튼을 눌렀을 때 호출되는 콜백 함수.
  final VoidCallback onSketchOnly;

  /// 노트 삭제 버튼을 눌렀을 때 호출되는 콜백 함수.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 48,
        color: Colors.orange[600],
      ),
      title: const Text(
        '파일 손상 감지',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"$noteTitle" 노트에서 ${_getCorruptionDescription()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildInfoBox(),
          const SizedBox(height: 16),
          _buildOptionsContainer(),
        ],
      ),
      actions: _buildActionButtons(context),
    );
  }

  /// 손상 유형에 따른 설명을 반환합니다.
  String _getCorruptionDescription() {
    switch (corruptionType) {
      case CorruptionType.imageFileMissing:
        return '이미지 파일이 손상되었거나 찾을 수 없습니다.';
      case CorruptionType.sourcePdfMissing:
        return '원본 PDF 파일을 찾을 수 없습니다.';
      case CorruptionType.bothMissing:
        return '이미지와 PDF 파일 모두 손상되었습니다.';
      case CorruptionType.imageFileCorrupted:
        return '이미지 파일이 손상되었습니다.';
      case CorruptionType.unknown:
        return '알 수 없는 오류가 발생했습니다.';
    }
  }

  /// 정보 박스를 생성합니다.
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getInfoMessage(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 손상 유형에 따른 정보 메시지를 반환합니다.
  String _getInfoMessage() {
    switch (corruptionType) {
      case CorruptionType.imageFileMissing:
      case CorruptionType.imageFileCorrupted:
        return '재렌더링을 선택하면 원본 PDF로부터 이미지를 다시 생성합니다. '
            '필기 데이터는 보존됩니다.';
      case CorruptionType.sourcePdfMissing:
        return '원본 PDF가 없어 재렌더링할 수 없습니다. '
            '필기만 보기를 선택하면 배경 없이 필기만 표시됩니다.';
      case CorruptionType.bothMissing:
        return '파일을 복구할 수 없습니다. 노트를 삭제하는 것을 권장합니다.';
      case CorruptionType.unknown:
        return '문제를 해결하기 위해 재렌더링을 시도해보세요.';
    }
  }

  /// 복구 옵션 컨테이너를 생성합니다.
  Widget _buildOptionsContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '복구 옵션:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildOptionsList(),
        ],
      ),
    );
  }

  /// 손상 유형에 따른 옵션 목록을 생성합니다.
  List<Widget> _buildOptionsList() {
    final options = <Widget>[];

    switch (corruptionType) {
      case CorruptionType.imageFileMissing:
      case CorruptionType.imageFileCorrupted:
      case CorruptionType.unknown:
        options.addAll([
          _buildOptionItem(
            icon: Icons.refresh,
            title: '재렌더링',
            description: '원본 PDF에서 이미지를 다시 생성',
            color: Colors.blue[600]!,
          ),
          const SizedBox(height: 6),
          _buildOptionItem(
            icon: Icons.visibility_off,
            title: '필기만 보기',
            description: '배경 없이 필기만 표시',
            color: Colors.green[600]!,
          ),
          const SizedBox(height: 6),
          _buildOptionItem(
            icon: Icons.delete_outline,
            title: '노트 삭제',
            description: '노트를 완전히 삭제',
            color: Colors.red[600]!,
          ),
        ]);
        break;

      case CorruptionType.sourcePdfMissing:
        options.addAll([
          _buildOptionItem(
            icon: Icons.visibility_off,
            title: '필기만 보기',
            description: '배경 없이 필기만 표시',
            color: Colors.green[600]!,
          ),
          const SizedBox(height: 6),
          _buildOptionItem(
            icon: Icons.delete_outline,
            title: '노트 삭제',
            description: '노트를 완전히 삭제',
            color: Colors.red[600]!,
          ),
        ]);
        break;

      case CorruptionType.bothMissing:
        options.add(
          _buildOptionItem(
            icon: Icons.delete_outline,
            title: '노트 삭제',
            description: '복구 불가능 - 노트를 삭제해야 합니다',
            color: Colors.red[600]!,
          ),
        );
        break;
    }

    return options;
  }

  /// 개별 옵션 아이템을 생성합니다.
  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 액션 버튼들을 생성합니다.
  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    // 삭제 버튼은 항상 추가
    buttons.add(
      TextButton(
        onPressed: () {
          context.pop();
          onDelete();
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.red[600],
        ),
        child: const Text('삭제'),
      ),
    );

    // 손상 유형에 따른 추가 버튼들
    switch (corruptionType) {
      case CorruptionType.imageFileMissing:
      case CorruptionType.imageFileCorrupted:
      case CorruptionType.unknown:
        buttons.addAll([
          TextButton(
            onPressed: () {
              context.pop();
              onSketchOnly();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[600],
            ),
            child: const Text('필기만 보기'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.pop();
              onRerender();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('재렌더링'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ]);
        break;

      case CorruptionType.sourcePdfMissing:
        buttons.add(
          ElevatedButton.icon(
            onPressed: () {
             context.pop();
              onSketchOnly();
            },
            icon: const Icon(Icons.visibility_off),
            label: const Text('필기만 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        );
        break;

      case CorruptionType.bothMissing:
        // 삭제 버튼만 표시 (이미 추가됨)
        break;
    }

    return buttons;
  }

  /// 복구 옵션 모달을 표시합니다.
  ///
  /// [context]는 빌드 컨텍스트입니다.
  /// [corruptionType]은 감지된 손상 유형입니다.
  /// [noteTitle]은 손상된 노트의 제목입니다.
  /// [onRerender]는 재렌더링 버튼을 눌렀을 때 호출되는 콜백 함수입니다.
  /// [onSketchOnly]는 필기만 보기 버튼을 눌렀을 때 호출되는 콜백 함수입니다.
  /// [onDelete]는 노트 삭제 버튼을 눌렀을 때 호출되는 콜백 함수입니다.
  static Future<void> show(
    BuildContext context, {
    required CorruptionType corruptionType,
    required String noteTitle,
    required VoidCallback onRerender,
    required VoidCallback onSketchOnly,
    required VoidCallback onDelete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 반드시 선택하도록 함
      builder: (context) => RecoveryOptionsModal(
        corruptionType: corruptionType,
        noteTitle: noteTitle,
        onRerender: onRerender,
        onSketchOnly: onSketchOnly,
        onDelete: onDelete,
      ),
    );
  }
}