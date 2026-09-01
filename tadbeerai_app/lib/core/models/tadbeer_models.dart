enum UrgencyLevel { high, medium, low }

enum InputMode { text, pdf, url }

enum LogType { ok, info, warn, error }

enum AgentStatus { done, active, waiting }

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.source,
    required this.url,
    this.imageUrl,
    this.previewText,
    this.rawText,
    required this.publishedAt,
    required this.urgency,
    required this.domain,
    required this.relevanceScore,
  });

  final String id;
  final String title;
  final String source;
  final String url;
  final String? imageUrl;
  final String? previewText;
  final String? rawText;
  final DateTime publishedAt;
  final UrgencyLevel urgency;
  final String domain;
  final double relevanceScore;

  /// Text sent with POST /analyse so analysis works when URL scraping fails.
  String get analyseText {
    final parts = <String>[title];
    if (previewText != null && previewText!.trim().isNotEmpty) {
      parts.add(previewText!.trim());
    }
    if (rawText != null && rawText!.trim().isNotEmpty) {
      parts.add(rawText!.trim());
    }
    final combined = parts.join('\n\n');
    if (combined.length <= 4000) return combined;
    return combined.substring(0, 4000);
  }

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'] as String,
        title: json['title'] as String,
        source: json['source'] as String,
        url: json['url'] as String,
        imageUrl: json['image_url'] as String?,
        previewText: json['preview_text'] as String?,
        rawText: json['raw_text'] as String?,
        publishedAt: DateTime.parse(json['published_at'] as String),
        urgency: _urgencyFromString(json['urgency'] as String),
        domain: json['domain'] == 'Supply Chain' ? 'Business Operations' : json['domain'] as String,
        relevanceScore: (json['relevance_score'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source': source,
        'url': url,
        'image_url': imageUrl,
        'preview_text': previewText,
        'raw_text': rawText,
        'published_at': publishedAt.toUtc().toIso8601String(),
        'urgency': urgency.name,
        'domain': domain,
        'relevance_score': relevanceScore,
      };
}

class ImpactItem {
  const ImpactItem({
    required this.description,
    this.quantified,
    required this.severity,
  });

  final String description;
  final String? quantified;
  final String severity;

  factory ImpactItem.fromJson(Map<String, dynamic> json) => ImpactItem(
        description: (json['description'] as String?) ?? '',
        quantified: json['quantified'] as String?,
        severity: (json['severity'] as String?) ?? 'medium',
      );
}

class ActionItem {
  const ActionItem({
    required this.rank,
    required this.title,
    required this.detail,
    this.businessMath,
    this.churnRisk,
  });

  final int rank;
  final String title;
  final String detail;
  final String? businessMath;
  final String? churnRisk;

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
        rank: (json['rank'] as int?) ?? 0,
        title: (json['title'] as String?) ?? '',
        detail: (json['detail'] as String?) ?? '',
        businessMath: json['business_math'] as String?,
        churnRisk: json['churn_risk'] as String?,
      );
}

class AgentStep {
  const AgentStep({
    required this.agentName,
    required this.agentNumber,
    required this.durationSeconds,
    required this.status,
    required this.steps,
  });

  final String agentName;
  final int agentNumber;
  final double durationSeconds;
  final AgentStatus status;
  final List<TraceStep> steps;

  factory AgentStep.fromJson(Map<String, dynamic> json) => AgentStep(
        agentName: json['agent_name'] as String,
        agentNumber: json['agent_number'] as int,
        durationSeconds: (json['duration_seconds'] as num).toDouble(),
        status: _agentStatusFromString(json['status'] as String),
        steps: (json['steps'] as List)
            .map((e) => TraceStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'agent_name': agentName,
        'agent_number': agentNumber,
        'duration_seconds': durationSeconds,
        'status': status.name,
        'steps': steps.map((e) => e.toJson()).toList(),
      };
}

class TraceStep {
  const TraceStep({
    required this.title,
    required this.detail,
    this.decisionText,
    required this.timestamp,
    required this.badges,
  });

