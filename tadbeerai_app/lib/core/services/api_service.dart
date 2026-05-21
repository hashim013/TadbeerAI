import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tadbeerai/core/models/tadbeer_models.dart';
import 'package:tadbeerai/core/constants/constants.dart';
import 'package:tadbeerai/core/services/auth_service.dart';

/// Backend notification contract (when API is extended):
/// POST /simulate — body may include user_id, scenario, notify_channels;
/// response may include delivery_report { sms_recipients, email_recipients, push_recipients, status }.
/// See docs/api-notifications.md
class ApiService {
  static const _base = TConst.apiBase;
  static const _timeout = Duration(seconds: TConst.apiTimeout);

  static String _lastScenario = 'petrol';

  static String get lastScenario => _lastScenario;

  static String _httpErrorMessage(String action, http.Response res) {
    var detail = res.body;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['detail'] != null) {
        final d = decoded['detail'];
        if (d is String) {
          detail = d;
        } else if (d is List && d.isNotEmpty) {
          detail = d
              .map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString())
              .join('; ');
        }
      }
    } catch (_) {}
    if (detail.length > 200) {
      detail = '${detail.substring(0, 200)}…';
    }
    return '$action failed (${res.statusCode}): $detail';
  }

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await AuthService.instance.getIdToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<NewsItem>> getFeed({bool forceRefresh = false}) async {
    final url = forceRefresh ? '$_base/feed?refresh=true' : '$_base/feed';
    final res = await http
        .get(Uri.parse(url), headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load feed');
  }

  static Future<InsightResult> analyse({
    String? text,
    String? sourceUrl,
    String language = 'en',
  }) async {
    _lastScenario = detectScenarioKey(text: text, sourceUrl: sourceUrl);
    final res = await http
        .post(
          Uri.parse('$_base/analyse'),
          headers: await _headers(),
          body: jsonEncode({
            if (text != null) 'text': text,
            if (sourceUrl != null) 'source_url': sourceUrl,
            'language': language,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      try {
        return InsightResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      } catch (e) {
        throw Exception('Analyse failed: invalid response ($e)');
      }
    }
    throw Exception(_httpErrorMessage('Analyse', res));
  }

  static Future<SimulationResult> simulate({
    required int actionIndex,
    String? userId,
    List<String>? notifyChannels,
  }) async {
    final body = <String, dynamic>{
      'action_index': actionIndex,
      'scenario': _lastScenario,
    };
    if (userId != null) body['user_id'] = userId;
    if (notifyChannels != null && notifyChannels.isNotEmpty) {
      body['notify_channels'] = notifyChannels;
    }

    final res = await http
        .post(
          Uri.parse('$_base/simulate'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return SimulationResult.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to simulate');
  }

  static Future<List<AgentStep>> getTrace() async {
    final res = await http
        .get(Uri.parse('$_base/trace'), headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => AgentStep.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load trace');
  }
}
