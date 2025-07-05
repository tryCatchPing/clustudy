import 'package:flutter/material.dart';

/// 🏠 테스트용 홈페이지
///
/// 이 페이지는 앱의 시작점으로, 다른 페이지들로 이동할 수 있는
/// 네비게이션 허브 역할을 합니다.
///
/// 📱 동작 방식:
/// 1. 앱 실행 시 main.dart에서 '/' 라우트로 이 페이지가 먼저 표시됨
/// 2. 사용자가 버튼을 누르면 Navigator.pushNamed()로 다른 페이지로 이동
/// 3. 다른 페이지에서 뒤로가기를 누르면 다시 이 홈페이지로 돌아옴
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'IT Contest - Flutter App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6750A4),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎯 앱 로고/타이틀 영역
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.edit_note,
                      size: 80,
                      color: Color(0xFF6750A4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '손글씨 노트 앱',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C1B1F),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '4인 팀 프로젝트 - Flutter 데모',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 📱 페이지 네비게이션 버튼들
              Text(
                '페이지 테스트',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C1B1F),
                ),
              ),

              const SizedBox(height: 24),

              // 🎨 1. Scribble 페이지 버튼
              //
              // 💡 동작 설명:
              // - 사용자가 이 카드를 탭하면 onTap 콜백이 실행됨
              // - Navigator.pushNamed(context, '/scribble')가 호출됨
              // - main.dart의 routes에서 '/scribble' 경로를 찾음
              // - ScribblePage(title: 'Scribble Canvas') 위젯이 생성되어 화면에 표시됨
              // - 새 페이지가 현재 페이지(HomePage) 위에 스택처럼 쌓임
              _buildNavigationCard(
                context: context,
                icon: Icons.brush,
                title: 'Scribble Canvas',
                subtitle: '손글씨 그리기 기능\n(Canvas & Drawing)',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  // 🚀 네비게이션 동작:
                  // 1. '/scribble' 라우트로 이동 요청
                  // 2. main.dart에서 해당 라우트를 찾아 ScribblePage 생성
                  // 3. 새 페이지가 현재 페이지 위에 Push됨 (스택 구조)
                  // 4. 사용자에게는 새 화면이 나타나는 것처럼 보임
                  print('🎨 Scribble 페이지로 이동 중...');
                  Navigator.pushNamed(context, '/scribble');
                },
              ),

              const SizedBox(height: 16),

              _buildNavigationCard(
                context: context,
                icon: Icons.brush,
                title: 'Flutter Drawing Board Test Page',
                subtitle: 'Flutter 그림판 테스트 페이지',
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.pushNamed(context, '/flutter_drawing_board');
                },
              ),

              const SizedBox(height: 16),

              _buildNavigationCard(
                context: context,
                icon: Icons.auto_awesome,
                title: 'Flutter Painter V2 Test Page',
                subtitle:
                    '🎨 최신 그리기 기능 테스트\n• 개별 획/객체 삭제 ✓\n• 실시간 도구 변경\n• 직관적인 UI 컨트롤',
                color: const Color(0xFF673AB7),
                onTap: () {
                  Navigator.pushNamed(context, '/flutter_painter_v2');
                },
              ),

              const SizedBox(height: 16),

              _buildNavigationCard(
                context: context,
                icon: Icons.info_outline,
                title: 'Test Page',
                subtitle: '테스트 페이지',
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.pushNamed(context, '/test');
                },
              ),

              // 📊 프로젝트 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '개발 상태: Canvas 기본 기능 + UI 와이어프레임 완성',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 네비게이션 카드 위젯
  ///
  /// 이 위젯은 각 페이지로 이동하는 버튼을 만들어줍니다.
  ///
  /// 📱 매개변수 설명:
  /// - context: 현재 위젯의 BuildContext (네비게이션에 필요)
  /// - icon: 카드에 표시할 아이콘
  /// - title: 카드의 제목 텍스트
  /// - subtitle: 카드의 설명 텍스트
  /// - color: 카드의 테마 색상
  /// - onTap: 카드를 탭했을 때 실행할 함수 (VoidCallback)
  ///
  /// 🔄 동작 과정:
  /// 1. 사용자가 카드를 터치
  /// 2. GestureDetector가 터치 이벤트 감지
  /// 3. onTap 콜백 함수 실행
  /// 4. Navigator.pushNamed()를 통해 새 페이지로 이동
  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap, // 👆 이 함수가 버튼 동작을 정의함
  }) {
    return GestureDetector(
      // 🖱️ GestureDetector: 사용자의 터치/탭을 감지하는 위젯
      // onTap에 전달된 함수가 사용자가 카드를 탭했을 때 실행됩니다.
      onTap: onTap,
      child: AnimatedContainer(
        // 🎭 AnimatedContainer: 터치 시 부드러운 애니메이션 효과
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),

            const SizedBox(width: 16),

            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // 화살표 아이콘
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
