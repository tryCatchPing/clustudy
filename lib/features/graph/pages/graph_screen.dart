// features/graph/pages/graph_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design_system/components/molecules/app_card.dart';
import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../notes/state/note_store.dart';
import '../../vaults/state/vault_store.dart';

class GraphScreen extends StatelessWidget {
  final String vaultId;
  const GraphScreen({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopToolbar(variant: TopToolbarVariant.folder, title: '그래프뷰'),
      body: Center(child: Text('Graph for vault: $vaultId')),
    );
  }
}
