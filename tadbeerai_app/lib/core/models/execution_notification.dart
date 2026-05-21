import 'tadbeer_models.dart';

class ExecutionNotification {
  const ExecutionNotification({
    required this.id,
    required this.title,
    required this.summary,
    required this.insightSummary,
    required this.usersReached,
    required this.stateChanges,
    required this.execTimeSeconds,
    required this.deliveryReport,
    required this.createdAt,
    this.read = false,
    this.smsDraft = '',
    this.diffs = const [],
    this.execLog = const [],
  });

  final String id;
  final String title;
  final String summary;
  final String insightSummary;
  final int usersReached;
  final int stateChanges;
  final double execTimeSeconds;
  final DeliveryReport deliveryReport;
  final DateTime createdAt;
  final bool read;
  final String smsDraft;
  final List<StateDiff> diffs;
  final List<ExecLogLine> execLog;

  ExecutionNotification copyWith({bool? read}) => ExecutionNotification(
        id: id,
        title: title,
        summary: summary,
        insightSummary: insightSummary,
        usersReached: usersReached,
        stateChanges: stateChanges,
        execTimeSeconds: execTimeSeconds,
        deliveryReport: deliveryReport,
        createdAt: createdAt,
        read: read ?? this.read,
        smsDraft: smsDraft,
        diffs: diffs,
        execLog: execLog,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'insight_summary': insightSummary,
        'users_reached': usersReached,
        'state_changes': stateChanges,
        'exec_time_seconds': execTimeSeconds,
        'delivery_report': deliveryReport.toJson(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'read': read,
        'sms_draft': smsDraft,
        'diffs': diffs.map((d) => d.toJson()).toList(),
        'exec_log': execLog.map((l) => l.toJson()).toList(),
      };

  factory ExecutionNotification.fromJson(Map<String, dynamic> json) =>
      ExecutionNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        insightSummary: json['insight_summary'] as String,
        usersReached: json['users_reached'] as int,
        stateChanges: json['state_changes'] as int,
        execTimeSeconds: (json['exec_time_seconds'] as num).toDouble(),
        deliveryReport: DeliveryReport.fromJson(
          json['delivery_report'] as Map<String, dynamic>,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        read: json['read'] as bool? ?? false,
        smsDraft: json['sms_draft'] as String? ?? '',
        diffs: json['diffs'] != null
            ? (json['diffs'] as List)
                .map((e) => StateDiff.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        execLog: json['exec_log'] != null
            ? (json['exec_log'] as List)
                .map((e) => ExecLogLine.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );

  static ExecutionNotification fromSimulation({
    required SimulationResult result,
    required DeliveryReport delivery,
    String? title,
  }) {
    final now = DateTime.now();
    return ExecutionNotification(
      id: now.microsecondsSinceEpoch.toString(),
      title: title ?? 'Execution completed',
      summary:
          '${result.stateChanges} changes · ${_formatNum(result.usersReached)} users notified',
      insightSummary: result.insightSummary,
      usersReached: result.usersReached,
      stateChanges: result.stateChanges,
      execTimeSeconds: result.execTimeSeconds,
      deliveryReport: delivery,
      createdAt: now,
      smsDraft: result.smsDraft,
      diffs: result.diffs,
      execLog: result.execLog,
    );
  }

  static String _formatNum(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

