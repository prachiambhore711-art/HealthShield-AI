import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _pinKey = "app_lock_pin";
  static const String _biometricsKey = "app_lock_biometrics_enabled";
  static const String _enabledKey = "app_lock_enabled";

  // In-memory session unlock state. When app is closed/resumed, locks sensitive views.
  static bool isUnlockedThisSession = false;

  /// Check if an app PIN has been set
  static Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.trim().length == 4;
  }

  /// Check if app lock is active
  static Future<bool> isLockEnabled() async {
    final enabled = await _storage.read(key: _enabledKey);
    final hasPin = await isPinSet();
    return enabled == "true" && hasPin;
  }

  /// Check if biometric authentication is enabled by the user
  static Future<bool> isBiometricsEnabled() async {
    final enabled = await _storage.read(key: _biometricsKey);
    return enabled == "true";
  }

  /// Set or update the 4-digit PIN
  static Future<void> setPin(String pin) async {
    if (pin.trim().length != 4) {
      throw ArgumentError("PIN must be exactly 4 digits");
    }
    await _storage.write(key: _pinKey, value: pin.trim());
    await _storage.write(key: _enabledKey, value: "true");
    isUnlockedThisSession = true;
  }

  /// Set biometrics toggle
  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsKey, value: enabled ? "true" : "false");
  }

  /// Verify entered PIN against secure storage
  static Future<bool> verifyPin(String enteredPin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    final success = stored.trim() == enteredPin.trim();
    if (success) {
      isUnlockedThisSession = true;
    }
    return success;
  }

  /// Remove PIN and disable lock
  static Future<void> disableLock() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _enabledKey, value: "false");
    await _storage.delete(key: _biometricsKey);
    isUnlockedThisSession = false;
  }

  /// Check if hardware supports biometrics
  static Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Authenticate using device biometrics (fingerprint/face)
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access private health records',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        isUnlockedThisSession = true;
      }
      return authenticated;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Lock current active session
  static void lockSession() {
    isUnlockedThisSession = false;
  }
}
