import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kLoggedIn = 'session_logged_in';
  static const _kMethod = 'session_method';
  static const _kIdentifier = 'session_identifier';
  static const _kUid = 'session_uid';

  static SharedPreferences? _prefs;

  static bool wasLoggedIn = false;
  static String method = '';
  static String identifier = '';

  /// Call once in main() before runApp.
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      wasLoggedIn = _prefs!.getBool(_kLoggedIn) ?? false;
      method = _prefs!.getString(_kMethod) ?? '';
      identifier = _prefs!.getString(_kIdentifier) ?? '';
    } catch (e) {
      debugPrint('session init failed: $e');
    }
  }

  static Future<void> save(User u) async {
    final isPhone = (u.phoneNumber ?? '').isNotEmpty;
    wasLoggedIn = true;
    method = isPhone ? 'phone' : 'email';
    identifier = isPhone ? u.phoneNumber! : (u.email ?? '');
    try {
      final p = _prefs ??= await SharedPreferences.getInstance();
      await p.setBool(_kLoggedIn, true);
      await p.setString(_kMethod, method);
      await p.setString(_kIdentifier, identifier);
      await p.setString(_kUid, u.uid);
    } catch (e) {
      debugPrint('session save failed: $e');
    }
  }

  static Future<void> clear() async {
    wasLoggedIn = false;
    method = '';
    identifier = '';
    try {
      final p = _prefs ??= await SharedPreferences.getInstance();
      await p.remove(_kLoggedIn);
      await p.remove(_kMethod);
      await p.remove(_kIdentifier);
      await p.remove(_kUid);
    } catch (e) {
      debugPrint('session clear failed: $e');
    }
  }
}
