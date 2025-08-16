# 작업자 E - 운영 자동화 API 문서

## 📋 완료된 작업 목록

### 1. MaintenanceJobs 확장 (`lib/shared/services/maintenance_jobs.dart`)

#### 새로 추가된 메서드

##### `cleanupRecentTabs()`
```dart
Future<int> cleanupRecentTabs()
```
- **기능**: RecentTabs 정리 (깨진 noteId 제거, LRU 10 유지, 중복 제거)
- **반환값**: 정리 작업 수행 여부 (1: 수행됨, 0: 수행 안됨)
- **사용법**:
```dart
final cleaned = await MaintenanceJobs.instance.cleanupRecentTabs();
```

##### `schedulePeriodicMaintenance()`
```dart
Future<void> schedulePeriodicMaintenance({Duration interval = const Duration(hours: 6)})
```
- **기능**: 주기적 유지보수 작업 스케줄링 (기본 6시간마다)
- **매개변수**: `interval` - 실행 간격 (기본값: 6시간)
- **사용법**:
```dart
await MaintenanceJobs.instance.schedulePeriodicMaintenance();
// 또는 사용자 정의 간격
await MaintenanceJobs.instance.schedulePeriodicMaintenance(
  interval: Duration(hours: 12)
);
```

##### `runDailyMaintenance()`
```dart
Future<Map<String, int>> runDailyMaintenance()
```
- **기능**: 일일 통합 유지보수 (RecentTabs + 휴지통 + 스냅샷)
- **반환값**: 각 작업별 처리 개수
```dart
{
  'recentTabs': 1,      // RecentTabs 정리 수행됨
  'recycleBin': 25,     // 휴지통에서 25개 항목 삭제
  'snapshots': 120      // 120개 스냅샷 정리
}
```

##### `stopPeriodicMaintenance()`
```dart
void stopPeriodicMaintenance()
```
- **기능**: 주기적 유지보수 스케줄러 중지

### 2. ConnectivityService (`lib/shared/services/connectivity_service.dart`)

#### 주요 메서드

##### `isWifiConnected()`
```dart
Future<bool> isWifiConnected()
```
- **기능**: WiFi 연결 상태 확인
- **반환값**: WiFi 연결 여부

##### `isMeteredConnection()`
```dart
Future<bool> isMeteredConnection()
```
- **기능**: 데이터 요금제 연결 확인 (모바일 데이터)
- **반환값**: 모바일 데이터 연결 여부

##### `isConnected()`
```dart
Future<bool> isConnected()
```
- **기능**: 인터넷 연결 여부 확인 (WiFi 또는 모바일)
- **반환값**: 인터넷 연결 여부

##### 연결 상태 모니터링
```dart
Stream<ConnectivityResult> get connectivityStream
void startMonitoring()
void stopMonitoring()
```
- **사용법**:
```dart
// 모니터링 시작
ConnectivityService.instance.startMonitoring();

// 연결 상태 변화 감지
ConnectivityService.instance.connectivityStream.listen((result) {
  switch (result) {
    case ConnectivityResult.wifi:
      print('WiFi 연결됨');
      break;
    case ConnectivityResult.mobile:
      print('모바일 데이터 연결됨');
      break;
    case ConnectivityResult.none:
      print('연결 없음');
      break;
  }
});
```

### 3. DeviceConditionService (`lib/shared/services/device_condition_service.dart`)

#### 주요 메서드

##### `isCharging()`
```dart
Future<bool> isCharging()
```
- **기능**: 현재 충전 중인지 확인
- **반환값**: 충전 중 여부

##### `getBatteryLevel()`
```dart
Future<int> getBatteryLevel()
```
- **기능**: 배터리 잔량 확인
- **반환값**: 배터리 잔량 (0-100)

##### `isLowPowerMode()`
```dart
Future<bool> isLowPowerMode()
```
- **기능**: 절전 모드 확인 (배터리 20% 이하 시)
- **반환값**: 절전 모드 여부

