import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  static const _prefsKey = 'tadbeer_user_profile';
  UserProfile? _cached;

  UserProfile? get current => _cached;

  Future<UserProfile?> loadProfile(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['uid'] = uid;
        _cached = UserProfile.fromJson(data);
        await _saveLocal(_cached!);
        return _cached;
      }
    } catch (e) {
      debugPrint('Firestore profile load failed: $e');
    }
    return _loadLocal(uid);
  }

  Future<UserProfile?> _loadLocal(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsKey:$uid');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _cached = UserProfile.fromJson(data);
        return _cached;
      }
    } catch (e) {
      debugPrint('Local profile load failed: $e');
    }
    return null;
  }

  Future<void> _saveLocal(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefsKey:${profile.uid}',
        jsonEncode(profile.toJson()),
      );
    } catch (_) {}
  }

  Future<UserProfile> getOrCreateFromAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    final existing = await loadProfile(user.uid);
    if (existing != null) return existing;

    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      phone: user.phoneNumber ?? '',
      profileComplete: false,
    );
    _cached = profile;
    await saveProfile(profile);
    return profile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    _cached = profile;
    await _saveLocal(profile);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore profile save failed: $e');
    }
  }

  Future<void> updateFcmToken(String uid, String token) async {
    final profile = _cached ?? await loadProfile(uid);
    if (profile == null) return;
    await saveProfile(profile.copyWith(fcmToken: token));
  }

  void clearCache() => _cached = null;
}
