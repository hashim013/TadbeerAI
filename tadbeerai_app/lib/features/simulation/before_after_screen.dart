// lib/features/simulation/before_after_screen.dart
// Screen 4: Before/After State — Most important screen for judges

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/models/tadbeer_models.dart';
import '../../core/providers/language_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../trace/agent_trace_screen.dart';

class BeforeAfterScreen extends StatefulWidget {
  final SimulationResult result;
  final int? notifiedCount;

  const BeforeAfterScreen({
    super.key,
    required this.result,
    this.notifiedCount,
  });

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Simulation result'.tr(context),
        subtitle: widget.notifiedCount != null
            ? '${'Alerts sent to'.tr(context)} ${widget.notifiedCount} ${'recipients'.tr(context)}'
            : 'Antigravity Agent 6 · executed'.tr(context),
        actions: [
          TBadge(
            label: 'Executed'.tr(context),
            color: TColors.teal,
            bg: TColors.tealLight,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.notifiedCount != null) _buildSuccessBanner(),
            _buildInsightChip(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChangesTab(),
                  _buildDeliveryTab(),
                  _buildExecLogTab(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TColors.tealLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: TColors.teal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Execution alerts sent via SMS, email, and push to registered users.'
                  .tr(context),
              style: TextStyle(
                fontSize: 12,
                color: TColors.tealDark,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ── INSIGHT CHIP ───────────────────────────
  Widget _buildInsightChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: TColors.primary.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_rounded, size: 14, color: TColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(widget.result.insightSummary,
                  style: const TextStyle(
                      fontSize: 12,
                      color: TColors.primaryDark,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }

  // ── TAB BAR ────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      height: 40,
      decoration: BoxDecoration(
        color: context.tSurfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.tBorder, width: 0.5),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: TColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: context.tTextSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        tabs: [
          Tab(text: 'State changes'.tr(context)),
          Tab(text: 'Delivery'.tr(context)),
          Tab(text: 'Exec log'.tr(context)),
        ],
      ),
    );
  }

  // ── CHANGES TAB ────────────────────────────
  Widget _buildChangesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TSectionLabel(label: 'State diff'.tr(context)),
          SizedBox(height: 6),
          _buildDiffTable().animate().fadeIn(delay: 100.ms),
          SizedBox(height: 12),
          TSectionLabel(label: 'Simulated SMS draft'.tr(context)),
          SizedBox(height: 6),
          _buildSmsDraft().animate().fadeIn(delay: 200.ms),
          SizedBox(height: 12),
          _buildOutcomeStrip().animate().fadeIn(delay: 300.ms),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDiffTable() {
    return Container(
      decoration: context.tCard,
      child: Column(
        children: widget.result.diffs.asMap().entries.map((e) {
          final isLast = e.key == widget.result.diffs.length - 1;
          return _DiffRow(diff: e.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildSmsDraft() {
    return Container(
      decoration: context.tCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TColors.amberLight,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(
                  bottom: BorderSide(color: context.tBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sms_rounded,
                    size: 14, color: TColors.amberDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'To:'.tr(context)} ${_formatNum(widget.result.usersReached)} ${'customers'.tr(context)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TColors.amberDark),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.result.smsDraft));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('SMS draft copied'.tr(context)),
                        backgroundColor: TColors.teal,
                        duration: const Duration(seconds: 2)));
                  },
                  child: const Icon(Icons.copy_rounded,
                      size: 14, color: TColors.amberDark),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(widget.result.smsDraft,
                style: TextStyle(
                    fontSize: 13,
                    color: context.tTextSecondary,
                    height: 1.6,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TColors.tealLight,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: TColors.teal.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 20, color: TColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${'Complete'.tr(context)} · ${widget.result.stateChanges} ${'state changes'.tr(context)} · '
              '${_formatNum(widget.result.usersReached)} ${'users reached'.tr(context)} · '
              '${widget.result.execTimeSeconds}${'s'.tr(context)} · 0 ${'errors'.tr(context)}',
              style: const TextStyle(
                  fontSize: 12,
                  color: TColors.tealDark,
                  fontWeight: FontWeight.w500,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab() {
    final d = widget.result.deliveryReport;
    if (d == null) {
      return TEmptyState(
        icon: Icons.send_rounded,
        title: 'No delivery data'.tr(context),
        subtitle: 'Delivery report will appear after execution.'.tr(context),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TSectionLabel(label: 'Notification delivery'.tr(context)),
          const SizedBox(height: 8),
          _DeliveryRow(
            icon: Icons.sms_rounded,
            label: 'SMS',
            count: d.smsRecipients,
            skipped: d.smsSkipped,
            color: TColors.amber,
          ),
          _DeliveryRow(
            icon: Icons.email_rounded,
            label: 'Email',
            count: d.emailRecipients,
            skipped: d.emailSkipped,
            color: TColors.primary,
          ),
          _DeliveryRow(
            icon: Icons.notifications_active_rounded,
            label: 'Push',
            count: d.pushRecipients,
            skipped: d.pushSkipped,
            color: TColors.teal,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: TColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'Status:'.tr(context)} ${d.status.toUpperCase()} · '
                    '${d.totalRecipients} ${'total notifications'.tr(context)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── EXEC LOG TAB ───────────────────────────
  Widget _buildExecLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TSectionLabel(label: 'Execution log'.tr(context)),
          SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: TColors.termBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08), width: 0.5),
            ),
            child: Column(
              children: widget.result.execLog.asMap().entries.map((e) {
                return _LogLine(
                    line: e.value,
                    isLast: e.key == widget.result.execLog.length - 1);
              }).toList(),
            ),
          ).animate().fadeIn(delay: 100.ms),
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: TColors.primary.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: TColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Orchestrated by Google Antigravity · Full workplan + task logs available for judge review'
                        .tr(context),
                    style: const TextStyle(
                        fontSize: 12, color: TColors.primaryDark, height: 1.5),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── BOTTOM BAR ────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: context.tSurface,
        border: Border(top: BorderSide(color: context.tBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgentTraceScreen(
                    steps: widget.result.agentTrace,
                  ),
                ),
              ),
              icon: const Icon(Icons.account_tree_rounded, size: 15),
              label: Text('View trace'.tr(context)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.download_rounded, size: 15),
              label: Text('Export PDF'.tr(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final result = widget.result;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, text: 'TadbeerAI Analysis Report'),
          pw.Header(level: 1, text: 'Insight'),
          pw.Paragraph(text: result.insightSummary),
          pw.Header(level: 1, text: 'State Changes'),
          pw.TableHelper.fromTextArray(
            headers: ['Field', 'Before', 'After'],
            data:
                result.diffs.map((d) => [d.field, d.before, d.after]).toList(),
          ),
          pw.Header(level: 1, text: 'SMS Draft'),
          pw.Paragraph(text: result.smsDraft),
          pw.Header(level: 1, text: 'Execution Log'),
          ...result.execLog.map(
            (l) => pw.Paragraph(text: '${l.time} ${l.prefix} ${l.message}'),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'tadbeerai_report.pdf',
    );
  }

  String _formatNum(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _DeliveryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool skipped;
  final Color color;

  const _DeliveryRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.skipped,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: context.tCard,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
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
                      ? 'Skipped'.tr(context)
                      : '${'Delivered to'.tr(context)} $count ${'users'.tr(context)}',
                  style: context.tCaption,
                ),
              ],
            ),
          ),
          TStatusChip(
            label: skipped ? 'Off'.tr(context) : 'Sent'.tr(context),
            color: skipped ? TColors.textTertiary : TColors.teal,
          ),
        ],
      ),
    );
  }
}

// ── DIFF ROW ──────────────────────────────────
class _DiffRow extends StatelessWidget {
  final StateDiff diff;
  final bool isLast;
  const _DiffRow({required this.diff, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.tBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(diff.field,
                style: TextStyle(fontSize: 12, color: context.tTextSecondary)),
          ),
          // Before chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TColors.redLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(diff.before,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TColors.redDark)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded,
                size: 13, color: context.tTextTertiary),
          ),
          // After chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TColors.tealLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(diff.after,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TColors.tealDark)),
          ),
        ],
      ),
    );
  }
}

// ── LOG LINE ──────────────────────────────────
class _LogLine extends StatelessWidget {
  final ExecLogLine line;
  final bool isLast;
  const _LogLine({required this.line, required this.isLast});

  Color get _prefixColor {
    switch (line.type) {
      case LogType.ok:
        return TColors.termOk;
      case LogType.info:
        return TColors.termInfo;
      case LogType.warn:
        return TColors.termWarn;
      case LogType.error:
        return TColors.termError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.time,
              style: const TextStyle(
                  fontSize: 11,
                  color: TColors.termMuted,
                  fontFamily: 'monospace')),
          SizedBox(width: 10),
          Text(line.prefix,
              style: TextStyle(
                  fontSize: 11,
                  color: _prefixColor,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          Expanded(
            child: Text(line.message,
                style: const TextStyle(
                    fontSize: 11,
                    color: TColors.termText,
                    fontFamily: 'monospace',
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
