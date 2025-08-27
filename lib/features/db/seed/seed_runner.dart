import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:uuid/uuid.dart';


/// 초기 데이터(시드)를 보장하는 러너입니다.
class SeedRunner {
  /// 내부 생성자.
  SeedRunner._();
  /// 싱글턴 인스턴스.
  static final SeedRunner instance = SeedRunner._();

  /// 앱 최초 실행 시 필요한 기본 Vault/Folder/Note/Page를 생성합니다.
  Future<void> ensureInitialSeed() async {
    final isar = await IsarDb.instance.open();
    final hasVault = await isar.collection<Vault>().where().count() > 0;
    if (hasVault) {
      return;
    }
    await isar.writeTxn(() async {
      final now = DateTime.now();
      final vault = Vault()
        ..name = 'Default'
        ..nameLowerUnique = 'default'
        ..createdAt = now
        ..updatedAt = now;
      final vaultId = await isar.collection<Vault>().put(vault);
      final folder = Folder()
        ..vaultId = vaultId
        ..name = 'General'
        ..nameLowerForVaultUnique = 'general'
        ..sortIndex = 1000
        ..createdAt = now
        ..updatedAt = now;
      final folderId = await isar.collection<Folder>().put(folder);
      final note = NoteModel.create(
        noteId: const Uuid().v4(),
        title: 'Welcome',
        vaultId: vaultId,
        folderId: folderId,
        sortIndex: 1000,
        createdAt: now,
        updatedAt: now,
      );
      await isar.collection<NoteModel>().put(note);
      final page = Page()
        ..noteId = note.noteId
        ..index = 0
        ..widthPx = 2480
        ..heightPx = 3508
        ..rotationDeg = 0
        ..createdAt = now
        ..updatedAt = now;
      await isar.collection<Page>().put(page);
    });
  }
}
