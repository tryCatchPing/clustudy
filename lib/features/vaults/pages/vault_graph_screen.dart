import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  Rect? _overlayRect;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault 그래프'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: () {
              ref.invalidate(vaultGraphDataProvider(currentVaultId));
              _clearVertexOverlays();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: dataAsync.when(
        data: (data) {
          final options = Options();
          options.enableHit = true;
          options.panelDelay = const Duration(milliseconds: 200);
          options.textGetter = (vertex) {
            final t = vertex.tag;
            return t.isEmpty ? '${vertex.id}' : t;
          };
          options.backgroundBuilder = (context) => Container(
            color: const Color.fromARGB(135, 255, 255, 255),
          );
          // hover 하이라이트는 패키지 기본 동작 활용 (vertexPanelBuilder 미사용)
          options.graphStyle = (GraphStyle()
            ..tagColorByIndex = [
              Colors.redAccent.shade100,
              Colors.orangeAccent.shade100,
              Colors.yellowAccent.shade100,
              Colors.greenAccent.shade100,
              Colors.lightBlueAccent.shade100,
              Colors.blueAccent.shade100,
              Colors.purpleAccent.shade100,
              Colors.pinkAccent.shade100,
              Colors.tealAccent.shade100,
              Colors.deepOrangeAccent.shade100,
            ]
            ..hoverOpacity = 0.35);
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
