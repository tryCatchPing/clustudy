import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/atoms/app_button.dart';
import '../../../design_system/components/molecules/app_card.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
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
              Text(
                '아직 Vault가 없습니다.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gray40,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppButton.textIcon(
                text: 'Vault 생성',
                svgIconPath: AppIcons.plus,
                onPressed: onCreateVault,
                style: AppButtonStyle.primary,
                size: AppButtonSize.md,
              ),
            ],
          );
        }

        if (!hasActiveVault) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppButton.textIcon(
                text: 'Vault 생성',
                svgIconPath: AppIcons.plus,
                onPressed: onCreateVault,
                style: AppButtonStyle.primary,
                size: AppButtonSize.md,
              ),
              const SizedBox(height: AppSpacing.large),
              Wrap(
                spacing: AppSpacing.large,
                runSpacing: AppSpacing.large,
                children: [
                  for (final vault in vaults)
                    AppCard(
                      key: ValueKey(vault.vaultId),
                      svgIconPath: AppIcons.folderVaultLarge,
                      title: vault.name,
                      date: vault.createdAt,
                      onTap: () => onVaultSelected(vault.vaultId),
                      onLongPressStart: (details) => onShowVaultActions(vault),
                    ),
                ],
              ),
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            AppButton.textIcon(
              text: '노트 검색',
              svgIconPath: AppIcons.search,
              onPressed: onGoToSearch,
              style: AppButtonStyle.primary,
              size: AppButtonSize.md,
            ),
            AppButton.textIcon(
              text: 'Vault 목록으로',
              svgIconPath: AppIcons.folderVault,
              onPressed: onClearSelection,
              style: AppButtonStyle.secondary,
              size: AppButtonSize.md,
            ),
            AppButton.textIcon(
              text: '그래프 보기',
              svgIconPath: AppIcons.graphView,
              onPressed: onGoToGraph,
              style: AppButtonStyle.secondary,
              size: AppButtonSize.md,
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
