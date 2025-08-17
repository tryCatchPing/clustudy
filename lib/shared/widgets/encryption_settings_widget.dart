import 'package:flutter/material.dart';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/shared/services/encryption_manager.dart';

/// 암호화 설정을 관리하는 위젯
class EncryptionSettingsWidget extends StatefulWidget {
  const EncryptionSettingsWidget({super.key});

  @override
  State<EncryptionSettingsWidget> createState() => _EncryptionSettingsWidgetState();
}

class _EncryptionSettingsWidgetState extends State<EncryptionSettingsWidget> {
  final EncryptionManager _encryptionManager = EncryptionManager.instance;
  bool _isLoading = false;
  bool? _currentEncryptionStatus;
  List<BackupKeyInfo> _backupKeys = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    setState(() => _isLoading = true);

    try {
      // EncryptionManager에 public 메서드가 없으므로 직접 DB에서 읽기
      final isarDb = IsarDb.instance;
      final isar = await isarDb.open();
      final settings = await isar.collection<SettingsEntity>().where().filter().findFirst();
      final backupKeys = await _encryptionManager.getBackupKeysInfo();

      setState(() {
        _currentEncryptionStatus = settings?.encryptionEnabled ?? false;
        _backupKeys = backupKeys;
      });
    } on Exception catch (e) {
      _showErrorDialog('설정 로드 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEncryption(bool enable) async {
    final confirmed = await _showConfirmationDialog(
      title: enable ? '암호화 활성화' : '암호화 비활성화',
      message: enable
          ? '데이터베이스를 암호화합니다. 이 작업은 시간이 걸릴 수 있습니다.'
          : '데이터베이스 암호화를 해제합니다. 이 작업은 되돌릴 수 없습니다.',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final result = await _encryptionManager.toggleEncryption(enable: enable);

      if (result.success) {
        await _loadCurrentStatus();
        _showSuccessDialog(enable ? '암호화가 활성화되었습니다.' : '암호화가 비활성화되었습니다.');
      } else {
        _showErrorDialog('암호화 토글 실패: ${result.error}');
      }
    } on Exception catch (e) {
      _showErrorDialog('암호화 토글 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rotateKey() async {
    final confirmed = await _showConfirmationDialog(
      title: '암호화 키 회전',
      message: '새로운 암호화 키를 생성하고 데이터베이스를 재암호화합니다. 이 작업은 시간이 걸릴 수 있습니다.',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final result = await _encryptionManager.rotateEncryptionKey();

      if (result.success) {
        await _loadCurrentStatus();
        _showSuccessDialog('암호화 키가 성공적으로 회전되었습니다.');
      } else {
        _showErrorDialog('키 회전 실패: ${result.error}');
      }
    } on Exception catch (e) {
      _showErrorDialog('키 회전 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recoverFromBackup(String backupAlias) async {
    final confirmed = await _showConfirmationDialog(
      title: '백업에서 복구',
      message: '선택한 백업 키로 데이터베이스를 복구합니다. 현재 데이터가 손실될 수 있습니다.',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final result = await _encryptionManager.recoverFromBackup(backupAlias);

      if (result.success) {
        await _loadCurrentStatus();
        _showSuccessDialog('백업에서 성공적으로 복구되었습니다.');
      } else {
        _showErrorDialog('복구 실패: ${result.error}');
      }
    } on Exception catch (e) {
      _showErrorDialog('복구 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '데이터베이스 암호화',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // 암호화 상태 표시
              _buildEncryptionStatus(),
              const SizedBox(height: 16),

              // 암호화 토글 버튼
              _buildEncryptionToggle(),
              const SizedBox(height: 16),

              // 키 회전 버튼 (암호화 활성화 시에만 표시)
              if (_currentEncryptionStatus == true) ...[
                _buildKeyRotationButton(),
                const SizedBox(height: 16),
              ],

              // 백업 키 목록
              _buildBackupKeysList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptionStatus() {
    final status = _currentEncryptionStatus;
    final color = status == true ? Colors.green : Colors.orange;
    final icon = status == true ? Icons.lock : Icons.lock_open;
    final text = status == true ? '암호화 활성화됨' : '암호화 비활성화됨';

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEncryptionToggle() {
    final isEncrypted = _currentEncryptionStatus == true;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _toggleEncryption(!isEncrypted),
            icon: Icon(isEncrypted ? Icons.lock_open : Icons.lock),
            label: Text(isEncrypted ? '암호화 비활성화' : '암호화 활성화'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEncrypted ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyRotationButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _rotateKey,
            icon: const Icon(Icons.refresh),
            label: const Text('암호화 키 회전'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupKeysList() {
    if (_backupKeys.isEmpty) {
      return const Text('백업 키가 없습니다.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '백업 키 (${_backupKeys.length}개)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...(_backupKeys.take(5).map((backup) => _buildBackupKeyItem(backup))),
        if (_backupKeys.length > 5) Text('... 및 ${_backupKeys.length - 5}개 더'),
      ],
    );
  }

  Widget _buildBackupKeyItem(BackupKeyInfo backup) {
    final dateStr = backup.timestamp != null
        ? '${backup.timestamp!.month}/${backup.timestamp!.day} ${backup.timestamp!.hour}:${backup.timestamp!.minute.toString().padLeft(2, '0')}'
        : '알 수 없음';

    return ListTile(
      dense: true,
      leading: Icon(
        backup.isValid ? Icons.key : Icons.error,
        color: backup.isValid ? Colors.green : Colors.red,
      ),
      title: Text('백업 키 - $dateStr'),
      subtitle: Text(
        backup.isValid ? '유효 (${backup.keyLength} bytes)' : '손상됨',
      ),
      trailing: backup.isValid
          ? IconButton(
              onPressed: () => _recoverFromBackup(backup.alias),
              icon: const Icon(Icons.restore),
            )
          : null,
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('성공'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
