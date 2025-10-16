import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../shared/routing/app_routes.dart';
import '../../vaults/data/derived_vault_providers.dart';
import '../data/vault_graph_providers.dart';

/// 드래그 히트율 향상을 위한 최소 반지름 보정 데코레이터
class MinRadiusVertexDecorator extends VertexDecorator {
  final double min;
  MinRadiusVertexDecorator({this.min = 14});
  @override
  void decorate(Vertex<dynamic> vertex, ui.Canvas canvas, paint, paintLayers) {
    if (vertex.radius < min) {
      vertex.radius = min;
    }
  }
}

/// Vault 그래프 뷰 화면
class VaultGraphScreen extends ConsumerStatefulWidget {
  const VaultGraphScreen({super.key});

  @override
  ConsumerState<VaultGraphScreen> createState() => _VaultGraphScreenState();
}

class _VaultGraphScreenState extends ConsumerState<VaultGraphScreen> {
  final GlobalKey _graphKey = GlobalKey(debugLabel: 'graphWidgetKey');
  // Rect? _overlayRect;

  void _clearVertexOverlays() {
    final state = _graphKey.currentState;
    if (state == null) return;
    try {
      final game = (state as dynamic).graphCpn as GraphComponent?;
      if (game == null) return;
      final actives = game.overlays.activeOverlays
          .where((name) => name.startsWith('vertex'))
          .toList();
      for (final name in actives) {
        game.overlays.remove(name);
      }
      game.graph.hoverVertex = null;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final currentVaultId = ref.watch(currentVaultProvider);

    if (currentVaultId == null) {
      return const Scaffold(
        body: Center(child: Text('선택된 Vault가 없습니다.')),
      );
    }

    final dataAsync = ref.watch(vaultGraphDataProvider(currentVaultId));
    final vaultAsync = ref.watch(vaultByIdProvider(currentVaultId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: vaultAsync.maybeWhen(
          data: (vault) => vault?.name ?? 'Vault 그래프',
          orElse: () => 'Vault 그래프',
        ),
        onBack: () => context.pop(),
        backSvgPath: AppIcons.chevronLeft,
        actions: const [
          // TODO: SVG refresh 아이콘 추가 시 교체 필요
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.invalidate(vaultGraphDataProvider(currentVaultId));
          _clearVertexOverlays();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        tooltip: '새로고침',
        child: const Icon(Icons.refresh),
      ),
      body: dataAsync.when(
        data: (data) {
          final options = Options();
          options.enableHit = true;
          options.panelDelay = const Duration(milliseconds: 200);

          // edgePanelBuilder가 null이면 패키지가 오버레이를 등록하지 않아 assertion이 발생하므로
          // 빈 빌더를 명시해 오버레이 등록만 수행하고 아무것도 그리지 않도록 한다.
          options.edgePanelBuilder = (_, __) => const SizedBox.shrink();

          options.textGetter = (vertex) {
            final t = vertex.tag;
            return t.isEmpty ? '${vertex.id}' : t;
          };
          options.legendTextBuilder = (tag, i, color, position) {
            return TextComponent(
              text: tag,
              position: Vector2(position.x + 40, position.y - 2),
              textRenderer: TextPaint(
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
              ),
            );
          };

          options.backgroundBuilder = (context) => Container(
            color: AppColors.background,
          );

          // hover 하이라이트는 패키지 기본 동작 활용 (vertexPanelBuilder 미사용)
          // 노드 색상: 기본은 회색 팔레트로 통일
          options.graphStyle = (GraphStyle()
            ..defaultColor = (() => [AppColors.primary])
            ..tagColorByIndex = [
              AppColors.primary.withValues(alpha: 0.85),
              AppColors.primary.withValues(alpha: 0.7),
              AppColors.primary.withValues(alpha: 0.6),
            ]
            ..hoverOpacity = 0.3);
          // 노드 히트율 개선: 최소 반지름 보정
          options.vertexShape = VertexCircleShape(
            decorators: [MinRadiusVertexDecorator(min: 14)],
          );
          // 노드 탭: 즉시 해당 노트로 이동
          options.onVertexTapUp = (vertex, event) {
            final ctx = vertex.cpn?.context;
            if (ctx != null) {
              GoRouter.of(ctx).pushNamed(
                AppRoutes.noteEditName,
                pathParameters: {'noteId': vertex.id.toString()},
              );
            }
            return null;
          };
          // 탭다운/취소 핸들러 제거: 기본 제스처 동작에 맡김

          // 배경 탭으로 선택 해제: GameWidget 위에 GestureDetector를 덮으면 제스처 충돌이 발생하므로,
          // 수평/수직 컨트롤 오버레이 토글을 이용해 간접적으로 배경 탭을 유도하는 대신,
          // 새로고침 버튼 탭 시 해제하도록 유지. 필요 시, 그래프 외부 AppBar leading/back 탭에서도 해제.

          return FlutterGraphWidget(
            key: _graphKey,
            data: data,
            algorithm: ForceDirected(),
            convertor: MapConvertor(),
            options: options,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('그래프 로딩 오류: $e')),
      ),
    );
  }
}
