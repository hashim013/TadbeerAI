import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/tadbeer_models.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/alert_store.dart';
import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../feed/feed_screen.dart';
import '../input/input_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _marketUnread = 0;

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 2) _refreshBadgeCounts();
  }

  final List<Widget> _screens = [
    const FeedScreen(),
    const InputScreen(),
    const NotificationsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshBadgeCounts();
  }

  Future<void> _refreshBadgeCounts() async {
    try {
      final items = await ApiService.getFeed();
      final alertIds = items
          .where((i) =>
              i.urgency == UrgencyLevel.high ||
              i.urgency == UrgencyLevel.medium)
          .map((i) => i.id);
      if (mounted) {
        setState(() {
          _marketUnread = AlertStore.instance.marketUnreadCount(alertIds);
        });
      }
    } catch (_) {}
  }

  int _totalBadge(NotificationProvider np) =>
      _marketUnread + np.executionUnread;

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    final totalBadge = _totalBadge(np);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: TColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text('TadbeerAI', style: context.tHeading3),
          ],
        ),
        actions: [
          ThemeToggleButton(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: TColors.primaryLight,
              child: Icon(Icons.person_rounded,
                  size: 20, color: TColors.primaryDark),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) _refreshBadgeCounts();
        },
        selectedItemColor: TColors.primary,
        unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed_rounded),
            label: 'Feed',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Input',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: totalBadge > 0,
              label: Text('$totalBadge'),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
