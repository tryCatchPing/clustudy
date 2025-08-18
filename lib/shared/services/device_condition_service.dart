import 'dart:async';
import 'dart:developer' as developer;

import 'package:battery_plus/battery_plus.dart';
import 'package:it_contest/shared/services/connectivity_service.dart';

/// 디바이스 상태 (배터리, 충전, 연결성) 모니터링 서비스
class DeviceConditionService {
  DeviceConditionService._();
  /// 전역에서 재사용되는 싱글톤 인스턴스. 디바이스 상태 조회/검증 및
  /// 배터리 상태 스트림 구독의 진입점으로 사용됩니다.
  static final DeviceConditionService instance = DeviceConditionService._();

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  final StreamController<BatteryState> _batteryStateController =
      StreamController<BatteryState>.broadcast();

  /// 현재 충전 중인지 확인
  Future<bool> isCharging() async {
    try {
      final batteryState = await _battery.batteryState;
      return batteryState == BatteryState.charging;
    } on Exception catch (e) {
      developer.log('Error checking charging state', name: 'DeviceConditionService', error: e);
      return false;
    }
  }

  /// 배터리 잔량 확인 (0-100)
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } on Exception catch (e) {
      developer.log('Error getting battery level', name: 'DeviceConditionService', error: e);
      return 0;
    }
  }

  /// 절전 모드 확인 (배터리 상태로 유추)
  Future<bool> isLowPowerMode() async {
    try {
      final batteryLevel = await getBatteryLevel();
      // 배터리 20% 이하일 때 절전 모드로 간주
      return batteryLevel <= 20;
    } on Exception catch (e) {
      developer.log('Error checking low power mode', name: 'DeviceConditionService', error: e);
      return false;
    }
  }

  /// 백업 실행 조건 체크 통합 메서드
  Future<bool> isBackupConditionMet({
    bool requireWifi = false,
    bool requireCharging = false,
    int minBatteryLevel = 20,
  }) async {
    try {
      // 1. WiFi 연결 조건 체크
      if (requireWifi) {
        final isWifiConnected = await ConnectivityService.instance.isWifiConnected();
        if (!isWifiConnected) {
          developer.log('WiFi not connected, backup condition not met', name: 'DeviceConditionService');
          return false;
        }
      }

      // 2. 충전 조건 체크
      if (requireCharging) {
        final isCurrentlyCharging = await isCharging();
        if (!isCurrentlyCharging) {
          developer.log('Device not charging, backup condition not met', name: 'DeviceConditionService');
          return false;
        }
      }

      // 3. 배터리 잔량 조건 체크
      final batteryLevel = await getBatteryLevel();
      if (batteryLevel < minBatteryLevel) {
        developer.log(
          'Battery level ($batteryLevel%) below minimum ($minBatteryLevel%), backup condition not met',
          name: 'DeviceConditionService',
        );
        return false;
      }

      developer.log(
        'All backup conditions met - WiFi: ${requireWifi ? 'required & connected' : 'not required'}, Charging: ${requireCharging ? 'required & charging' : 'not required'}, Battery: $batteryLevel%',
        name: 'DeviceConditionService',
      );
      return true;
    } on Exception catch (e) {
      developer.log('Error checking backup conditions', name: 'DeviceConditionService', error: e);
      return false;
    }
  }

  /// 배터리 상태 변화 스트림
  Stream<BatteryState> get batteryStateStream => _batteryStateController.stream;

  /// 배터리 상태 모니터링 시작
  void startBatteryMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen(
      (BatteryState state) {
        _batteryStateController.add(state);
        developer.log('Battery state changed to $state', name: 'DeviceConditionService');
      },
      onError: (Object e) {
        developer.log('Error monitoring battery state', name: 'DeviceConditionService', error: e);
      },
    );
  }

  /// 배터리 상태 모니터링 중지
  void stopBatteryMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
  }

  /// 디바이스 상태 정보 요약
  Future<Map<String, dynamic>> getDeviceStatusSummary() async {
    return {
      'batteryLevel': await getBatteryLevel(),
      'isCharging': await isCharging(),
      'isLowPowerMode': await isLowPowerMode(),
      'isWifiConnected': await ConnectivityService.instance.isWifiConnected(),
      'isConnected': await ConnectivityService.instance.isConnected(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 리소스 정리
  void dispose() {
    stopBatteryMonitoring();
    _batteryStateController.close();
  }
}
