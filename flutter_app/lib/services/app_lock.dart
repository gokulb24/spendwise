import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the "unlock with fingerprint / PIN" gate.
class AppLock extends ChangeNotifier {
  static const _key = 'appLockEnabled';
  final LocalAuthentication _auth = LocalAuthentication();

  bool _enabled = false;
  bool _unlocked = true; // true = app contents visible
  bool _authInProgress = false;

  bool get enabled => _enabled;
  bool get locked => _enabled && !_unlocked;

  /// Load the saved preference at startup and lock immediately if enabled.
  Future<void> load() async {
    try {
      _enabled =
          (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {
      _enabled = false;
    }
    _unlocked = !_enabled;
    notifyListeners();
  }

  /// Whether this device can actually do biometric/credential auth.
  Future<bool> deviceCanAuthenticate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) _unlocked = true; // turning off unlocks
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, value);
    } catch (_) {}
  }

  /// Called when the app resumes from the background — re-lock.
  void relockIfEnabled() {
    if (_enabled && _unlocked) {
      _unlocked = false;
      notifyListeners();
    }
  }

  /// Prompt for fingerprint / device PIN. Returns true on success.
  Future<bool> authenticate() async {
    if (!_enabled) return true;
    if (_authInProgress) return false;
    _authInProgress = true;
    try {
      // If the device has no secure lock at all, don't trap the user out.
      if (!await deviceCanAuthenticate()) {
        _unlocked = true;
        notifyListeners();
        return true;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock SpendWise',
        biometricOnly: false, // allow PIN / password fallback
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        _unlocked = true;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      _authInProgress = false;
    }
  }
}
