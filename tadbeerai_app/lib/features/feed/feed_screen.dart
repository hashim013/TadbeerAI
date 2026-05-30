// lib/features/feed/feed_screen.dart
// Screen 1: Proactive News Feed — TadbeerAI's unique killer feature

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/tadbeer_models.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/domain_config.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../home/home_screen.dart';
import '../insight/insight_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<NewsItem> _items = [];
  bool _loading = true;
  DateTime? _lastRefreshed;
  String _selectedDomain = 'All';

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getFeed(forceRefresh: forceRefresh);
      setState(() {
        _items = items;
        _loading = false;
        _lastRefreshed = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading ? _buildSkeleton() : _buildFeed(),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────
  Widget _buildHeader() {
    final newCount = _items.where((i) => i.urgency == UrgencyLevel.high).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: context.tSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Proactive feed', style: context.tHeading3),
              const Spacer(),
              GestureDetector(
                onTap: () => _loadFeed(forceRefresh: true),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.tBorder, width: 0.5),
                  ),
                  child: Icon(Icons.refresh_rounded,
                      size: 18, color: context.tTextSecondary),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text('Business alerts',
                  style:
                      TextStyle(fontSize: 13, color: context.tTextSecondary)),
              const Spacer(),
              if (_lastRefreshed != null)
                Text('Updated ${_timeAgo(_lastRefreshed!)}',
                    style: context.tCaption),
            ],
          ),
          if (newCount > 0) ...[
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TColors.redLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: TColors.red.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: TColors.red),
                  SizedBox(width: 6),
                  Text(
                      '$newCount high-urgency alert${newCount > 1 ? 's' : ''} require action',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: TColors.redDark)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── FEED LIST ──────────────────────────────
  Widget _buildFeed() {
    final filteredItems = _selectedDomain == 'All'
        ? _items
        : _items
            .where(
                (i) => i.domain.toLowerCase() == _selectedDomain.toLowerCase())
            .toList();

    if (filteredItems.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _buildDomainFilter(),
          ),
          Expanded(
            child: TEmptyState(
              icon: Icons.newspaper_rounded,
              title: _items.isEmpty
                  ? 'No alerts right now'
                  : 'No alerts in $_selectedDomain',
              subtitle: _items.isEmpty
                  ? 'Pull to refresh or paste your own news below'
                  : 'Pull to refresh or select another category',
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFeed(forceRefresh: true),
      color: TColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: filteredItems.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0)
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDomainFilter(),
            );
          final item = filteredItems[i - 1];
          return _NewsCard(
            item: item,
            index: i - 1,
            onAct: () => _onAct(item),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 50 * (i < 6 ? i : 0)))
              .slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }

  // ── DOMAIN FILTER CHIPS ───────────────────
  Widget _buildDomainFilter() {
    final domains = [
      'All',
      ...DomainConfig.domainConfig.keys,
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        key: const PageStorageKey('domain_filter_list'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: domains.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final isSelected = _selectedDomain == domains[i];
          final accentColor = domains[i] == 'All'
              ? TColors.primary
              : DomainConfig.colorFor(domains[i]);
          return GestureDetector(
            onTap: () => setState(() => _selectedDomain = domains[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : context.tSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: isSelected ? accentColor : context.tBorder,
                    width: 0.5),
              ),
              child: Text(domains[i],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          isSelected ? Colors.white : context.tTextSecondary)),
            ),
          );
        },
      ),
    );
  }

  // ── SKELETON LOADING ──────────────────────
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, i) => TShimmerCard(height: 100)
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: context.tBorderLight),
    );
  }

  // ── ACT HANDLER ───────────────────────────
  void _onAct(NewsItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InsightScreen(
          inputText: item.analyseText,
          sourceUrl: item.url,
          sourceTitle: item.title,
          sourceLabel: '${item.source} · ${_timeAgo(item.publishedAt)}',
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── NEWS CARD ─────────────────────────────────
class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final int index;
  final VoidCallback onAct;

  _NewsCard({required this.item, required this.index, required this.onAct});

  Color get _urgencyColor {
    switch (item.urgency) {
      case UrgencyLevel.high:
        return TColors.urgencyHigh;
      case UrgencyLevel.medium:
        return TColors.urgencyMed;
      case UrgencyLevel.low:
        return TColors.urgencyLow;
    }
  }

  String get _urgencyLabel {
    switch (item.urgency) {
      case UrgencyLevel.high:
        return 'High';
      case UrgencyLevel.medium:
        return 'Medium';
      case UrgencyLevel.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 6),
      decoration: BoxDecoration(
        color: context.tSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.urgency == UrgencyLevel.high
              ? TColors.red.withValues(alpha: 0.3)
              : context.tBorder,
          width: item.urgency == UrgencyLevel.high ? 1 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Urgency dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                      color: _urgencyColor, shape: BoxShape.circle),
                ),
                SizedBox(width: 10),
                // Title
                Expanded(
                  child: Text(item.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.tTextPrimary,
                          height: 1.4)),
                ),
                SizedBox(width: 8),
                // Act button
                GestureDetector(
                  onTap: onAct,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.urgency == UrgencyLevel.high
                          ? TColors.primary
                          : TColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.urgency == UrgencyLevel.high ? 'Act now' : 'Act',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.urgency == UrgencyLevel.high
                              ? Colors.white
                              : TColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Meta row
            Row(
              children: [
                const SizedBox(width: 18),
                Flexible(
                  child: _SourceChip(label: item.source),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: _DomainChip(label: item.domain),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _urgencyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_urgencyLabel,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _urgencyColor)),
                ),
              ],
            ),
            if (item.previewText != null) ...[
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(item.previewText!,
                    style: context.tCaption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  _SourceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.tSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.tBorder, width: 0.5),
      ),
      child: Text(label, style: context.tCaption),
    );
  }
}

class _DomainChip extends StatelessWidget {
  final String label;
  _DomainChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: TColors.primaryDark,
              fontWeight: FontWeight.w500)),
    );
  }
}
