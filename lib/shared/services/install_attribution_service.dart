import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_service_providers.dart';

const MethodChannel _installReferrerChannel = MethodChannel(
  'com.trycatchping.clustudy/install_referrer',
);

/// Provides access to the install attribution payload captured at bootstrap.
final installAttributionBootstrapProvider =
    Provider<InstallAttributionPayload?>((_) => null);

/// Wires up the [InstallAttributionService] for dependency injection.
final installAttributionServiceProvider = Provider<InstallAttributionService>((
  ref,
) {
  final logger = ref.watch(firebaseAnalyticsLoggerProvider);
  return InstallAttributionService(analyticsLogger: logger);
});

/// Immutable representation of the Google Play install referrer payload.
class InstallAttributionPayload {
  InstallAttributionPayload({
    required this.rawReferrer,
    required this.parameters,
    this.referrerClickTimestamp,
    this.installBeginTimestamp,
    this.isInstantExperience = false,
  });

  final String rawReferrer;
  final Map<String, String> parameters;
  final DateTime? referrerClickTimestamp;
  final DateTime? installBeginTimestamp;
  final bool isInstantExperience;

  String? get source => parameters['utm_source'] ?? parameters['source'];
  String? get medium => parameters['utm_medium'] ?? parameters['medium'];
  String? get campaign => parameters['utm_campaign'] ?? parameters['campaign'];
  String? get content => parameters['utm_content'] ?? parameters['content'];

  Map<String, String> asAnalyticsParameters() {
    final payload = <String, String>{};
    payload.addAll(parameters);

    if (referrerClickTimestamp != null) {
      payload['referrer_click_ts'] = referrerClickTimestamp!
          .millisecondsSinceEpoch
          .toString();
    }

    if (installBeginTimestamp != null) {
      payload['install_begin_ts'] = installBeginTimestamp!
          .millisecondsSinceEpoch
          .toString();
    }

    if (isInstantExperience) {
      payload['google_play_instant'] = '1';
    }

    return payload;
  }
}

/// Handles retrieval and logging of Google Play install attribution data.
class InstallAttributionService {
  InstallAttributionService({
    FirebaseAnalyticsLogger? analyticsLogger,
    MethodChannel? methodChannel,
  }) : _analyticsLogger = analyticsLogger,
       _methodChannel = methodChannel ?? _installReferrerChannel;

  final FirebaseAnalyticsLogger? _analyticsLogger;
  final MethodChannel _methodChannel;
  Future<InstallAttributionPayload?>? _pendingRequest;

  Future<InstallAttributionPayload?> bootstrap() {
    return _pendingRequest ??= _loadAndRecord();
  }

  Future<InstallAttributionPayload?> _loadAndRecord() async {
    if (!_isAndroid) {
      return null;
    }

    try {
      final response = await _methodChannel.invokeMapMethod<String, dynamic>(
        'getInstallReferrer',
      );
      final payload = _parseResponse(response);
      if (payload == null) {
        return null;
      }

      await _analyticsLogger?.logInstallAttribution(
        payload.asAnalyticsParameters(),
      );

      return payload;
    } on MissingPluginException catch (error) {
      debugPrint('Install attribution unavailable: $error');
      return null;
    } on PlatformException catch (error) {
      debugPrint('Install attribution failed: ${error.message}');
      return null;
    } catch (error) {
      debugPrint('Unexpected install attribution error: $error');
      return null;
    }
  }

  InstallAttributionPayload? _parseResponse(
    Map<String, dynamic>? response,
  ) {
    final rawReferrer = response?['installReferrer'] as String?;
    if (rawReferrer == null || rawReferrer.trim().isEmpty) {
      return null;
    }

    final parameters = _extractParameters(rawReferrer);
    if (parameters.isEmpty) {
      return null;
    }

    final clickSeconds = response?['referrerClickTimestampSeconds'];
    final installSeconds = response?['installBeginTimestampSeconds'];
    final instant = response?['googlePlayInstantParam'];

    return InstallAttributionPayload(
      rawReferrer: rawReferrer,
      parameters: parameters,
      referrerClickTimestamp: _timestampFromSeconds(clickSeconds),
      installBeginTimestamp: _timestampFromSeconds(installSeconds),
      isInstantExperience: _parseBool(instant),
    );
  }

  @visibleForTesting
  Map<String, String> extractParametersForTest(String rawReferrer) {
    return _extractParameters(rawReferrer);
  }

  @visibleForTesting
  InstallAttributionPayload? parseResponseForTest(
    Map<String, dynamic>? response,
  ) {
    return _parseResponse(response);
  }

  Map<String, String> _extractParameters(String rawReferrer) {
    var normalized = rawReferrer.trim();
    if (normalized.isEmpty) {
      return const <String, String>{};
    }

    try {
      normalized = Uri.decodeFull(normalized);
    } catch (_) {
      try {
        normalized = Uri.decodeComponent(normalized);
      } catch (_) {
        // Ignore decoding errors and use the raw value.
      }
    }

    if (normalized.startsWith('?')) {
      normalized = normalized.substring(1);
    }

    if (!normalized.contains('=')) {
      return const <String, String>{};
    }

    try {
      final query = Uri.splitQueryString(normalized);
      return Map<String, String>.fromEntries(
        query.entries.where(
          (entry) => entry.key.isNotEmpty && entry.value.isNotEmpty,
        ),
      );
    } catch (_) {
      final segments = normalized.split('&');
      final result = <String, String>{};

      for (final segment in segments) {
        final parts = segment.split('=');
        if (parts.length == 2) {
          final key = parts[0];
          final value = parts[1];
          if (key.isNotEmpty && value.isNotEmpty) {
            result[key] = value;
          }
        }
      }

      return result;
    }
  }

  DateTime? _timestampFromSeconds(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).round(),
        isUtc: true,
      );
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true);
      }
    }
    return null;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  bool get _isAndroid {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }
}
