import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/execution_notification.dart';

class AlertStore extends ChangeNotifier {
  AlertStore._();
  static final AlertStore instance = AlertStore._();

  static const _executionsKey = 'tadbeer_execution_alerts';
  static const _readMarketKey = 'tadbeer_market_read_ids';

  List<ExecutionNotification> _executions = [];
  Set<String> _readMarketIds = {};
  String _currentUid = 'guest';

  List<ExecutionNotification> get executions => List.unmodifiable(_executions);
  Set<String> get readMarketIds => Set.unmodifiable(_readMarketIds);

  int get executionUnreadCount =>
      _executions.where((e) => !e.read).length;

  Future<void> initialize() async {
    await updateCurrentUser();
  }

  Future<void> updateCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';
    _currentUid = uid;
    await _loadExecutions();
    await _loadMarketRead();
    notifyListeners();

    if (_currentUid != 'guest') {
      _syncWithFirestore(_currentUid);
    }
  }

  Future<void> _syncWithFirestore(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('execution_alerts')
          .get();

      final firestoreNotifications = snapshot.docs
          .map((doc) => ExecutionNotification.fromJson(doc.data()))
          .toList();

      final merged = <String, ExecutionNotification>{};
      for (final n in _executions) {
        merged[n.id] = n;
      }
      for (final n in firestoreNotifications) {
        if (merged.containsKey(n.id)) {
          final isRead = merged[n.id]!.read || n.read;
          merged[n.id] = n.copyWith(read: isRead);
        } else {
          merged[n.id] = n;
        }
      }

      _executions = merged.values.toList();
      _executions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _persistExecutions();
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore sync failed: $e');
    }
  }

  Future<void> _loadExecutions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_executionsKey}_$_currentUid';
      final raw = prefs.getString(key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _executions = list
            .map((e) =>
                ExecutionNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        _executions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _executions = [];
      }
    } catch (e) {
      debugPrint('Load executions failed: $e');
      _executions = [];
    }
  }

  Future<void> _persistExecutions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_executionsKey}_$_currentUid';
      await prefs.setString(
        key,
        jsonEncode(_executions.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Persist executions failed: $e');
    }
  }

  Future<void> _loadMarketRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_readMarketKey}_$_currentUid';
      final raw = prefs.getStringList(key);
      _readMarketIds = raw?.toSet() ?? {};
    } catch (_) {
      _readMarketIds = {};
    }
  }

  Future<void> _persistMarketRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_readMarketKey}_$_currentUid';
      await prefs.setStringList(key, _readMarketIds.toList());
    } catch (_) {}
  }

  Future<void> addExecution(ExecutionNotification notification) async {
    _executions.insert(0, notification);
    await _persistExecutions();
    notifyListeners();
  }

  Future<void> markExecutionRead(String id) async {
    final idx = _executions.indexWhere((e) => e.id == id);
    if (idx < 0 || _executions[idx].read) return;
    _executions[idx] = _executions[idx].copyWith(read: true);
    await _persistExecutions();
    notifyListeners();
  }

  Future<void> markAllExecutionsRead() async {
    _executions =
        _executions.map((e) => e.copyWith(read: true)).toList();
    await _persistExecutions();
    notifyListeners();
  }

  Future<void> markMarketRead(String id) async {
    _readMarketIds.add(id);
    await _persistMarketRead();
    notifyListeners();
  }

  Future<void> markAllMarketRead(Iterable<String> ids) async {
    _readMarketIds.addAll(ids);
    await _persistMarketRead();
    notifyListeners();
  }

  int marketUnreadCount(Iterable<String> alertIds) =>
      alertIds.where((id) => !_readMarketIds.contains(id)).length;
}
