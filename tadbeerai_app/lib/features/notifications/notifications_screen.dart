import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/models/execution_notification.dart';
import '../../core/models/tadbeer_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/alert_store.dart';
import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../insight/insight_screen.dart';
import 'execution_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NewsItem> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
    AlertStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    AlertStore.instance.removeListener(_onStoreChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getFeed();
      final alerts = items
          .where((i) =>
              i.urgency == UrgencyLevel.high ||
              i.urgency == UrgencyLevel.medium)
          .toList();
      alerts.sort((a, b) {
        final urgencyOrder = {
          UrgencyLevel.high: 0,
          UrgencyLevel.medium: 1,
          UrgencyLevel.low: 2,
        };
        final cmp =
            urgencyOrder[a.urgency]!.compareTo(urgencyOrder[b.urgency]!);
        if (cmp != 0) return cmp;
        return b.publishedAt.compareTo(a.publishedAt);
      });
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _alerts = [];
        _loading = false;
      });
    }
  }

  int get _marketUnread => AlertStore.instance.marketUnreadCount(
        _alerts.map((a) => a.id),
      );

  void _markAllMarketRead() {
    AlertStore.instance.markAllMarketRead(_alerts.map((a) => a.id));
  }

  void _markAllExecutionsRead() {
    AlertStore.instance.markAllExecutionsRead();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<NotificationProvider>();
    final executions = AlertStore.instance.executions;

    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            TabBar(
              controller: _tabController,
              labelColor: TColors.primary,
              unselectedLabelColor: context.tTextSecondary,
              indicatorColor: TColors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Market'.tr(context)),
                      if (_marketUnread > 0) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: _marketUnread),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Executions'.tr(context)),
                      if (AlertStore.instance.executionUnreadCount > 0) ...[
                        const SizedBox(width: 6),
                        _CountBadge(
                            count: AlertStore.instance.executionUnreadCount),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _loading ? _buildSkeleton() : _buildMarketList(),
                  _buildExecutionsList(executions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: context.tSurface,
      child: Row(
        children: [
          const Icon(Icons.notifications_rounded,
              size: 22, color: TColors.primary),
          const SizedBox(width: 8),
          Text('Alerts'.tr(context), style: context.tHeading3),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAlerts,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, i) => TShimmerCard(height: 90)
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: context.tBorderLight),
    );
  }

  Widget _buildMarketList() {
    if (_alerts.isEmpty) {
      return TEmptyState(
        icon: Icons.notifications_off_rounded,
        title: 'No market alerts'.tr(context),
        subtitle: 'No high-urgency feed items right now.'.tr(context),
      );
    }

    return Column(
      children: [
        if (_marketUnread > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _markAllMarketRead,
                child: Text('Mark all read'.tr(context)),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAlerts,
            color: TColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _alerts.length,
              itemBuilder: (ctx, i) {
                final alert = _alerts[i];
                final isRead =
                    AlertStore.instance.readMarketIds.contains(alert.id);
                return _MarketAlertCard(
                  item: alert,
                  isRead: isRead,
                  onTap: () {
                    AlertStore.instance.markMarketRead(alert.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InsightScreen(
                          inputText: alert.analyseText,
                          sourceUrl: alert.url,
                          sourceTitle: alert.title,
                          sourceLabel:
                              '${alert.source} · ${_timeAgo(alert.publishedAt)}',
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: 40 * i));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionsList(List<ExecutionNotification> executions) {
    if (executions.isEmpty) {
      return TEmptyState(
        icon: Icons.play_circle_outline_rounded,
        title: 'No execution alerts'.tr(context),
        subtitle:
            'When you execute an action, results appear here and as push notifications.'
                .tr(context),
      );
    }

    return Column(
      children: [
        if (AlertStore.instance.executionUnreadCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _markAllExecutionsRead,
                child: Text('Mark all read'.tr(context)),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: executions.length,
            itemBuilder: (ctx, i) {
              final n = executions[i];
              return _ExecutionAlertCard(
                notification: n,
                onTap: () {
                  AlertStore.instance.markExecutionRead(n.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExecutionDetailScreen(notification: n),
                    ),
                  );
                },
              ).animate().fadeIn(delay: Duration(milliseconds: 40 * i));
            },
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TColors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _MarketAlertCard extends StatelessWidget {
  final NewsItem item;
  final bool isRead;
  final VoidCallback onTap;

  const _MarketAlertCard({
    required this.item,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: context.tCard.copyWith(
          color: isRead
              ? context.tSurface
              : TColors.amberLight.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            TUrgencyDot(urgency: item.urgency),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.tBodyMd.copyWith(
                          fontWeight:
                              isRead ? FontWeight.w400 : FontWeight.w600)),
                  Text(item.source, style: context.tCaption),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: TColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExecutionAlertCard extends StatelessWidget {
  final ExecutionNotification notification;
  final VoidCallback onTap;

  const _ExecutionAlertCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: context.tCard.copyWith(
          border: Border.all(
            color:
                n.read ? context.tBorder : TColors.teal.withValues(alpha: 0.4),
            width: n.read ? 0.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TColors.tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: TColors.teal, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: context.tBodyMd.copyWith(
                          fontWeight:
                              n.read ? FontWeight.w400 : FontWeight.w600)),
                  Text(n.summary, style: context.tCaption, maxLines: 2),
                ],
              ),
            ),
            if (!n.read)
              TBadge(
                label: 'New'.tr(context),
                color: TColors.teal,
                bg: TColors.tealLight,
              ),
          ],
        ),
      ),
    );
  }
}
