import 'package:flutter/material.dart';

import '../../components/organisms/top_toolbar.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_icons.dart';

/// Placeholder graph view used only for design demos. The production screen
/// renders interactive relationships based on store data; here we focus on the
/// surrounding chrome so designers can iterate quickly.
class DesignGraphScreen extends StatelessWidget {
  const DesignGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: '그래프 뷰',
        actions: [ToolbarAction(svgPath: AppIcons.settings, onTap: () {})],
      ),
      body: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const SizedBox(
            height: 320,
            width: 480,
            child: Center(
              child: Text(
                '그래프 결과 미리보기\n(vault relationships)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray40, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
