/// 📏 앱 전체에서 사용할 간격 시스템
/// 
/// Figma 디자인 시스템을 기반으로 한 간격 토큰입니다.
/// 모든 Padding, Margin에서 하드코딩된 값 대신 이 클래스를 사용해주세요.
/// 
/// 예시:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.medium),
///   child: Text('컨텐츠'),
/// )
/// ```
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // ================== Base Spacing Scale ==================
  /// 초소형 간격 (2px) - 미세 조정용
  static const double xxs = 2.0;
  
  /// 아주 작은 간격 (4px) - 아이콘과 텍스트 사이
  static const double xs = 4.0;
  
  /// 작은 간격 (8px) - 인접한 요소 사이
  static const double small = 8.0;
  
  /// 기본 간격 (16px) - 일반적인 패딩
  static const double medium = 16.0;
  
  /// 큰 간격 (24px) - 섹션 내부 간격
  static const double large = 24.0;
  
  /// 아주 큰 간격 (32px) - 섹션 간 간격
  static const double xl = 32.0;
  
  /// 초대형 간격 (48px) - 펜대 섹션 간격
  static const double xxl = 48.0;
  
  /// 거대하게 큰 간격 (64px) - 페이지 상단/하단
  static const double xxxl = 64.0;

  // ================== Common Patterns ==================
  /// 리스트 아이템 간격
  static const double listItem = 12.0;
  
  /// 카드 내부 패딩
  static const double cardPadding = 16.0;
  
  /// 카드 간 마진
  static const double cardMargin = 8.0;
  
  /// 폼 필드 간격
  static const double formField = 16.0;
  
  /// 버튼 내부 패딩 (가로)
  static const double buttonHorizontal = 24.0;
  
  /// 버튼 내부 패딩 (세로)
  static const double buttonVertical = 12.0;
  
  /// 툴바 아이템 간격
  static const double toolbar = 8.0;
  
  /// 아이콘과 텍스트 간격
  static const double iconText = 8.0;

  // ================== Layout Spacing ==================
  /// 화면 가장자리 패딩
  static const double screenPadding = 16.0;
  
  /// 섹션 가장자리 패딩
  static const double sectionPadding = 24.0;
  
  /// 컴포넌트 간 세로 간격
  static const double componentVertical = 16.0;
  
  /// 컴포넌트 간 가로 간격
  static const double componentHorizontal = 16.0;

  // ================== Canvas Specific Spacing ==================
  /// 캔버스 툴바 패딩
  static const double canvasToolbar = 12.0;
  
  /// 캔버스 컴트롤 간격
  static const double canvasControl = 8.0;
  
  /// 페이지 네비게이션 간격
  static const double pageNavigation = 16.0;
  
  /// 그리기 도구 간격
  static const double drawingTool = 4.0;

  // ================== Note App Specific Spacing ==================
  /// 노트 카드 내부 패딩
  static const double noteCard = 16.0;
  
  /// 노트 카드 간 간격
  static const double noteCardGap = 8.0;
  
  /// 노트 리스트 패딩
  static const double noteList = 16.0;
  
  /// 검색 바 마진
  static const double searchBar = 16.0;
  
  /// 노트 제목과 미리보기 간격
  static const double noteTitlePreview = 4.0;
  
  /// 노트 메타데이터 마진
  static const double noteMeta = 8.0;
}

/// 📏 사전 정의된 EdgeInsets 패턴
class AppPadding {
  // Private constructor
  AppPadding._();
  
  // ================== All Sides ==================
  /// 모든 방향 소 패딩
  static const EdgeInsets allSmall = EdgeInsets.all(AppSpacing.small);
  
  /// 모든 방향 기본 패딩
  static const EdgeInsets allMedium = EdgeInsets.all(AppSpacing.medium);
  
  /// 모든 방향 대 패딩
  static const EdgeInsets allLarge = EdgeInsets.all(AppSpacing.large);

  // ================== Horizontal & Vertical ==================
  /// 가로 방향만 소 패딩
  static const EdgeInsets horizontalSmall = EdgeInsets.symmetric(
    horizontal: AppSpacing.small,
  );
  
  /// 가로 방향만 기본 패딩
  static const EdgeInsets horizontalMedium = EdgeInsets.symmetric(
    horizontal: AppSpacing.medium,
  );
  
  /// 가로 방향만 대 패딩
  static const EdgeInsets horizontalLarge = EdgeInsets.symmetric(
    horizontal: AppSpacing.large,
  );
  
  /// 세로 방향만 소 패딩
  static const EdgeInsets verticalSmall = EdgeInsets.symmetric(
    vertical: AppSpacing.small,
  );
  
  /// 세로 방향만 기본 패딩
  static const EdgeInsets verticalMedium = EdgeInsets.symmetric(
    vertical: AppSpacing.medium,
  );
  
  /// 세로 방향만 대 패딩
  static const EdgeInsets verticalLarge = EdgeInsets.symmetric(
    vertical: AppSpacing.large,
  );

  // ================== Screen Padding ==================
  /// 화면 전체 패딩
  static const EdgeInsets screen = EdgeInsets.all(AppSpacing.screenPadding);
  
  /// 화면 가로 패딩만
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.screenPadding,
  );
  
  /// 화면 상하 패딩만
  static const EdgeInsets screenVertical = EdgeInsets.symmetric(
    vertical: AppSpacing.screenPadding,
  );

  // ================== Component Specific ==================
  /// 버튼 패딩
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSpacing.buttonHorizontal,
    vertical: AppSpacing.buttonVertical,
  );
  
  /// 카드 패딩
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.cardPadding);
  
  /// 리스트 아이템 패딩
  static const EdgeInsets listItem = EdgeInsets.all(AppSpacing.listItem);
  
  /// 폼 필드 패딩
  static const EdgeInsets formField = EdgeInsets.all(AppSpacing.formField);
}

/// 📏 사전 정의된 SizedBox 패턴
class AppSizedBox {
  // Private constructor
  AppSizedBox._();
  
  // ================== Vertical Spacing ==================
  /// 세로 초소 간격
  static const SizedBox verticalXxs = SizedBox(height: AppSpacing.xxs);
  static const SizedBox verticalXs = SizedBox(height: AppSpacing.xs);
  static const SizedBox verticalSmall = SizedBox(height: AppSpacing.small);
  static const SizedBox verticalMedium = SizedBox(height: AppSpacing.medium);
  static const SizedBox verticalLarge = SizedBox(height: AppSpacing.large);
  static const SizedBox verticalXl = SizedBox(height: AppSpacing.xl);
  static const SizedBox verticalXxl = SizedBox(height: AppSpacing.xxl);
  
  // ================== Horizontal Spacing ==================
  /// 가로 초소 간격
  static const SizedBox horizontalXxs = SizedBox(width: AppSpacing.xxs);
  static const SizedBox horizontalXs = SizedBox(width: AppSpacing.xs);
  static const SizedBox horizontalSmall = SizedBox(width: AppSpacing.small);
  static const SizedBox horizontalMedium = SizedBox(width: AppSpacing.medium);
  static const SizedBox horizontalLarge = SizedBox(width: AppSpacing.large);
  static const SizedBox horizontalXl = SizedBox(width: AppSpacing.xl);
  static const SizedBox horizontalXxl = SizedBox(width: AppSpacing.xxl);
}