  final String title;
  final String detail;
  final String? decisionText;
  final String timestamp;
  final List<String> badges;

  factory TraceStep.fromJson(Map<String, dynamic> json) => TraceStep(
        title: json['title'] as String,
        detail: json['detail'] as String,
        decisionText: json['decision_text'] as String?,
        timestamp: json['timestamp'] as String,
        badges: (json['badges'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'detail': detail,
        'decision_text': decisionText,
        'timestamp': timestamp,
        'badges': badges,
      };
}

class InsightResult {
  const InsightResult({
    required this.insightTitle,
    required this.insightDetail,
    required this.confidence,
    required this.confidenceReason,
    required this.tags,
    required this.impacts,
    required this.actions,
    required this.agentTrace,
  });

  final String insightTitle;
  final String insightDetail;
  final double confidence;
  final String confidenceReason;
  final List<String> tags;
  final List<ImpactItem> impacts;
  final List<ActionItem> actions;
  final List<AgentStep> agentTrace;

  factory InsightResult.fromJson(Map<String, dynamic> json) => InsightResult(
        insightTitle: (json['insight'] as String?) ?? (json['insight_title'] as String?) ?? '',
        insightDetail: (json['insight_detail'] as String?) ?? '',
        confidence: ((json['confidence'] as num?) ?? 0.5).toDouble(),
        confidenceReason: (json['confidence_reason'] as String?) ?? '',
        tags: json['tags'] != null ? (json['tags'] as List).cast<String>() : [],
        impacts: json['impacts'] != null
            ? (json['impacts'] as List)
                .map((e) => ImpactItem.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        actions: json['actions'] != null
            ? (json['actions'] as List)
                .map((e) => ActionItem.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        agentTrace: json['agent_trace'] != null
            ? (json['agent_trace'] as List)
                .map((e) => AgentStep.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );
}

class StateDiff {
  const StateDiff({
    required this.field,
    required this.before,
    required this.after,
  });

  final String field;
  final String before;
  final String after;

  factory StateDiff.fromJson(Map<String, dynamic> json) => StateDiff(
        field: json['field'] as String,
        before: json['before'] as String,
        after: json['after'] as String,
      );

  Map<String, dynamic> toJson() => {
        'field': field,
        'before': before,
        'after': after,
      };
}

class ExecLogLine {
  const ExecLogLine({
    required this.time,
    required this.prefix,
    required this.message,
    required this.type,
  });

  final String time;
  final String prefix;
  final String message;
  final LogType type;

  factory ExecLogLine.fromJson(Map<String, dynamic> json) => ExecLogLine(
        time: json['time'] as String,
        prefix: json['prefix'] as String,
        message: json['message'] as String,
        type: _logTypeFromString(json['type'] as String),
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'prefix': prefix,
        'message': message,
        'type': type.name,
      };
}

class DeliveryReport {
  const DeliveryReport({
    required this.smsRecipients,
    required this.emailRecipients,
    required this.pushRecipients,
    required this.status,
    this.smsSkipped = false,
    this.emailSkipped = false,
    this.pushSkipped = false,
  });

  final int smsRecipients;
  final int emailRecipients;
  final int pushRecipients;
  final String status;
  final bool smsSkipped;
  final bool emailSkipped;
  final bool pushSkipped;

  int get totalRecipients =>
      smsRecipients + emailRecipients + pushRecipients;

  factory DeliveryReport.fromJson(Map<String, dynamic> json) => DeliveryReport(
        smsRecipients: json['sms_recipients'] as int? ?? 0,
        emailRecipients: json['email_recipients'] as int? ?? 0,
        pushRecipients: json['push_recipients'] as int? ?? 0,
        status: json['status'] as String? ?? 'sent',
        smsSkipped: json['sms_skipped'] as bool? ?? false,
        emailSkipped: json['email_skipped'] as bool? ?? false,
        pushSkipped: json['push_skipped'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'sms_recipients': smsRecipients,
        'email_recipients': emailRecipients,
        'push_recipients': pushRecipients,
        'status': status,
        'sms_skipped': smsSkipped,
        'email_skipped': emailSkipped,
        'push_skipped': pushSkipped,
      };

  static DeliveryReport fallback({
    required int usersReached,
    required bool notifySms,
    required bool notifyEmail,
    required bool notifyPush,
    required bool hasPhone,
    required bool hasEmail,
  }) {
    final sms = notifySms && hasPhone ? usersReached : 0;
    final email = notifyEmail && hasEmail ? usersReached : 0;
    final push = notifyPush ? usersReached : 0;
    final any = sms + email + push > 0;
    return DeliveryReport(
      smsRecipients: sms,
      emailRecipients: email,
      pushRecipients: push,
      status: any ? 'sent' : 'partial',
      smsSkipped: !notifySms || !hasPhone,
      emailSkipped: !notifyEmail || !hasEmail,
      pushSkipped: !notifyPush,
    );
  }
}

class SimulationResult {
  const SimulationResult({
    required this.insightSummary,
    required this.diffs,
    required this.smsDraft,
    required this.usersReached,
    required this.stateChanges,
    required this.execTimeSeconds,
    required this.execLog,
    this.deliveryReport,
    this.agentTrace = const [],
  });

  final String insightSummary;
  final List<StateDiff> diffs;
  final String smsDraft;
  final int usersReached;
  final int stateChanges;
  final double execTimeSeconds;
  final List<ExecLogLine> execLog;
  final DeliveryReport? deliveryReport;
  final List<AgentStep> agentTrace;

  factory SimulationResult.fromJson(Map<String, dynamic> json) =>
      SimulationResult(
        insightSummary: json['insight_summary'] as String,
        diffs: (json['diffs'] as List)
            .map((e) => StateDiff.fromJson(e as Map<String, dynamic>))
            .toList(),
        smsDraft: json['sms_draft'] as String,
        usersReached: json['users_reached'] as int,
        stateChanges: json['state_changes'] as int,
        execTimeSeconds: (json['exec_time_seconds'] as num).toDouble(),
        execLog: (json['exec_log'] as List)
            .map((e) => ExecLogLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        deliveryReport: json['delivery_report'] != null
            ? DeliveryReport.fromJson(
                json['delivery_report'] as Map<String, dynamic>,
              )
            : null,
        agentTrace: json['agent_trace'] != null
            ? (json['agent_trace'] as List)
                .map((e) => AgentStep.fromJson(e as Map<String, dynamic>))
                .toList()
            : const [],
      );
}

UrgencyLevel _urgencyFromString(String value) =>
    UrgencyLevel.values.firstWhere((e) => e.name == value);

LogType _logTypeFromString(String value) =>
    LogType.values.firstWhere((e) => e.name == value);

AgentStatus _agentStatusFromString(String value) =>
    AgentStatus.values.firstWhere((e) => e.name == value);

/// Detect scenario key from user input for offline mock routing.
String detectScenarioKey({String? text, String? sourceUrl}) {
  final blob = '${text ?? ''} ${sourceUrl ?? ''}'.toLowerCase();
  if (blob.contains('petrol') || blob.contains('ogra')) return 'petrol';
  if (blob.contains('rupee') || blob.contains('dollar') || blob.contains('295')) {
    return 'rupee';
  }
  if (blob.contains('kse') || blob.contains('stock')) return 'stock';
  if (blob.contains('gold') || blob.contains('tola')) return 'gold';
  if (blob.contains('port') || blob.contains('karachi') || blob.contains('logistics')) {
    return 'port';
  }
  if (blob.contains('sales') || blob.contains('lahore') || blob.contains('decline')) {
    return 'sales';
  }
  return 'petrol';
}

