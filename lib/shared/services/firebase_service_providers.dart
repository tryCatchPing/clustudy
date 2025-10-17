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
