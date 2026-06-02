import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/providers/language_provider.dart';
import '../../core/models/tadbeer_models.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/alert_store.dart';
import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../feed/feed_screen.dart';
import '../input/input_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

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
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: TColors.primary,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                style: context.tHeading3.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                  fontSize: 18,
                ),
                children: [
                  const TextSpan(
                    text: 'Tadbeer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      color: TColors.coral,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.transparent,
                child: Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 66,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.tSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.tBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.rss_feed_rounded, 'Feed'.tr(context)),
              _buildNavItem(1, Icons.add_circle_outline_rounded, 'Input'.tr(context)),
              _buildNavItem(2, Icons.notifications_rounded, 'Alerts'.tr(context),
                  badgeCount: totalBadge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    final activeColor = TColors.primary;
    final inactiveColor = context.tTextSecondary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _currentIndex = index);
          if (index == 2) _refreshBadgeCounts();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? TColors.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 20,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: TColors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
