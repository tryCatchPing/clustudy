import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../shared/services/page_order_service.dart';
import '../../canvas/providers/note_editor_provider.dart';
import '../data/derived_note_providers.dart';
import '../data/notes_repository_provider.dart';
import '../models/note_page_model.dart';
import 'draggable_page_thumbnail.dart';

/// 페이지 썸네일을 그리드 형태로 표시하는 위젯입니다.
///
/// 드래그 앤 드롭을 통한 순서 변경, 지연 로딩, 가상화를 지원합니다.
class PageThumbnailGrid extends ConsumerStatefulWidget {
  /// 표시할 노트의 ID.
  final String noteId;

  /// 그리드의 열 개수 (기본값: 3).
  final int crossAxisCount;

  /// 썸네일 간격 (기본값: 8.0).
  final double spacing;

  /// 썸네일 크기 (기본값: 120.0).
  final double thumbnailSize;

  /// 페이지 삭제 콜백.
  final void Function(NotePageModel page)? onPageDelete;

  /// 페이지 탭 콜백.
  final void Function(NotePageModel page, int index)? onPageTap;

  /// 순서 변경 완료 콜백.
  final void Function(List<NotePageModel> reorderedPages)? onReorderComplete;

  /// [PageThumbnailGrid]의 생성자.
  const PageThumbnailGrid({
    super.key,
    required this.noteId,
    this.crossAxisCount = 3,
    this.spacing = 8.0,
    this.thumbnailSize = 120.0,
    this.onPageDelete,
    this.onPageTap,
    this.onReorderComplete,
  });

  @override
  ConsumerState<PageThumbnailGrid> createState() => _PageThumbnailGridState();
}

class _PageThumbnailGridState extends ConsumerState<PageThumbnailGrid> {
  /// 현재 드래그 중인 페이지의 인덱스.
  int? _draggingIndex;

  /// 드래그 오버 중인 위치의 인덱스.
  int? _dragOverIndex;

  /// 페이지 순서 변경 중인지 여부.
  bool _isReordering = false;

  /// 임시 페이지 순서 (드래그 중 미리보기용).
  List<NotePageModel>? _tempPages;

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final pageControllerState = ref.watch(
      pageControllerNotifierProvider(widget.noteId),
    );

