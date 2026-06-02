// lib/features/insight/insight_screen.dart
// Screen 3: Insight Card — Insight + Impact + Actions + Agent trace steps

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../../core/models/tadbeer_models.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/language_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/user_profile_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../simulation/before_after_screen.dart';

class InsightScreen extends StatefulWidget {
  final String? inputText;
  final String? sourceUrl;
  final String? sourceTitle;
  final String? sourceLabel;
  final String language;

  const InsightScreen({
    super.key,
    this.inputText,
    this.sourceUrl,
    this.sourceTitle,
    this.sourceLabel,
    this.language = 'en',
  });

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  InsightResult? _result;
  bool _loading = true;
  String? _error;
  bool _simulating = false;
  int _selectedActionIndex = 0;

  @override
  void initState() {
    super.initState();
    _analyse();
  }

  Future<void> _analyse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.analyse(
        text: widget.inputText,
        sourceUrl: widget.sourceUrl,
        language: widget.language,
      );
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<UserProfile?> _loadProfile() async {
    if (AuthService.instance.isGuest) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final existing = await UserProfileService.instance.loadProfile(uid);
    return existing ?? await UserProfileService.instance.getOrCreateFromAuth();
  }

  Future<void> _executeSimulation() async {
    setState(() => _simulating = true);
    try {
      // Determine if we are running in Guest Mode (either via AuthService state, Hive profile mode, or no signed in user)
      bool isGuestMode = AuthService.instance.isGuest ||
          FirebaseAuth.instance.currentUser == null;
      if (!isGuestMode) {
        try {
          final box = Hive.box<dynamic>('user_profile_box');
          final dynamic profileMap = box.get('user_profile');
          if (profileMap != null) {
            final map = Map<String, dynamic>.from(profileMap);
            if (map['mode'] == 'guest' &&
                FirebaseAuth.instance.currentUser == null) {
              isGuestMode = true;
            }
          }
        } catch (_) {}
      }

      // Handle guest execution
      if (isGuestMode) {
        if (!mounted) return;
        final bool proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Guest Mode Simulation'.tr(context)),
                content: Text(
                  'You are running in Guest Mode. The simulation will execute and calculate results, but no real email or SMS alerts can be dispatched. Create an account to enable real-time alert notifications.'.tr(context),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel'.tr(context)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Run Simulation'.tr(context)),
                  ),
                ],
              ),
            ) ??
            false;

        if (!proceed) {
          setState(() => _simulating = false);
          return;
        }

        final simResult = await ApiService.simulate(
          actionIndex: _selectedActionIndex,
          userId: null,
          notifyChannels: [],
        );

        final actionTitle =
            _result != null && _result!.actions.length > _selectedActionIndex
                ? _result!.actions[_selectedActionIndex].title
                : null;

        final delivery =
            await NotificationService.instance.dispatchExecutionAlert(
          result: simResult,
          actionTitle: actionTitle,
          profile: null,
        );

        final enriched = SimulationResult(
          insightSummary: simResult.insightSummary,
          diffs: simResult.diffs,
          smsDraft: simResult.smsDraft,
          usersReached: simResult.usersReached,
          stateChanges: simResult.stateChanges,
          execTimeSeconds: simResult.execTimeSeconds,
          execLog: simResult.execLog,
          deliveryReport: delivery.deliveryReport,
        );

        if (mounted) {
          setState(() => _simulating = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeforeAfterScreen(
                result: enriched,
                notifiedCount: delivery.deliveryReport.totalRecipients,
              ),
            ),
          );
        }
        return;
      }

      // Handle registered user execution
      final profile = await _loadProfile();

      // Build notification channels from profile (if available)
      final channels = <String>[];
      if (profile != null && profile.canReceiveNotifications) {
        if (profile.notifySms) channels.add('sms');
        if (profile.notifyEmail) channels.add('email');
        if (profile.notifyPush) channels.add('push');
      }

      // If no notification channels available, warn user but still allow execution
      if (channels.isEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Limited Notifications'.tr(context)),
            content: Text(
              'Your profile isn\'t fully configured for notifications. '
              'The simulation will run, but real-time alerts (SMS, Email) won\'t be dispatched.\n\n'
              'Go to Settings to complete your profile for full notification support.'.tr(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Run Anyway'.tr(context)),
              ),
            ],
          ),
        );
        if (proceed != true) {
          setState(() => _simulating = false);
          return;
        }
      }

      final simResult = await ApiService.simulate(
        actionIndex: _selectedActionIndex,
        userId: profile?.uid,
        notifyChannels: channels,
      );

      final actionTitle =
          _result != null && _result!.actions.length > _selectedActionIndex
              ? _result!.actions[_selectedActionIndex].title
              : null;

      final delivery =
          await NotificationService.instance.dispatchExecutionAlert(
        result: simResult,
        actionTitle: actionTitle,
        profile: profile,
      );

      final enriched = SimulationResult(
        insightSummary: simResult.insightSummary,
        diffs: simResult.diffs,
        smsDraft: simResult.smsDraft,
        usersReached: simResult.usersReached,
        stateChanges: simResult.stateChanges,
        execTimeSeconds: simResult.execTimeSeconds,
        execLog: simResult.execLog,
        deliveryReport: delivery.deliveryReport,
      );

      if (mounted) {
        setState(() => _simulating = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BeforeAfterScreen(
              result: enriched,
              notifiedCount: delivery.deliveryReport.totalRecipients,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _simulating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'Execution failed'.tr(context)}: $e'),
            backgroundColor: TColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      appBar: TTopBar(
        title: 'Analysis result'.tr(context),
        subtitle: 'Antigravity pipeline · 5 agents'.tr(context),
        actions: [
          TBadge(
            label: _loading ? 'Analysing…'.tr(context) : 'Done'.tr(context),
            color: _loading ? TColors.amber : TColors.teal,
            bg: _loading ? TColors.amberLight : TColors.tealLight,
            icon: _loading ? Icons.sync_rounded : Icons.check_circle_rounded,
          ),
          SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  // ── LOADING ────────────────────────────────
  Widget _buildLoading() {
    final steps = [
      'Ingesting content…'.tr(context),
      'Extracting insights…'.tr(context),
      'Analysing impact…'.tr(context),
      'Generating actions…'.tr(context),
      'Running simulation…'.tr(context),
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: TColors.primary, strokeWidth: 2),
            SizedBox(height: 24),
            Text('TadbeerAI is thinking…'.tr(context), style: context.tHeading3),
            SizedBox(height: 20),
            ...steps
                .asMap()
                .entries
                .map((e) => _LoadStep(label: e.value, index: e.key)),
          ],
        ),
      ),
    );
  }

  // ── ERROR ──────────────────────────────────
  Widget _buildError() {
    final message = _error ?? 'Please try again'.tr(context);
    final displayMessage =
        message.length > 280 ? '${message.substring(0, 280)}…' : message;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: context.tTextTertiary),
            const SizedBox(height: 16),
            Text('Something went wrong'.tr(context),
                style: context.tHeading3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(displayMessage,
                style: context.tBodyMd, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TPrimaryButton(
              label: 'Retry'.tr(context),
              icon: Icons.refresh_rounded,
              onTap: _analyse,
            ),
          ],
        ),
      ),
    );
  }

  // ── CONTENT ────────────────────────────────
  Widget _buildContent() {
    final r = _result!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source chip
                if (widget.sourceTitle != null || widget.sourceLabel != null)
                  _SourceChip(
                    title:
                        widget.sourceTitle ?? widget.sourceUrl ?? 'Input text',
                    label: widget.sourceLabel ?? '',
                  ).animate().fadeIn(),
                SizedBox(height: 10),
                // Insight card
                _InsightCard(result: r)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.05),
                SizedBox(height: 10),
                // Impact card
                _ImpactCard(impacts: r.impacts)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.05),
                SizedBox(height: 10),
                // Actions card
                _ActionsCard(
                  actions: r.actions,
                  selectedIndex: _selectedActionIndex,
                  onSelect: (i) => setState(() => _selectedActionIndex = i),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                SizedBox(height: 10),
                // Agent trace mini
                _AgentTraceMini(trace: r.agentTrace)
                    .animate()
                    .fadeIn(delay: 400.ms),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
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
      child: TPrimaryButton(
        label: 'Execute & notify users'.tr(context),
        icon: Icons.notifications_active_rounded,
        isLoading: _simulating,
        onTap: _executeSimulation,
      ),
    );
  }
}

