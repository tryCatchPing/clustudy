import 'package:clustudy/shared/services/install_attribution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstallAttributionService', () {
    test('extracts decoded UTM parameters from percent-encoded referrer', () {
      final service = InstallAttributionService();

      final params = service.extractParametersForTest(
        'utm_source%3Dinstagram_profile%26utm_medium%3Dsocial'
        '%26utm_campaign%3Dlaunching_event',
      );

      expect(params['utm_source'], 'instagram_profile');
      expect(params['utm_medium'], 'social');
      expect(params['utm_campaign'], 'launching_event');
    });

    test('builds payload with timestamps and analytics parameters', () {
      final service = InstallAttributionService();

      final payload = service.parseResponseForTest({
        'installReferrer':
            'utm_source=naver_blog&utm_medium=community'
            '&utm_campaign=launching_event&utm_content=banner',
        'referrerClickTimestampSeconds': 1,
        'installBeginTimestampSeconds': 2,
        'googlePlayInstantParam': true,
      });

      expect(payload, isNotNull);
      expect(payload!.source, 'naver_blog');
      expect(payload.medium, 'community');
      expect(payload.campaign, 'launching_event');
      expect(payload.content, 'banner');
      expect(
        payload.referrerClickTimestamp,
        DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      );
      expect(
        payload.installBeginTimestamp,
        DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true),
      );

      final analyticsParams = payload.asAnalyticsParameters();
      expect(analyticsParams['utm_source'], 'naver_blog');
      expect(analyticsParams['utm_medium'], 'community');
      expect(analyticsParams['utm_campaign'], 'launching_event');
      expect(analyticsParams['utm_content'], 'banner');
      expect(analyticsParams['referrer_click_ts'], '1000');
      expect(analyticsParams['install_begin_ts'], '2000');
      expect(analyticsParams['google_play_instant'], '1');
    });

    test('returns null payload when referrer is empty', () {
      final service = InstallAttributionService();

      final payload = service.parseResponseForTest({
        'installReferrer': '',
      });

      expect(payload, isNull);
    });
  });
}
