import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents an authenticated Google user profile.
class GoogleUserProfile {
  final String name;
  final String email;
  final String? avatarUrl;

  const GoogleUserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
  });
}

/// Singleton authentication service managing user session & persistence.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  GoogleUserProfile? _currentUser;
  GoogleUserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  static const String _keyEmail = 'auth_google_email';
  static const String _keyName = 'auth_google_name';

  /// Initialize and restore any persisted session from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_keyEmail);
      final name = prefs.getString(_keyName);
      if (email != null && email.isNotEmpty) {
        _currentUser = GoogleUserProfile(
          name: (name != null && name.isNotEmpty)
              ? name
              : deriveNameFromEmail(email),
          email: email,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Sign in with a Google account email and optional display name.
  Future<void> signInWithGoogle({required String email, String? name}) async {
    final cleanEmail = email.trim();
    final displayName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : deriveNameFromEmail(cleanEmail);

    _currentUser = GoogleUserProfile(
      name: displayName,
      email: cleanEmail,
    );
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmail, cleanEmail);
      await prefs.setString(_keyName, displayName);
    } catch (_) {}
  }

  /// Sign out and clear stored credentials.
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyName);
    } catch (_) {}
  }

  /// Derive a friendly clinical display name from an email address.
  static String deriveNameFromEmail(String email) {
    if (!email.contains('@')) return 'Google User';
    final handle = email.split('@').first;
    final cleaned = handle.replaceAll(RegExp(r'[._\-]'), ' ').trim();
    if (cleaned.isEmpty) return 'Google User';
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
