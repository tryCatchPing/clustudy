import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/molecules/app_card.dart';
import '../../../design_system/components/organisms/item_actions.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../vaults/models/vault_model.dart';

class VaultListPanel extends StatelessWidget {
  const VaultListPanel({
    super.key,
    required this.vaultsAsync,
    required this.onVaultSelected,
    required this.onRenameVault,
    required this.onDeleteVault,
  });

  final AsyncValue<List<VaultModel>> vaultsAsync;
  final ValueChanged<String> onVaultSelected;
  final ValueChanged<VaultModel> onRenameVault;
  final ValueChanged<VaultModel> onDeleteVault;

  @override
  Widget build(BuildContext context) {
    return vaultsAsync.when(
      data: (vaults) {
        if (vaults.isEmpty) {
          return Text(
            '아직 Vault가 없습니다.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.gray40,
            ),
          );
        }

        final canDelete = vaults.length > 1;

        return Wrap(
          spacing: AppSpacing.large,
          runSpacing: AppSpacing.large,
          children: [
            for (final vault in vaults)
              _VaultCard(
                key: ValueKey(vault.vaultId),
                vault: vault,
                onTap: () => onVaultSelected(vault.vaultId),
                onLongPressStart: (details) {
                  showItemActionsNear(
                    context,
                    anchorGlobal: details.globalPosition,
                    handlers: ItemActionHandlers(
                      onRename: () async => onRenameVault(vault),
                      onDelete: canDelete ? () async => onDeleteVault(vault) : null,
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({
    super.key,
    required this.vault,
    required this.onTap,
    this.onLongPressStart,
  });

  final VaultModel vault;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails details)? onLongPressStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      svgIconPath: AppIcons.folderVaultLarge,
      title: vault.name,
      date: vault.createdAt,
      onTap: onTap,
      onLongPressStart: onLongPressStart,
    );
  }
}
