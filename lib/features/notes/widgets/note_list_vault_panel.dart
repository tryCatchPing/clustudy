import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/navigation_card.dart';
import '../../vaults/models/vault_model.dart';

class VaultListPanel extends StatelessWidget {
  const VaultListPanel({
    super.key,
    required this.vaultsAsync,
    required this.hasActiveVault,
    required this.onCreateVault,
    required this.onVaultSelected,
    required this.onShowVaultActions,
    required this.onGoToSearch,
    required this.onClearSelection,
    required this.onGoToGraph,
  });

  final AsyncValue<List<VaultModel>> vaultsAsync;
  final bool hasActiveVault;
  final VoidCallback onCreateVault;
  final ValueChanged<String> onVaultSelected;
  final ValueChanged<VaultModel> onShowVaultActions;
  final VoidCallback onGoToSearch;
  final VoidCallback onClearSelection;
  final VoidCallback onGoToGraph;

  @override
  Widget build(BuildContext context) {
    return vaultsAsync.when(
      data: (vaults) {
        if (vaults.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('아직 Vault가 없습니다.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onCreateVault,
                icon: const Icon(Icons.add),
                label: const Text('Vault 생성'),
              ),
            ],
          );
        }

        if (!hasActiveVault) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: onCreateVault,
                  icon: const Icon(Icons.add),
                  label: const Text('Vault 생성'),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  for (final v in vaults) ...[
                    GestureDetector(
                      onLongPress: () => onShowVaultActions(v),
                      child: NavigationCard(
                        icon: Icons.folder,
                        title: v.name,
                        subtitle: 'Vault',
                        color: const Color(0xFF6750A4),
                        onTap: () => onVaultSelected(v.vaultId),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onGoToSearch,
              icon: const Icon(Icons.search),
              label: const Text('노트 검색'),
            ),
            FilledButton.icon(
              onPressed: onClearSelection,
              icon: const Icon(Icons.folder_shared),
              label: const Text('Vault 선택화면 이동'),
            ),
            FilledButton.icon(
              onPressed: onGoToGraph,
              icon: const Icon(Icons.hub),
              label: const Text('그래프 보기'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
