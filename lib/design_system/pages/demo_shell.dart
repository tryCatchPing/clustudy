import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/design_system_routes.dart';
import '../tokens/app_colors.dart';

/// 🏗️ 디자인 시스템 데모 셸
/// 
/// 좌측 네비게이션과 우측 컨텐츠 영역으로 구성된 데모 환경
/// 디자이너와 개발자가 컴포넌트를 쉽게 탐색하고 테스트할 수 있는 인터페이스
class DemoShell extends StatelessWidget {
  const DemoShell({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // ================== Left Navigation Panel ==================
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Design System',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Component showcase & testing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildSectionHeader('📋 Figma Pages'),
                      _buildNavItem(
                        context,
                        icon: Icons.edit_note,
                        title: 'Note Editor',
                        subtitle: 'Complete note editing interface',
                        route: DesignSystemRoutes.noteEditorDemo,
                        isActive: _isCurrentRoute(context, DesignSystemRoutes.noteEditorDemo),
                      ),

                      const SizedBox(height: 16),
                      _buildSectionHeader('🧩 Components'),
                      _buildNavItem(
                        context,
                        icon: Icons.build_circle,
                        title: 'Toolbar Components',
                        subtitle: 'Color picker, tools, controls',
                        route: DesignSystemRoutes.toolbarDemo,
                        isActive: _isCurrentRoute(context, DesignSystemRoutes.toolbarDemo),
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.widgets,
                        title: 'Atomic Components',
                        subtitle: 'Buttons, circles, basic elements',
                        route: DesignSystemRoutes.atomsDemo,
                        isActive: _isCurrentRoute(context, DesignSystemRoutes.atomsDemo),
                      ),

                      const SizedBox(height: 16),
                      _buildSectionHeader('🎨 Design Tokens'),
                      _buildInfoItem(
                        icon: Icons.color_lens,
                        title: 'Colors',
                        subtitle: '${_getColorCount()} colors defined',
                      ),
                      _buildInfoItem(
                        icon: Icons.text_fields,
                        title: 'Typography',
                        subtitle: 'Font styles & sizes',
                      ),
                      _buildInfoItem(
                        icon: Icons.space_bar,
                        title: 'Spacing',
                        subtitle: 'Margin & padding system',
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Tips',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Click components to interact\n• Check console for debug info\n• Use browser back/forward',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================== Right Content Area ==================
          Expanded(
            child: Container(
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: isActive 
              ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
              : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.primary : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? AppColors.primary : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentRoute(BuildContext context, String route) {
    return GoRouterState.of(context).uri.path == route;
  }

  int _getColorCount() {
    // AppColors 클래스의 static 필드 개수를 반환
    // 실제로는 리플렉션을 사용하거나 수동으로 계산
    return 25; // 대략적인 색상 개수
  }
}