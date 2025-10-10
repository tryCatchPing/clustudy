import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../canvas/providers/note_editor_provider.dart';
import '../data/derived_note_providers.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';
import '../providers/page_controller_provider.dart';
import '../widgets/page_thumbnail_grid.dart';

/// 페이지 컨트롤러 모달 화면입니다.
///
/// 노트의 페이지를 관리할 수 있는 모달 다이얼로그를 제공합니다.
/// 페이지 썸네일 그리드, 페이지 추가 버튼, 드래그 앤 드롭 순서 변경 등의 기능을 포함합니다.
class PageControllerScreen extends ConsumerStatefulWidget {
  /// 관리할 노트의 ID
  final String noteId;

  const PageControllerScreen({
    super.key,
    required this.noteId,
  });

  /// 페이지 컨트롤러 모달을 표시합니다.
  ///
  /// [context]는 BuildContext이고, [noteId]는 관리할 노트의 ID입니다.
  /// 모달이 닫힐 때 변경사항이 있으면 저장 확인 다이얼로그를 표시합니다.
  static Future<void> show(BuildContext context, String noteId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // 배경 탭으로 닫기 방지
      builder: (context) => PageControllerScreen(noteId: noteId),
    );
  }

  @override
  ConsumerState<PageControllerScreen> createState() =>
      _PageControllerScreenState();
}

