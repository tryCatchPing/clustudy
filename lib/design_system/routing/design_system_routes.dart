import 'package:go_router/go_router.dart';
import '../pages/demo_shell.dart';
import '../pages/figma_pages/note_editor_demo.dart';
import '../pages/component_showcase/toolbar_demo.dart';
import '../pages/component_showcase/atoms_demo.dart';

/// 🎨 디자인 시스템 데모 라우트 정의
/// 
/// 컴포넌트 테스트, Figma 디자인 재현, 팀 협업을 위한 라우팅 시스템
class DesignSystemRoutes {
  DesignSystemRoutes._();

  // ================== Route Paths ==================
  /// 디자인 시스템 메인 경로
  static const String designSystem = '/design-system';
  
  /// 툴바 컴포넌트 데모
  static const String toolbarDemo = '/design-system/toolbar';
  
  /// 아토믹 컴포넌트들 데모
  static const String atomsDemo = '/design-system/atoms';
  
  /// Figma 노트 에디터 페이지 재현
  static const String noteEditorDemo = '/design-system/note-editor';

  // ================== Route Names ==================
  static const String designSystemName = 'designSystem';
  static const String toolbarDemoName = 'toolbarDemo';
  static const String atomsDemoName = 'atomsDemo';
  static const String noteEditorDemoName = 'noteEditorDemo';

  // ================== Helper Methods ==================
  static String designSystemRoute() => designSystem;
  static String toolbarDemoRoute() => toolbarDemo;
  static String atomsDemoRoute() => atomsDemo;
  static String noteEditorDemoRoute() => noteEditorDemo;

  // ================== GoRouter Configuration ==================
  static final List<RouteBase> routes = [
    ShellRoute(
      builder: (context, state, child) => DemoShell(child: child),
      routes: [
        GoRoute(
          path: designSystem,
          name: designSystemName,
          redirect: (context, state) => noteEditorDemo, // 기본적으로 노트 에디터로 리다이렉트
        ),
        GoRoute(
          path: noteEditorDemo,
          name: noteEditorDemoName,
          builder: (context, state) => const NoteEditorDemo(),
        ),
        GoRoute(
          path: toolbarDemo,
          name: toolbarDemoName,
          builder: (context, state) => const ToolbarDemo(),
        ),
        GoRoute(
          path: atomsDemo,
          name: atomsDemoName,
          builder: (context, state) => const AtomsDemo(),
        ),
      ],
    ),
  ];
}