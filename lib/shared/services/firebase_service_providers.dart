import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton [FirebaseAnalytics] instance once Firebase is ready.
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Provides the singleton [FirebaseCrashlytics] instance once Firebase is ready.
final firebaseCrashlyticsProvider = Provider<FirebaseCrashlytics>((ref) {
  return FirebaseCrashlytics.instance;
});

/// Provides a shared [FirebaseAnalyticsObserver] for router screen tracking.
final firebaseAnalyticsObserverProvider =
    Provider<FirebaseAnalyticsObserver>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return FirebaseAnalyticsObserver(analytics: analytics);
});

/// Simple facade wrapping analytics event calls used across features.
class FirebaseAnalyticsLogger {
  FirebaseAnalyticsLogger(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logAppLaunch() => _analytics.logEvent(name: 'app_launch');

  Future<void> logVaultOpen({required String vaultId}) {
    return _analytics.logEvent(
      name: 'vault_open',
      parameters: {'vault_id': vaultId},
    );
  }

  Future<void> logFolderOpen({
    required String folderId,
    required bool isRoot,
  }) {
    return _analytics.logEvent(
      name: 'folder_open',
      parameters: {
        'folder_id': folderId,
        'is_root': isRoot ? 1 : 0,
      },
    );
  }

  Future<void> logNoteOpen({
    required String noteId,
    required String source,
  }) {
    return _analytics.logEvent(
      name: 'note_open',
      parameters: {'note_id': noteId, 'source': source},
    );
  }

  Future<void> logNoteCreated({
    required String noteId,
    required String source,
  }) {
    return _analytics.logEvent(
      name: 'note_created',
      parameters: {'note_id': noteId, 'source': source},
    );
  }

  Future<void> logNoteDeleted({
    required String noteId,
    int? pageCount,
  }) {
    return _analytics.logEvent(
      name: 'note_deleted',
      parameters: {
        'note_id': noteId,
        if (pageCount != null) 'page_count': pageCount,
      },
    );
  }

  Future<void> logPageAdded({
    required String noteId,
    required int pageNumber,
  }) {
    return _analytics.logEvent(
      name: 'note_page_added',
      parameters: {'note_id': noteId, 'page_number': pageNumber},
    );
  }

  Future<void> logCanvasFirstDraw({
    required String noteId,
    required String pageId,
  }) {
    return _analytics.logEvent(
      name: 'canvas_first_draw',
      parameters: {'note_id': noteId, 'page_id': pageId},
    );
  }

  Future<void> logLinkDrawn({
    required String sourceNoteId,
    required String sourcePageId,
    String? targetNoteId,
  }) {
    return _analytics.logEvent(
      name: 'link_drawn',
      parameters: {
        'source_note_id': sourceNoteId,
        'source_page_id': sourcePageId,
        if (targetNoteId != null) 'target_note_id': targetNoteId,
      },
    );
  }

  Future<void> logLinkConfirmed({
    required String linkId,
    required String sourceNoteId,
    required String targetNoteId,
  }) {
    return _analytics.logEvent(
      name: 'link_confirmed',
      parameters: {
        'link_id': linkId,
        'source_note_id': sourceNoteId,
        'target_note_id': targetNoteId,
      },
    );
  }

  Future<void> logLinkFollow({
    required String entry,
    required String sourceNoteId,
    required String targetNoteId,
  }) {
    return _analytics.logEvent(
      name: 'link_follow',
      parameters: {
        'entry': entry,
        'source_note_id': sourceNoteId,
        'target_note_id': targetNoteId,
      },
    );
  }

  Future<void> logBacklinkPanelOpen({required String noteId}) {
    return _analytics.logEvent(
      name: 'backlink_panel_open',
      parameters: {'note_id': noteId},
    );
  }

  Future<void> logGraphViewOpen({required String vaultId}) {
    return _analytics.logEvent(
      name: 'graph_view_open',
      parameters: {'vault_id': vaultId},
    );
  }

  /// Records install attribution parameters captured during app bootstrap.
  Future<void> logInstallAttribution(Map<String, String> parameters) async {
    if (parameters.isEmpty) {
      return;
    }

    await _analytics.logEvent(
      name: 'install_attribution',
      parameters: parameters,
    );

    final source = parameters['utm_source'] ?? parameters['source'];
    final medium = parameters['utm_medium'] ?? parameters['medium'];
    final campaign = parameters['utm_campaign'] ?? parameters['campaign'];

    await Future.wait([
      if (source != null && source.isNotEmpty)
        _analytics.setUserProperty(
          name: 'install_source',
          value: source,
        ),
      if (medium != null && medium.isNotEmpty)
        _analytics.setUserProperty(
          name: 'install_medium',
          value: medium,
        ),
      if (campaign != null && campaign.isNotEmpty)
        _analytics.setUserProperty(
          name: 'install_campaign',
          value: campaign,
        ),
    ]);
  }

  /// Tracks interest taps on PRO-only features shown to free users.
  Future<void> logProFeatureInterest({
    required String featureKey,
    required String featureLabel,
    required String surface,
  }) {
    return _analytics.logEvent(
      name: 'pro_feature_interest',
      parameters: {
        'feature_key': featureKey,
        'feature_label': featureLabel,
        'surface': surface,
      },
    );
  }
}

final firebaseAnalyticsLoggerProvider =
    Provider<FirebaseAnalyticsLogger>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return FirebaseAnalyticsLogger(analytics);
});