class _PageControllerScreenState extends ConsumerState<PageControllerScreen> {
  @override
  void initState() {
    super.initState();

    // 썸네일 미리 로드 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(preloadThumbnailsProvider(widget.noteId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final screenState = ref.watch(
      pageControllerScreenNotifierProvider(widget.noteId),
    );

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: _buildAppBar(context, screenState),
        body: noteAsync.when(
          data: (note) {
            if (note == null) {
              return _buildErrorState('노트를 찾을 수 없습니다');
            }
            return _buildBody(note, screenState);
          },
          loading: () => _buildLoadingState(),
          error: (error, stackTrace) => _buildErrorState(error.toString()),
        ),
        floatingActionButton: _buildFloatingActionButton(screenState),
      ),
    );
  }

  /// 앱바를 빌드합니다.
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PageControllerScreenState screenState,
  ) {
    return TopToolbar(
      variant: TopToolbarVariant.folder,
      title: '페이지 관리',
      backSvgPath: AppIcons.roundX,
      onBack: () => _handleClose(context, screenState),
      actions: const [],
      iconColor: AppColors.gray50,
      height: 76,
      iconSize: 32,
    );

    // TODO: "변경됨" 뱃지는 TopToolbar에 trailing 파라미터 추가 후 적용
    // if (screenState.hasUnsavedChanges) ...
  }

  /// 메인 바디를 빌드합니다.
  Widget _buildBody(
    NoteModel note,
    PageControllerScreenState screenState,
  ) {
    return Column(
      children: [
        // 오류 메시지 표시
        if (screenState.errorMessage != null) _buildErrorBanner(screenState),

        // 로딩 인디케이터
        if (screenState.isLoading) _buildLoadingBanner(screenState),

        // 페이지 정보 헤더
        _buildPageInfoHeader(note),

        // 페이지 썸네일 그리드
        Expanded(
          child: PageThumbnailGrid(
            noteId: widget.noteId,
            crossAxisCount: 3,
            spacing: 12.0,
            thumbnailSize: 140.0,
            onPageDelete: _handlePageDelete,
            onPageTap: _handlePageTap,
            onReorderComplete: _handleReorderComplete,
          ),
        ),
      ],
    );
  }

  /// 페이지 정보 헤더를 빌드합니다.
  Widget _buildPageInfoHeader(NoteModel note) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.gray20,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: AppTypography.subtitle1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '총 ${note.pages.length}개 페이지',
                  style: AppTypography.body5.copyWith(
                    color: AppColors.gray40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 오류 배너를 빌드합니다.
  Widget _buildErrorBanner(PageControllerScreenState screenState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      color: AppColors.errorLight,
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorDark,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              screenState.errorMessage!,
              style: AppTypography.body5.copyWith(
                color: AppColors.errorDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              ref
                  .read(
                    pageControllerScreenNotifierProvider(
                      widget.noteId,
                    ).notifier,
                  )
                  .clearError();
            },
            color: AppColors.errorDark,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 배너를 빌드합니다.
  Widget _buildLoadingBanner(PageControllerScreenState screenState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Text(
            screenState.operation ?? '처리 중...',
            style: AppTypography.body5.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 플로팅 액션 버튼을 빌드합니다.
  Widget? _buildFloatingActionButton(PageControllerScreenState screenState) {
    if (screenState.isLoading) {
      return null; // 로딩 중에는 버튼 숨김
    }

    return FloatingActionButton.extended(
      onPressed: _handleAddPage,
      icon: const Icon(Icons.add),
      label: const Text('페이지 추가'),
      tooltip: '새 빈 페이지 추가',
    );
  }

  /// 로딩 상태를 빌드합니다.
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('노트를 불러오는 중...'),
        ],
      ),
    );
  }

  /// 오류 상태를 빌드합니다.
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            '오류가 발생했습니다',
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.errorDark,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            error,
            style: AppTypography.body5.copyWith(
              color: AppColors.gray40,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.large),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 페이지 추가 버튼 클릭을 처리합니다.
  void _handleAddPage() async {
    await ref
        .read(pageControllerScreenNotifierProvider(widget.noteId).notifier)
        .addBlankPage();

    // 페이지 추가 후 썸네일 캐시 무효화
    ref
        .read(pageControllerNotifierProvider(widget.noteId).notifier)
        .clearThumbnailCache();
  }

  /// 페이지 삭제를 처리합니다.
  void _handlePageDelete(NotePageModel page) {
    _showDeleteConfirmDialog(page);
  }

  /// 페이지 탭을 처리합니다.
  void _handlePageTap(NotePageModel page, int index) {
    debugPrint('🧭 [PageCtrlModal] tap page=${page.pageNumber} (idx=$index)');

    // 1) 먼저 PageController에 직접 점프를 시도 (현재 프레임에서 반영)
    final routeId = ref.read(noteRouteIdProvider(widget.noteId));
    if (routeId != null) {
      final controller = ref.read(
        pageControllerProvider(widget.noteId, routeId),
      );
      if (controller.hasClients) {
        debugPrint('🧭 [PageCtrlModal] jumpToPage → $index (direct)');
        controller.jumpToPage(index);
      } else {
        debugPrint(
          '🧭 [PageCtrlModal] controller has no clients; schedule jump',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final rid = ref.read(noteRouteIdProvider(widget.noteId));
          if (rid == null) return;
          final ctrl = ref.read(pageControllerProvider(widget.noteId, rid));
          if (ctrl.hasClients) {
            debugPrint('🧭 [PageCtrlModal] jumpToPage → $index (scheduled)');
            ctrl.jumpToPage(index);
          }
        });
      }
    } else {
      debugPrint(
        '🧭 [PageCtrlModal] no active routeId; fallback to provider update only',
      );
    }

    // 2) Provider 상태를 업데이트하여 동기화 보장
    ref.read(currentPageIndexProvider(widget.noteId).notifier).setPage(index);

    // 3) 모달 닫기 (다음 프레임에 닫아 점프 반영 여지 확보)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  /// 페이지 순서 변경 완료를 처리합니다.
  void _handleReorderComplete(List<NotePageModel> reorderedPages) {
    // 순서 변경은 PageThumbnailGrid에서 자동으로 저장되므로
    // 여기서는 추가 처리가 필요하지 않습니다.
  }

  /// 모달 닫기를 처리합니다.
  void _handleClose(
    BuildContext context,
    PageControllerScreenState screenState,
  ) {
    if (screenState.hasUnsavedChanges) {
      _showUnsavedChangesDialog(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 삭제 확인 다이얼로그를 표시합니다.
  void _showDeleteConfirmDialog(NotePageModel page) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 삭제'),
        content: Text(
          '페이지 ${page.pageNumber}을(를) 삭제하시겠습니까?\n\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(
                    pageControllerScreenNotifierProvider(
                      widget.noteId,
                    ).notifier,
                  )
                  .deletePage(page);

              // 페이지 삭제 후 썸네일 캐시 무효화
              ref
                  .read(pageControllerNotifierProvider(widget.noteId).notifier)
                  .clearThumbnailCache();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 저장되지 않은 변경사항 다이얼로그를 표시합니다.
  void _showUnsavedChangesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('변경사항 저장'),
        content: const Text(
          '변경된 내용이 있습니다.\n'
          '저장하지 않고 나가시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 페이지 컨트롤러 닫기
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('저장하지 않고 나가기'),
          ),
        ],
      ),
    );
  }
}
