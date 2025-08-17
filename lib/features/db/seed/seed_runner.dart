import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

class SeedRunner {
  SeedRunner._();
  static final SeedRunner instance = SeedRunner._();

  Future<void> ensureInitialSeed() async {
    final isar = await IsarDb.instance.open();
    final hasVault = await isar.vaults.where().count() > 0;
    if (hasVault) return;
    await isar.writeTxn(() async {
      final now = DateTime.now();
      final vault = Vault()
        ..name = 'Default'
        ..nameLowerUnique = 'default'
        ..createdAt = now
        ..updatedAt = now;
      final vaultId = await isar.vaults.put(vault);
      final folder = Folder()
        ..vaultId = vaultId
        ..name = 'General'
        ..nameLowerForVaultUnique = 'general'
        ..sortIndex = 1000
        ..createdAt = now
        ..updatedAt = now;
      final folderId = await isar.folders.put(folder);
      final note = Note()
        ..vaultId = vaultId
        ..folderId = folderId
        ..name = 'Welcome'
        ..nameLowerForParentUnique = 'welcome'
        ..pageSize = 'A4'
        ..pageOrientation = 'portrait'
        ..sortIndex = 1000
        ..createdAt = now
        ..updatedAt = now;
      final noteId = await isar.notes.put(note);
      final page = Page()
        ..noteId = noteId
        ..index = 0
        ..widthPx = 2480
        ..heightPx = 3508
        ..rotationDeg = 0
        ..createdAt = now
        ..updatedAt = now;
      await isar.pages.put(page);
    });
  }
}
