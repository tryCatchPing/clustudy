// lib/features/notes/pages/note_pages_screen.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/organisms/note_page_grid.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';

class NotePagesScreen extends StatefulWidget {
  const NotePagesScreen({
    super.key,
    required this.title,
    required this.initialPages, // 초기 페이지들 (미리보기, 페이지 번호)
    required this.noteId,
    this.onBack,
    this.onOpenPage, // 페이지 열기(보기/편집) 콜백
  });

  final String title;
  final List<NotePageItem> initialPages;
  final String noteId;
  final VoidCallback? onBack;
  final ValueChanged<int>? onOpenPage;

  @override
  State<NotePagesScreen> createState() => _NotePagesScreenState();
}

class _NotePagesScreenState extends State<NotePagesScreen> {
  late List<NotePageItem> _pages;
  int? _selected; // 현재 선택 인덱스

  @override
  void initState() {
    super.initState();
    _pages = List.of(widget.initialPages);
  }

  void _enterSelect(int index) {
    setState(() {
      _selected = index;
      _markSelected();
    });
  }

  void _clearSelect() {
    if (_selected == null) return;
    setState(() {
      _selected = null;
      _markSelected();
    });
  }

  void _markSelected() {
    _pages = [
      for (int i = 0; i < _pages.length; i++)
        NotePageItem(
          previewImage: _pages[i].previewImage,
          pageNumber: _pages[i].pageNumber,
          selected: _selected == i,
        ),
    ];
  }

  void _reindexPages() {
    _pages = [
      for (int i = 0; i < _pages.length; i++)
        NotePageItem(
          previewImage: _pages[i].previewImage,
          pageNumber: i + 1,
          selected: _selected == i,
        ),
    ];
  }

  Future<void> _addPage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = res?.files.firstOrNull?.bytes;
    if (bytes == null) return;
    setState(() {
      _pages.add(
        NotePageItem(previewImage: bytes, pageNumber: _pages.length + 1, selected: false,),
      );
    });
  }

  void _duplicateSelected() {
    if (_selected == null) return;
    final i = _selected!;
    final src = _pages[i];
    final copy = NotePageItem(
      previewImage: Uint8List.fromList(src.previewImage),
      pageNumber: src.pageNumber + 1,
    );
    setState(() {
      _pages.insert(i + 1, copy);
      _selected = i + 1; // 방금 복제한 것 유지
      _reindexPages();
    });
  }

  void _deleteSelected() {
    if (_selected == null) return;
    setState(() {
      _pages.removeAt(_selected!);
      _selected = null;
      _reindexPages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inSelection = _selected != null;
    return GestureDetector(
      // 빈 공간 탭하면 선택 해제 (스크린샷처럼 넓은 캔버스 느낌)
      onTap: _clearSelect,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.background, // 예: #FEFCF3
        appBar: TopToolbar(
          variant: TopToolbarVariant.folder,
          title: widget.title,
          onBack: () => context.pop(),
          backSvgPath: AppIcons.chevronLeft,
          // 선택 중일 때만 오른쪽 아이콘 노출
          actions: inSelection
              ? [
                  ToolbarAction(
                    svgPath: AppIcons.copy,
                    onTap: _duplicateSelected,
                    tooltip: '복제',
                  ),
                  ToolbarAction(
                    svgPath: AppIcons.trash,
                    onTap: _deleteSelected,
                    tooltip: '삭제',
                  ),
                ]
              : const [],
          iconColor: AppColors.gray50,
          height: 76,
          iconSize: 32,
        ),
        body: NotePageGrid(
          pages: _pages,
          onTapPage: (i) {
            if (inSelection) {
              // 선택 모드 중엔 탭 → 선택 대상 변경
              _enterSelect(i);
            } else {
              // 평소엔 탭 → 페이지 열기
              widget.onOpenPage?.call(i);
            }
          },
          onLongPressPage: _enterSelect,
          onAddPage: _addPage,
          // padding/crossAxisGap/mainAxisGap은 기본값 사용(이미 디자인 토큰 반영)
        ),
      ),
    );
  }
}
