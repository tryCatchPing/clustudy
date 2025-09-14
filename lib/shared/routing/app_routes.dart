/// 🎯 앱 전체 라우트 상수 및 네비게이션 헬퍼
///
/// 타입 안정성과 유지보수성을 위해 모든 라우트 경로를 여기서 관리합니다.
/// context.push('/some/path') 대신 AppRoutes.goToNotEdit() 같은 메서드 사용
class AppRoutes {
  // 🚫 인스턴스 생성 방지
  AppRoutes._();

  // 📍 라우트 경로 상수들
  /// 홈 화면 라우트 경로.
  static const String home = '/';

  /// 노트 목록 화면 라우트 경로.
  static const String noteList = '/notes';

  /// 노트 편집 화면 라우트 경로. `:noteId`는 동적 세그먼트입니다.
  static const String noteEdit = '/notes/:noteId/edit'; // 더 명확한 경로
  /// PDF 캔버스 화면 라우트 경로.
  static const String pdfCanvas = '/pdf-canvas';

  /// Vault 그래프 화면 라우트 경로.
  static const String vaultGraph = '/vault-graph';

  // 🎯 라우트 이름 상수들 (GoRouter name 속성용)
  /// 홈 화면 라우트 이름.
  static const String homeName = 'home';

  /// 노트 목록 화면 라우트 이름.
  static const String noteListName = 'noteList';

  /// 노트 편집 화면 라우트 이름.
  static const String noteEditName = 'noteEdit';

  /// PDF 캔버스 화면 라우트 이름.
  static const String pdfCanvasName = 'pdfCanvas';

  /// Vault 그래프 화면 라우트 이름.
  static const String vaultGraphName = 'vaultGraph';

  // 🚀 타입 안전한 네비게이션 헬퍼 메서드들

  /// 홈페이지로 이동하는 라우트 경로를 반환합니다.
  static String homeRoute() => home;

  /// 노트 목록 페이지로 이동하는 라우트 경로를 반환합니다.
  static String noteListRoute() => noteList;

  /// 특정 노트 편집 페이지로 이동하는 라우트 경로를 반환합니다.
  /// [noteId]: 편집할 노트의 ID
  static String noteEditRoute(String noteId) => '/notes/$noteId/edit';

  /// PDF 캔버스 페이지로 이동하는 라우트 경로를 반환합니다.
  static String pdfCanvasRoute() => pdfCanvas;

  /// Vault 그래프 페이지로 이동하는 라우트 경로를 반환합니다.
  static String vaultGraphRoute() => vaultGraph;

  // 📋 추후 확장성을 위한 구조 예시
  //
  // 새로운 기능 추가 시:
  // 1. 여기에 상수 추가: static const String newFeature = '/new-feature';
  // 2. 라우트 이름 추가: static const String newFeatureName = 'newFeature';
  // 3. 헬퍼 메서드 추가: static String newFeatureRoute() => newFeature;
  // 4. 각 feature의 routing 파일에서 이 상수들 사용
}
