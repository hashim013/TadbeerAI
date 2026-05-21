import 'package:flutter/foundation.dart';

import '../services/alert_store.dart';

/// Bridges AlertStore to Provider tree for reactive badge updates.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    AlertStore.instance.addListener(_onStoreChanged);
  }

  AlertStore get store => AlertStore.instance;

  int get executionUnread => store.executionUnreadCount;

  void _onStoreChanged() => notifyListeners();

  @override
  void dispose() {
    AlertStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void refresh() => notifyListeners();
}
