// lib/features/trace/agent_trace_screen.dart
// Screen 5: Agent Trace Log — Expandable per-agent reasoning steps

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import '../../core/models/tadbeer_models.dart';
import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';

class AgentTraceScreen extends StatefulWidget {
  final String? insightId;
  final List<AgentStep>? steps;
  const AgentTraceScreen({super.key, this.insightId, this.steps});

  @override
  State<AgentTraceScreen> createState() => _AgentTraceScreenState();
}

class _AgentTraceScreenState extends State<AgentTraceScreen> {
  List<AgentStep> _steps = [];
  bool _loading = true;
  final Set<int> _expanded = {0, 3}; // open by default

  @override
  void initState() {
    super.initState();
    _loadTrace();
  }

  Future<void> _loadTrace() async {
    if (widget.steps != null && widget.steps!.isNotEmpty) {
      setState(() {
        _steps = widget.steps!;
        _loading = false;
      });
      return;
    }
    final steps = await ApiService.getTrace();
    setState(() {
      _steps = steps;
      _loading = false;
    });
  }

  double get _totalTime => _steps.fold(0, (sum, s) => sum + s.durationSeconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Agent trace',
        subtitle: 'Google Antigravity orchestration log',
        actions: [
          GestureDetector(
            onTap: _exportTrace,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.download_rounded,
                      size: 14, color: TColors.primary),
                  SizedBox(width: 4),
                  Text('Export',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: TColors.primary))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary metrics
          _buildSummaryRow().animate().fadeIn(),
          SizedBox(height: 14),
          const TSectionLabel(label: 'Antigravity reasoning trace'),
          SizedBox(height: 8),
          // Agent blocks
          ..._steps.asMap().entries.map(
                (e) => _AgentBlock(
                  step: e.value,
                  isExpanded: _expanded.contains(e.key),
                  onToggle: () => setState(() {
                    if (_expanded.contains(e.key)) {
                      _expanded.remove(e.key);
                    } else {
                      _expanded.add(e.key);
                    }
                  }),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 60 * e.key))
                    .slideY(begin: 0.03),
              ),
          SizedBox(height: 12),
          // Antigravity strip
          _buildAntigravityStrip().animate().fadeIn(delay: 400.ms),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
            child: _MetricCard(
          label: 'Total agents',
          value: '${_steps.length}',
          sub: 'All completed',
        )),
        SizedBox(width: 10),
        Expanded(
            child: _MetricCard(
          label: 'Total time',
          value: '${_totalTime.toStringAsFixed(1)}s',
          sub:
              '${_steps.fold(0, (s, a) => s + a.steps.length)} reasoning steps',
        )),
      ],
    );
  }

  Widget _buildAntigravityStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: TColors.primary.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: TColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Orchestrated by Google Antigravity · Workplan, task plan, decision flow and action execution logs exported',
              style: TextStyle(
                  fontSize: 12, color: TColors.primaryDark, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _exportTrace() {
    try {
      final list = _steps.map((s) => s.toJson()).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(list);
      Share.share(
        jsonStr,
        subject: 'TadbeerAI Agent Reasoning Trace',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to export trace: $e'),
          backgroundColor: TColors.red));
    }
  }
}

// ── AGENT BLOCK ───────────────────────────────
class _AgentBlock extends StatelessWidget {
  final AgentStep step;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AgentBlock({
    required this.step,
    required this.isExpanded,
    required this.onToggle,
  });

  Color _dotColor(BuildContext context) {
    switch (step.status) {
      case AgentStatus.done:
        return TColors.teal;
      case AgentStatus.active:
        return TColors.primary;
      case AgentStatus.waiting:
        return context.tBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: context.tCard,
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: context.tSurfaceAlt,
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12))
                    : BorderRadius.circular(12),
                border: isExpanded
                    ? Border(
                        bottom: BorderSide(color: context.tBorder, width: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: _dotColor(context), shape: BoxShape.circle),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agent ${step.agentNumber} — ${step.agentName}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.tTextPrimary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: TColors.tealLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${step.durationSeconds}s',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: TColors.tealDark)),
                  ),
                  SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: context.tTextTertiary),
                  ),
                ],
              ),
            ),
          ),
          // Steps
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: step.steps.asMap().entries.map((e) {
                  final isLast = e.key == step.steps.length - 1;
                  return _TraceStepRow(step: e.value, isLast: isLast);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── TRACE STEP ROW ────────────────────────────
class _TraceStepRow extends StatelessWidget {
  final TraceStep step;
  final bool isLast;
  const _TraceStepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: isLast ? 8 : 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.tBorder, width: 0.5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: step.decisionText != null
                  ? TColors.amberLight
                  : TColors.tealLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              step.decisionText != null
                  ? Icons.account_tree_rounded
                  : Icons.check_rounded,
              size: 13,
              color: step.decisionText != null
                  ? TColors.amberDark
                  : TColors.tealDark,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.tTextPrimary)),
                SizedBox(height: 2),
                Text(step.detail, style: context.tCaption),
                // Decision box — Antigravity reasoning (amber box)
                if (step.decisionText != null) ...[
                  SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: TColors.amberLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: TColors.amber.withValues(alpha: 0.3),
                          width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ANTIGRAVITY DECISION',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: TColors.amberDark,
                                letterSpacing: 0.07 * 10)),
                        SizedBox(height: 4),
                        Text(step.decisionText!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: TColors.amberDark,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
                // Badges
                if (step.badges.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: step.badges
                        .map((b) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: TColors.tealLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(b,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: TColors.tealDark)),
                            ))
                        .toList(),
                  ),
                ],
                SizedBox(height: 4),
                Text(step.timestamp,
                    style: TextStyle(
                        fontSize: 10,
                        color: context.tTextTertiary,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── METRIC CARD ───────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  const _MetricCard(
      {required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: context.tCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.tCaption),
          SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.tTextPrimary)),
          SizedBox(height: 2),
          Text(sub, style: context.tCaption),
        ],
      ),
    );
  }
}
