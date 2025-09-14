import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vaults/data/derived_vault_providers.dart';
import '../data/vault_graph_providers.dart';

/// Vault 그래프 뷰 화면
class VaultGraphScreen extends ConsumerWidget {
  const VaultGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ]);

          return FlutterGraphWidget(
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
