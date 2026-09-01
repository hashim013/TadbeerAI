import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'user_profile_service.dart';
import 'alert_store.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  User? _user;
  User? get user => _user;

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  bool get isAuthenticated => _user != null || _isGuest;
  bool get isRegisteredUser => _user != null && !_isGuest;

  Future<void> initialize() async {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _user = user;
        if (user != null) _isGuest = false;
        AlertStore.instance.updateCurrentUser();
        notifyListeners();
      });
    } catch (e) {
      debugPrint(
          'Firebase not fully configured, falling back to mock mode: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-in failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Email sign-in failed: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-up failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Email sign-up failed: $e');
      return false;
    }
  }

  Future<void> signInAsGuest() async {
    _isGuest = true;
    await AlertStore.instance.updateCurrentUser();
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _user = null;
    _isGuest = false;
    UserProfileService.instance.clearCache();
    await AlertStore.instance.updateCurrentUser();
    notifyListeners();
  }

  Future<String?> getIdToken() async {
    try {
      return await _user?.getIdToken();
    } catch (_) {
      return null;
    }
  }
}
