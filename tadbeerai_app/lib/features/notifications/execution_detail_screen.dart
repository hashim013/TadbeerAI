import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/execution_notification.dart';
import '../../core/models/tadbeer_models.dart';
import '../../core/providers/language_provider.dart';
import '../../core/services/alert_store.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../simulation/before_after_screen.dart';

class ExecutionDetailScreen extends StatelessWidget {
  const ExecutionDetailScreen({super.key, required this.notification});

  final ExecutionNotification notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final d = n.deliveryReport;

    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Execution alert'.tr(context),
        subtitle: _formatTime(n.createdAt),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: context.tCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TBadge(
                      label: 'Executed'.tr(context),
                      color: TColors.teal,
                      bg: TColors.tealLight,
                      icon: Icons.check_circle_rounded,
                    ),
                    const Spacer(),
                    if (!n.read)
                      TBadge(
                        label: 'New'.tr(context),
                        color: TColors.primary,
                        bg: TColors.primaryLight,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(n.title, style: context.tHeading3),
                const SizedBox(height: 6),
                Text(n.summary, style: context.tBodyMd),
                const SizedBox(height: 12),
                Text(n.insightSummary,
                    style: context.tBodyMd
                        .copyWith(color: TColors.primaryDark, height: 1.5)),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          TSectionLabel(label: 'Delivery report'.tr(context)),
          const SizedBox(height: 8),
          _DeliveryChannelCard(
            icon: Icons.sms_rounded,
            label: 'SMS',
            count: d.smsRecipients,
            skipped: d.smsSkipped,
            color: TColors.amber,
          ),
          _DeliveryChannelCard(
            icon: Icons.email_rounded,
            label: 'Email',
            count: d.emailRecipients,
            skipped: d.emailSkipped,
            color: TColors.primary,
          ),
          _DeliveryChannelCard(
            icon: Icons.notifications_active_rounded,
            label: 'Push',
            count: d.pushRecipients,
            skipped: d.pushSkipped,
            color: TColors.teal,
          ),
          const SizedBox(height: 24),
          TPrimaryButton(
            label: 'View full result'.tr(context),
            icon: Icons.open_in_new_rounded,
            onTap: () {
              AlertStore.instance.markExecutionRead(n.id);
              final sim = SimulationResult(
                insightSummary: n.insightSummary,
                diffs: n.diffs,
                smsDraft: n.smsDraft,
                usersReached: n.usersReached,
                stateChanges: n.stateChanges,
                execTimeSeconds: n.execTimeSeconds,
                execLog: n.execLog,
                deliveryReport: d,
                agentTrace: n.agentTrace,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BeforeAfterScreen(result: sim),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DeliveryChannelCard extends StatelessWidget {
  const _DeliveryChannelCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.skipped,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool skipped;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: context.tCard,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.tr(context),
                    style:
                        context.tBodyMd.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  skipped
                      ? 'Skipped (disabled or missing contact)'.tr(context)
                      : 'Delivered'.tr(context),
                  style: context.tCaption,
                ),
              ],
            ),
          ),
          Text(
            skipped ? '—' : '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: skipped ? context.tTextTertiary : color,
            ),
          ),
        ],
      ),
    );
  }
}