// ── INSIGHT CARD ─────────────────────────────
class _InsightCard extends StatelessWidget {
  final InsightResult result;
  const _InsightCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.tCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TCardHeader(
              icon: Icons.lightbulb_rounded,
              label: 'Key insight'.tr(context),
              color: TColors.primaryDark,
              bg: TColors.primaryLight),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.insightTitle,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.tTextPrimary,
                        height: 1.4)),
                SizedBox(height: 6),
                Text(result.insightDetail, style: context.tBodyMd),
                SizedBox(height: 10),
                // Confidence bar
                Row(
                  children: [
                    Text('Confidence'.tr(context),
                        style: TextStyle(
                            fontSize: 11, color: context.tTextTertiary)),
                    SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: result.confidence,
                          backgroundColor: context.tBorder,
                          color: TColors.teal,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('${(result.confidence * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TColors.tealDark)),
                  ],
                ),
                // Confidence reason (unique feature!)
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: TColors.tealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 13, color: TColors.tealDark),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text(result.confidenceReason,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: TColors.tealDark,
                                  height: 1.5))),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: TColors.primaryLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: TColors.primaryDark,
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── IMPACT CARD ───────────────────────────────
class _ImpactCard extends StatelessWidget {
  final List<ImpactItem> impacts;
  const _ImpactCard({required this.impacts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.tCard,
      child: Column(
        children: [
          TCardHeader(
              icon: Icons.trending_up_rounded,
              label: 'Impact analysis'.tr(context),
              color: TColors.amberDark,
              bg: TColors.amberLight),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: impacts.asMap().entries.map((e) {
                final isLast = e.key == impacts.length - 1;
                final item = e.value;
                return Container(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  decoration: isLast
                      ? null
                      : BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: context.tBorder, width: 0.5))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                            color: TColors.amber, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.description, style: context.tBodyMd),
                            if (item.quantified != null) ...[
                              SizedBox(height: 2),
                              Text(item.quantified!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: TColors.amberDark)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTIONS CARD ──────────────────────────────
class _ActionsCard extends StatelessWidget {
  final List<ActionItem> actions;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ActionsCard({
    required this.actions,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.tCard,
      child: Column(
        children: [
          TCardHeader(
              icon: Icons.checklist_rounded,
              label: 'Recommended actions'.tr(context),
              color: TColors.tealDark,
              bg: TColors.tealLight),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: actions.asMap().entries.map((e) {
                final isLast = e.key == actions.length - 1;
                final a = e.value;
                final selected = e.key == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelect(e.key),
                  child: Container(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? TColors.primaryLight.withValues(alpha: 0.5)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                  color: context.tBorder, width: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: selected
                              ? TColors.primary
                              : context.tTextTertiary,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: TColors.tealLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text('${a.rank}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: TColors.tealDark)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: context.tTextPrimary)),
                              const SizedBox(height: 2),
                              Text(a.detail, style: context.tBodyMd),
                              if (a.businessMath != null) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: TColors.tealLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(a.businessMath!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: TColors.tealDark)),
                                    ),
                                    if (a.churnRisk != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: TColors.amberLight,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                            '${'Churn risk: '.tr(context)}${a.churnRisk}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: TColors.amberDark)),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AGENT TRACE MINI ─────────────────────────
class _AgentTraceMini extends StatelessWidget {
  final List<AgentStep> trace;
  const _AgentTraceMini({required this.trace});

  // Mock steps if trace empty
  List<Map<String, dynamic>> get _steps => [
        {
          'name': 'Content ingestor',
          'time': '1.2s',
          'status': AgentStatus.done
        },
        {
          'name': 'Insight extractor',
          'time': '2.1s',
          'status': AgentStatus.done
        },
        {'name': 'Impact analyzer', 'time': '1.8s', 'status': AgentStatus.done},
        {
          'name': 'Action generator',
          'time': '1.4s',
          'status': AgentStatus.done
        },
        {'name': 'Simulation agent', 'time': '—', 'status': AgentStatus.active},
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TSectionLabel(label: 'Agent trace'.tr(context)),
        SizedBox(height: 6),
        Container(
          decoration: context.tCard,
          child: Column(
            children: _steps.asMap().entries.map((e) {
              final isLast = e.key == _steps.length - 1;
              final step = e.value;
              final status = step['status'] as AgentStatus;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: context.tBorder, width: 0.5))),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status == AgentStatus.done
                            ? TColors.teal
                            : status == AgentStatus.active
                                ? TColors.primary
                                : context.tBorder,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text((step['name'] as String).tr(context),
                            style: context.tBodyMd)),
                    if (status == AgentStatus.active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: TColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Running…'.tr(context),
                            style: TextStyle(
                                fontSize: 11,
                                color: TColors.primaryDark,
                                fontWeight: FontWeight.w500)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: TColors.tealLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(step['time'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                color: TColors.tealDark,
                                fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── SOURCE CHIP ───────────────────────────────
class _SourceChip extends StatelessWidget {
  final String title, label;
  _SourceChip({required this.title, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.tSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.tBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.newspaper_rounded, size: 14, color: context.tTextTertiary),
          SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: context.tBodyMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
          if (label.isNotEmpty) ...[
            SizedBox(width: 8),
            Text(label, style: context.tCaption),
          ],
        ],
      ),
    );
  }
}

// ── LOAD STEP ─────────────────────────────────
class _LoadStep extends StatelessWidget {
  final String label;
  final int index;
  const _LoadStep({required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 14, color: TColors.teal),
          SizedBox(width: 8),
          Text(label, style: context.tBodyMd),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 400 * index))
        .fadeIn()
        .slideX(begin: -0.1);
  }
}
