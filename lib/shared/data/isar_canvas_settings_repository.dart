import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:scribble/scribble.dart';

import '../entities/canvas_settings_entity.dart';
import '../models/canvas_settings.dart';
import '../repositories/canvas_settings_repository.dart';
import '../services/isar_database_service.dart';

/// Isar-backed implementation for [CanvasSettingsRepository].
class IsarCanvasSettingsRepository implements CanvasSettingsRepository {
  IsarCanvasSettingsRepository({Isar? isar}) : _providedIsar = isar;

  final Isar? _providedIsar;
  Isar? _isar;

  Future<Isar> _ensureIsar() async {
    final cached = _isar;
    if (cached != null && cached.isOpen) {
      return cached;
    }

    final resolved = _providedIsar ?? await IsarDatabaseService.getInstance();
    _isar = resolved;
    return resolved;
  }

  @override
  Future<CanvasSettings> load() async {
    final isar = await _ensureIsar();
    final entity = await isar.canvasSettingsEntitys.get(
      CanvasSettingsEntity.singletonId,
    );
    if (entity == null) {
      return const CanvasSettings.defaults();
    }

    final pointerIndex = entity.pointerPolicyIndex;
    final pointerValues = ScribblePointerMode.values;
    final pointer = (pointerIndex >= 0 && pointerIndex < pointerValues.length)
        ? pointerValues[pointerIndex]
        : ScribblePointerMode.all;

    return CanvasSettings(
      simulatePressure: entity.simulatePressure,
      pointerPolicy: pointer,
    );
  }

  @override
  Future<void> update({
    bool? simulatePressure,
    ScribblePointerMode? pointerPolicy,
  }) async {
    if (simulatePressure == null && pointerPolicy == null) {
      return;
    }

    final isar = await _ensureIsar();
    await isar
        .writeTxn(() async {
          final collection = isar.canvasSettingsEntitys;
          final entity =
              await collection.get(CanvasSettingsEntity.singletonId) ??
              CanvasSettingsEntity();

          if (simulatePressure != null) {
            entity.simulatePressure = simulatePressure;
          }
          if (pointerPolicy != null) {
            entity.pointerPolicyIndex = pointerPolicy.index;
          }

          await collection.put(entity);
        })
        .catchError((error, stackTrace) {
          debugPrint(
            '⚠️ [CanvasSettingsRepository] Failed to update settings: $error',
          );
          throw error;
        });
  }

  @override
  void dispose() {
    _isar = null;
  }
}
