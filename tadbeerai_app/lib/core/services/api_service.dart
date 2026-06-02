import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:tadbeerai/core/models/tadbeer_models.dart';
import 'package:tadbeerai/core/models/user_profile_model.dart';
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
    String? category;
    try {
      final box = Hive.box<dynamic>('user_profile_box');
      final dynamic raw = box.get('user_profile');
      if (raw != null) {
        final profile = UserProfileModel.fromJson(Map<String, dynamic>.from(raw));
        if (profile.category.isNotEmpty) {
          category = profile.category;
        }
      }
    } catch (_) {}

    var url = forceRefresh ? '$_base/feed?refresh=true' : '$_base/feed';
    if (category != null && category.isNotEmpty) {
      url += url.contains('?') ? '&category=$category' : '?category=$category';
    }

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

    Map<String, dynamic>? userProfileJson;
    try {
      final box = Hive.box<dynamic>('user_profile_box');
      final dynamic profileMap = box.get('user_profile');
      if (profileMap != null) {
        final map = Map<String, dynamic>.from(profileMap);
        final category = map['category'] ?? '';
        final profileData = Map<String, dynamic>.from(map['profileData'] ?? {});
        final city = profileData['city'] ?? '';

        userProfileJson = {
          'category': category,
          'city': city,
          ...profileData,
        };
      }
    } catch (e) {
      debugPrint('Error getting user profile for API: $e');
    }

    final res = await http
        .post(
          Uri.parse('$_base/analyse'),
          headers: await _headers(),
          body: jsonEncode({
            if (text != null) 'text': text,
            if (sourceUrl != null) 'source_url': sourceUrl,
            'language': language,
            if (userProfileJson != null) 'user_profile': userProfileJson,
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

  static Future<void> registerUser({
    required String userId,
    required String category,
    required String name,
    required String email,
    required String phone,
    required String fcmToken,
    required Map<String, dynamic> profileData,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/register'),
          headers: await _headers(),
          body: jsonEncode({
            'user_id': userId,
            'category': category,
            'name': name,
            'email': email,
            'phone': phone,
            'fcm_token': fcmToken,
            'profile_data': profileData,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception(_httpErrorMessage('Register user', res));
    }
  }

  static Future<UserProfileModel?> getUserProfile(String userId) async {
    final res = await http
        .get(Uri.parse('$_base/users/$userId'), headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode == 200) {
      try {
        return UserProfileModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error parsing user profile response: $e');
      }
    }
    return null;
  }

  static Future<void> deleteAccount({String? token}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final effectiveToken = token ?? await AuthService.instance.getIdToken();
    if (effectiveToken != null) {
      headers['Authorization'] = 'Bearer $effectiveToken';
    }

    final res = await http
        .delete(
          Uri.parse('$_base/delete-account'),
          headers: headers,
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception(_httpErrorMessage('Delete account', res));
    }
  }

  static Future<SimulationResult> simulate({
    required int actionIndex,
    String? userId,
    List<String>? notifyChannels,
  }) async {
    Map<String, dynamic>? userProfileJson;
    try {
      final box = Hive.box<dynamic>('user_profile_box');
      final dynamic profileMap = box.get('user_profile');
      if (profileMap != null) {
        final map = Map<String, dynamic>.from(profileMap);
        final category = map['category'] ?? '';
        final profileData = Map<String, dynamic>.from(map['profileData'] ?? {});
        final city = profileData['city'] ?? '';

        userProfileJson = {
          'category': category,
          'city': city,
          ...profileData,
        };
      }
    } catch (e) {
      debugPrint('Error getting user profile for API: $e');
    }

    final body = <String, dynamic>{
      'action_index': actionIndex,
      'scenario': _lastScenario,
      if (userProfileJson != null) 'user_profile': userProfileJson,
    };
    if (userId != null) body['user_id'] = userId;
    if (notifyChannels != null) {
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

  static Future<Map<String, dynamic>> getState() async {
    final res = await http
        .get(Uri.parse('$_base/state'), headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load state');
  }

  static Future<Map<String, dynamic>> updateState(
      Map<String, dynamic> updates) async {
    final res = await http
        .post(
          Uri.parse('$_base/state'),
          headers: await _headers(),
          body: jsonEncode(updates),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update state');
  }
}
