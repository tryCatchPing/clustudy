import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// WiFi 연결 상태 모니터링 서비스
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();

  /// 현재 WiFi 연결 상태 확인
  Future<bool> isWifiConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.wifi;
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error checking WiFi connection', name: 'ConnectivityService', error: e, stackTrace: stack);
      }
      return false;
    }
  }

  /// 데이터 요금제 연결 확인 (모바일 데이터)
  Future<bool> isMeteredConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile;
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error checking mobile connection', name: 'ConnectivityService', error: e, stackTrace: stack);
      }
      return false;
    }
  }

  /// 인터넷 연결 여부 확인 (WiFi 또는 모바일)
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } on Exception catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error checking connection', name: 'ConnectivityService', error: e, stackTrace: stack);
      }
      return false;
    }
  }

  /// 연결 상태 변화 스트림
  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;

  /// 연결 상태 모니터링 시작
  void startMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _connectivityController.add(result);
        if (kDebugMode) {
          developer.log('Connection changed to $result', name: 'ConnectivityService');
        }
      },
      onError: (Object e, StackTrace stack) {
        if (kDebugMode) {
          developer.log('Error monitoring connectivity', name: 'ConnectivityService', error: e, stackTrace: stack);
        }
        _connectivityController.add(ConnectivityResult.none);
      },
    );
  }

  /// 연결 상태 모니터링 중지
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// 리소스 정리
  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}