    return noteAsync.when(
      data: (note) {
        if (note == null || note.pages.isEmpty) {
          return _buildEmptyState();
        }

        // 드래그 중이면 임시 순서 사용, 아니면 원본 순서 사용
        final pages = _tempPages ?? note.pages;

        return _buildGrid(pages, pageControllerState);
      },
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error),
    );
  }

  /// 그리드를 빌드합니다.
  Widget _buildGrid(
    List<NotePageModel> pages,
    PageControllerState pageControllerState,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 가용 너비에 따라 동적으로 열 개수 조정
        final availableWidth = constraints.maxWidth;
        final itemWidth = widget.thumbnailSize + widget.spacing;
        final dynamicCrossAxisCount = (availableWidth / itemWidth)
            .floor()
            .clamp(1, widget.crossAxisCount);

        return GridView.builder(
          padding: EdgeInsets.all(widget.spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: dynamicCrossAxisCount,
            crossAxisSpacing: widget.spacing,
            mainAxisSpacing: widget.spacing,
            childAspectRatio: 1.0,
          ),
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return _buildGridItem(
              pages[index],
              index,
              pageControllerState,
            );
          },
        );
      },
    );
  }

  /// 그리드 아이템을 빌드합니다.
  Widget _buildGridItem(
    NotePageModel page,
    int index,
    PageControllerState pageControllerState,
  ) {
    final isDragging = _draggingIndex == index;
    final isDropTarget = _dragOverIndex == index && !isDragging;
    final thumbnail = pageControllerState.getThumbnail(page.pageId);

    return DragTarget<NotePageModel>(
      onWillAcceptWithDetails: (details) {
        // 자기 자신으로의 드롭은 허용하지 않음
        return details.data.pageId != page.pageId;
      },
      onAcceptWithDetails: (details) {
        _handleDrop(details.data, index);
      },
      onMove: (details) {
        if (_dragOverIndex != index) {
          setState(() {
            _dragOverIndex = index;
          });
        }
      },
      onLeave: (data) {
        if (_dragOverIndex == index) {
          setState(() {
            _dragOverIndex = null;
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isDropTarget
                ? Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  )
                : null,
            color: isDropTarget
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : null,
          ),
          child: Stack(
            children: [
              // 드롭 가능한 위치 표시
              if (isDropTarget) _buildDropIndicator(),

              // 썸네일 위젯
              DraggablePageThumbnail(
                key: ValueKey(page.pageId), // 고유한 Key 설정
                page: page,
                thumbnail: thumbnail,
                size: widget.thumbnailSize,
                isDragging: isDragging,
                onDelete: widget.onPageDelete != null
                    ? () => widget.onPageDelete!(page)
                    : null,
                onTap: widget.onPageTap != null
                    ? () => widget.onPageTap!(page, index)
                    : null,
                onDragStart: () => _handleDragStart(index),
                onDragEnd: () => _handleDragEnd(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 드롭 인디케이터를 빌드합니다.
  Widget _buildDropIndicator() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.small),
          border: Border.all(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.medium),
            ),
            child: Text(
              '여기에 놓기',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 빈 상태를 빌드합니다.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            color: AppColors.gray30,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            '페이지가 없습니다',
            style: AppTypography.body3.copyWith(
              color: AppColors.gray40,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            '새 페이지를 추가해보세요',
            style: AppTypography.body5.copyWith(
              color: AppColors.gray30,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 상태를 빌드합니다.
  Widget _buildLoadingState() {
    return GridView.builder(
      padding: EdgeInsets.all(widget.spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.spacing,
        mainAxisSpacing: widget.spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: 6, // 스켈레톤 아이템 개수
      itemBuilder: (context, index) {
        return _buildSkeletonItem();
      },
    );
  }

  /// 스켈레톤 아이템을 빌드합니다.
  Widget _buildSkeletonItem() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray10,
        borderRadius: BorderRadius.circular(AppSpacing.small),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 오류 상태를 빌드합니다.
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            '페이지를 불러올 수 없습니다',
            style: AppTypography.body3.copyWith(
              color: AppColors.errorDark,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            error.toString(),
            style: AppTypography.caption.copyWith(
              color: AppColors.gray40,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          ElevatedButton(
            onPressed: () {
              // 새로고침
              ref.invalidate(noteProvider(widget.noteId));
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 드래그 시작을 처리합니다.
  void _handleDragStart(int index) {
    setState(() {
      _draggingIndex = index;
      _dragOverIndex = null;
    });

    // 페이지 컨트롤러 상태에 드래그 시작 알림
    final note = ref.read(noteProvider(widget.noteId)).value;
    if (note != null && index < note.pages.length) {
      final page = note.pages[index];
      final validDropIndices = List.generate(note.pages.length, (i) => i);

      ref
          .read(pageControllerNotifierProvider(widget.noteId).notifier)
          .startDrag(page.pageId, index, validDropIndices);
    }
  }

  /// 드래그 종료를 처리합니다.
  void _handleDragEnd() {
    setState(() {
      _draggingIndex = null;
      _dragOverIndex = null;
      _tempPages = null;
      _isReordering = false;
    });

    // 페이지 컨트롤러 상태에 드래그 종료 알림
    ref.read(pageControllerNotifierProvider(widget.noteId).notifier).endDrag();
  }

  /// 드롭을 처리합니다.
  void _handleDrop(NotePageModel draggedPage, int dropIndex) async {
    final note = ref.read(noteProvider(widget.noteId)).value;
    if (note == null || _isReordering) {
      return;
    }

    final dragIndex = note.pages.indexWhere(
      (p) => p.pageId == draggedPage.pageId,
    );

    if (dragIndex == -1 || dragIndex == dropIndex) {
      _handleDragEnd();
      return;
    }

    setState(() {
      _isReordering = true;
    });

    try {
      // 페이지 순서 변경
      final reorderedPages = PageOrderService.reorderPages(
        note.pages,
        dragIndex,
        dropIndex,
      );

      // 페이지 번호 재매핑
      final remappedPages = PageOrderService.remapPageNumbers(reorderedPages);

      // 임시로 UI 업데이트
      setState(() {
        _tempPages = remappedPages;
      });

      // Repository를 통해 저장
      final repository = ref.read(notesRepositoryProvider);
      await PageOrderService.saveReorderedPages(
        widget.noteId,
        remappedPages,
        repository,
      );

      // 콜백 호출
      widget.onReorderComplete?.call(remappedPages);

      // 성공적으로 저장되면 임시 상태 클리어
      setState(() {
        _tempPages = null;
      });
    } catch (e) {
      // 오류 발생 시 롤백
      setState(() {
        _tempPages = null;
      });

      // 오류 상태 설정
      ref
          .read(pageControllerNotifierProvider(widget.noteId).notifier)
          .setError('페이지 순서 변경 실패: $e');

      // 스낵바로 오류 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('페이지 순서 변경에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _handleDragEnd();
    }
  }
}