##### `isBackupConditionMet()` (핵심 메서드)
```dart
Future<bool> isBackupConditionMet({
  bool requireWifi = false,
  bool requireCharging = false,
  int minBatteryLevel = 20,
})
```
- **기능**: 백업 실행 조건 통합 체크
- **매개변수**:
  - `requireWifi`: WiFi 연결 필수 여부
  - `requireCharging`: 충전 중 필수 여부
  - `minBatteryLevel`: 최소 배터리 잔량 (기본 20%)
- **사용 예시**:
```dart
// WiFi와 충전이 모두 필요한 경우
final canBackup = await DeviceConditionService.instance.isBackupConditionMet(
  requireWifi: true,
  requireCharging: true,
  minBatteryLevel: 30,
);

if (canBackup) {
  // 백업 실행
}
```

##### `getDeviceStatusSummary()`
```dart
Future<Map<String, dynamic>> getDeviceStatusSummary()
```
- **기능**: 디바이스 상태 정보 요약
- **반환값**: 전체 디바이스 상태 정보

### 4. BackupService 연동 수정

#### 수정된 `runIfDue()` 메서드
- **변경사항**: 디바이스 조건 체크 로직 통합
- **새로운 동작**:
  1. 백업 일정 확인
  2. **디바이스 조건 체크** (새로 추가)
     - WiFi 연결 상태 (설정에 따라)
     - 충전 상태 (설정에 따라)
     - 배터리 잔량 (최소 20%)
  3. 조건 충족 시에만 백업 실행

## 🔧 설정 연동

BackupService는 `SettingsEntity`의 다음 필드들을 참조합니다:

```dart
// 백업 관련 설정
bool? backupRequireWifi;      // WiFi 연결 필수 여부
bool? backupOnlyWhenCharging; // 충전 중에만 백업 여부
String backupDailyAt;         // 일일 백업 시간 (HH:MM)
int backupRetentionDays;      // 백업 보존 기간
DateTime? lastBackupAt;       // 마지막 백업 시간
```

## 📦 추가된 의존성

`pubspec.yaml`에 다음 패키지들이 추가되었습니다:

```yaml
dependencies:
  connectivity_plus: ^4.0.2  # 네트워크 연결 상태 확인
  battery_plus: ^4.0.2       # 배터리 및 충전 상태 확인
```

## 🚀 사용 예시

### 완전한 백업 시스템 설정

```dart
// 1. 서비스 초기화 및 모니터링 시작
void initializeServices() {
  ConnectivityService.instance.startMonitoring();
  DeviceConditionService.instance.startBatteryMonitoring();
  MaintenanceJobs.instance.schedulePeriodicMaintenance();
  BackupService.instance.startScheduler();
}

// 2. 수동 백업 전 조건 확인
Future<void> performManualBackup() async {
  final canBackup = await DeviceConditionService.instance.isBackupConditionMet(
    requireWifi: true,
    requireCharging: false,
    minBatteryLevel: 30,
  );

  if (canBackup) {
    await BackupService.instance.performBackup(retentionDays: 7);
  } else {
    // 사용자에게 조건 불충족 알림
  }
}

// 3. 일일 유지보수 수동 실행
Future<void> runMaintenance() async {
  final results = await MaintenanceJobs.instance.runDailyMaintenance();
  print('유지보수 완료: $results');
}
```

## ⚠️ 주의사항

1. **플랫폼 호환성**: iOS/Android/Desktop 모두 지원
2. **권한**: 배터리 정보 접근 권한이 필요할 수 있음
3. **백그라운드 실행**: 앱이 백그라운드에 있어도 동작
4. **리소스 정리**: 앱 종료 시 `dispose()` 메서드 호출 권장

```dart
// 앱 종료 시
@override
void dispose() {
  ConnectivityService.instance.dispose();
  DeviceConditionService.instance.dispose();
  MaintenanceJobs.instance.stopPeriodicMaintenance();
  BackupService.instance.stopScheduler();
  super.dispose();
}
```

## ✅ 작업 완료 기준 달성

- ✅ RecentTabs 자동 정리 스케줄러
- ✅ WiFi/충전 상태 실시간 모니터링
- ✅ 백업 서비스와 연동된 조건부 실행
- ✅ 일일/주기적 유지보수 자동화
