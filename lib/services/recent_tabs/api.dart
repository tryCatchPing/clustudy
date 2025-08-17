import 'package:it_contest/services/recent_tabs/recent_tabs_service.dart';

// Frozen interface: Do not change signatures without contract update.
Future<void> recentTabsFixBrokenIds() {
  return RecentTabsService.instance.recentTabsFixBrokenIds();
}
