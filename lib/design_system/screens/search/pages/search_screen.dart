import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../components/organisms/folder_grid.dart';
import '../../../components/organisms/search_toolbar.dart';
import '../../../tokens/app_colors.dart';
import '../../../tokens/app_icons.dart'; // 아이콘 경로 가정
import '../../../tokens/app_typography.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<FolderGridItem> _items = const [];

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleBack() => context.pop();

  void _handleDone() => _runSearch(_controller.text.trim());

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _runSearch(v.trim());
    });
  }

  Future<void> _runSearch(String q) async {
    if (q.isEmpty) {
      setState(() => _items = const []);
      return;
    }
    // TODO: 나중에 백엔드 검색으로 교체
    // 데모: 아무 문자열이면 8개 카드 렌더
    final demo = List.generate(
      8,
      (_) => FolderGridItem(
        svgIconPath: AppIcons.folderXLarge, // 폴더면 svg 사용
        title: '폴더 이름',
        date: DateTime(2025, 6, 24),
        onTap: () {
          /* TODO */
        },
      ),
    );
    setState(() => _items = demo);
  }

  @override
  Widget build(BuildContext context) {
    final showEmpty = _items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SearchToolbar(
        controller: _controller,
        onBack: _handleBack,
        onDone: _handleDone,
        backSvgPath: AppIcons.chevronLeft,
        searchSvgPath: AppIcons.search,
        clearSvgPath: AppIcons.roundX,
        autofocus: true,
        onChanged: _onChanged,
        onSubmitted: (_) => _handleDone(),
      ),
      body: showEmpty
          ? const _SearchEmptyState(message: '검색어를 입력하세요')
          : FolderGrid(items: _items),
    );
  }
}

// 같은 파일 내 간단 빈 상태 위젯
class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.message});
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
            // 필요하면 AppTypography.caption으로 교체
            style: AppTypography.body2.copyWith(color: AppColors.gray40),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
