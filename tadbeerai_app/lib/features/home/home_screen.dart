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
import '../tax/tax_desk_screen.dart';

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
    if (index == 3) _refreshBadgeCounts();
  }

  final List<Widget> _screens = [
    const FeedScreen(),
    const TaxDeskScreen(),
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
        elevation: 0,
        backgroundColor: context.tSurface,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: context.tBorder, width: 0.5)),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.tBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                  TextSpan(
                    text: 'Tadbeer',
                    style: TextStyle(
                      color: context.tTextPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      color: TColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
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
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.tBorder, width: 1),
                color: context.tSurfaceAlt,
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: TColors.primaryLight,
                child: Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: TColors.primaryDark,
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
              _buildNavItem(0, Icons.rss_feed_rounded, 'Feed'),
              _buildNavItem(1, Icons.account_balance_rounded, 'Tax Desk'),
              _buildNavItem(2, Icons.add_circle_outline_rounded, 'Input'),
              _buildNavItem(3, Icons.notifications_rounded, 'Alerts',
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
          if (index == 3) _refreshBadgeCounts();
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
