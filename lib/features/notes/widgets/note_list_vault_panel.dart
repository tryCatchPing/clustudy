import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/components/molecules/app_card.dart';
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
                onRename: () => onRenameVault(vault),
                onDelete: canDelete ? () => onDeleteVault(vault) : null,
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
    required this.onRename,
    required this.onDelete,
  });

  final VaultModel vault;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deleteDisabled = onDelete == null;

    return SizedBox(
      width: 168,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            svgIconPath: AppIcons.folderVaultLarge,
            title: vault.name,
            date: vault.createdAt,
            onTap: onTap,
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VaultActionButton(
                iconPath: AppIcons.rename,
                tooltip: '이름 변경',
                onPressed: onRename,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.small),
              _VaultActionButton(
                iconPath: AppIcons.trash,
                tooltip: deleteDisabled ? '마지막 Vault는 삭제할 수 없습니다' : '삭제',
                onPressed: onDelete,
                color: deleteDisabled ? theme.disabledColor : AppColors.penRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultActionButton extends StatelessWidget {
  const _VaultActionButton({
    required this.iconPath,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final String iconPath;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: SvgPicture.asset(
        iconPath,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
