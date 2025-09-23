import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/organisms/search_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_typography.dart';
import '../../../shared/routing/app_routes.dart';
import '../../../shared/widgets/navigation_card.dart';
import '../providers/note_list_controller.dart';

/// 노트 검색 전용 화면.
class NoteSearchScreen extends ConsumerStatefulWidget {
  const NoteSearchScreen({super.key});

  @override
  ConsumerState<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends ConsumerState<NoteSearchScreen> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;

  NoteListController get _actions =>
      ref.read(noteListControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    // 검색 화면 진입 시 기존 검색 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _actions.clearSearch();
    });
  }

  @override
  void dispose() {
    _actions.clearSearch();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleBack() => context.pop();

  void _handleDone() => _runSearch(_searchCtrl.text.trim());

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _runSearch(value.trim());
    });
  }

  void _runSearch(String query) {
    _actions.updateSearchQuery(query);
  }

  void _clearQuery() {
    _searchCtrl.clear();
    _actions.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NoteListState>(
      noteListControllerProvider,
      (previous, next) {
        if (_searchCtrl.text == next.searchQuery) return;
        _searchCtrl
          ..text = next.searchQuery
          ..selection = TextSelection.collapsed(
            offset: next.searchQuery.length,
          );
      },
    );

    final state = ref.watch(noteListControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SearchToolbar(
        controller: _searchCtrl,
        onBack: _handleBack,
        onDone: _handleDone,
        backSvgPath: AppIcons.chevronLeft,
        searchSvgPath: AppIcons.search,
        clearSvgPath: AppIcons.roundX,
        autofocus: true,
        onChanged: _onQueryChanged,
        onSubmitted: (_) => _handleDone(),
      ),
      body: Builder(
        builder: (_) {
          if (state.searchQuery.isEmpty) {
            return const _NoteSearchEmptyState(
              message: '검색어를 입력하세요',
            );
          }
          if (state.isSearching) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state.searchResults.isEmpty) {
            return const _NoteSearchEmptyState(
              message: '검색 결과가 없습니다',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.separated(
              itemCount: state.searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final result = state.searchResults[index];
                return NavigationCard(
                  icon: Icons.brush,
                  title: result.title,
                  subtitle: result.parentFolderName ?? '루트',
                  color: const Color(0xFF6750A4),
                  onTap: () {
                    context.pushNamed(
                      AppRoutes.noteEditName,
                      pathParameters: {'noteId': result.noteId},
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// 노트 검색 전용 빈 상태 위젯 (디자인 시스템 스타일)
class _NoteSearchEmptyState extends StatelessWidget {
  const _NoteSearchEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 디자인 토큰 아이콘 사용
          SvgPicture.asset(
            AppIcons.searchLarge,
            width: 144,
            height: 144,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.body2.copyWith(color: AppColors.gray40),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
