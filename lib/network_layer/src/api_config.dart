import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'middleware.dart';

class ApiConfig {
  late FlutterSecureStorage storage;

  ApiConfig._privateConstructor() {
    storage = const FlutterSecureStorage();
  }

  factory ApiConfig() {
    return _instance ??= ApiConfig._privateConstructor();
  }

  static ApiConfig? _instance;

  String? _authority;

  // Keys for secure storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _appInitializeKey = 'app_initialize';
  static const String _appSplashKey = 'app_splash';
  static const String _fingerprintKey = 'authenticateWithFingerprint';
  static const String _passcodeKey = 'authenticateWithPassCode';
  static const String _faceCodeKey = 'authenticateWithFaceCode';
  static const String _storedPasscodeKey = 'userPasscode';
  static const String _failedAttemptsKey = 'failedAttempts';
  static const String _lockoutStartKey = 'lockout_start';
  static const String _lockoutDurationKey = 'lockout_duration';

  // Existing methods...

  Future<void> setAccessToken({required String value}) async {
    await storage.write(key: _accessTokenKey, value: value);
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: _accessTokenKey);
  }

  void setApiAuthority({required String baseUrl}) {
    _authority = baseUrl;
  }

  Future<void> setRefreshToken({required String refreshToken}) async {
    await storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> setAppInitialize({required bool value}) async {
    await storage.write(key: _appInitializeKey, value: "$value");
  }

  Future<void> setAppSplash({required bool value}) async {
    await storage.write(key: _appSplashKey, value: "$value");
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: _refreshTokenKey);
  }

  String? getApiAuthority() {
    return _authority;
  }

  Future<bool> get isAuthenticated async {
    final token = await storage.read(key: _accessTokenKey);
    if (token != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> get isAppInitialize async {
    try {
      String? isInitialize = await storage.read(key: _appInitializeKey);
      logger.d("app initialize $isInitialize");
      return isInitialize == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<bool> get isSplashInitialize async {
    try {
      String? isInitialize = await storage.read(key: _appSplashKey);
      logger.d("app initialize $isInitialize");
      return isInitialize == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> clearApiConfig() async {
    await storage.deleteAll();
  }

  // Fingerprint methods
  Future<bool> authenticateWithFingerprint() async {
    try {
      final isAuthenticated = await storage.read(key: _fingerprintKey);
      return isAuthenticated == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> setAuthenticateWithFingerprint({required bool value}) async {
    try {
      await storage.write(key: _fingerprintKey, value: "$value");
    } catch (e) {
      logger.d("error in setAuthenticateWithFingerprint");
    }
  }

  // Passcode methods
  Future<bool> authenticateWithPassCode() async {
    try {
      final isAuthenticated = await storage.read(key: _passcodeKey);
      return isAuthenticated == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> setAuthenticateWithPassCode({required bool value}) async {
    try {
      await storage.write(key: _passcodeKey, value: "$value");
    } catch (e) {
      logger.d("error in setAuthenticateWithPassCode");
    }
  }

  Future<void> setPasscode({required String passcode}) async {
    try {
      await storage.write(key: _storedPasscodeKey, value: passcode);
    } catch (e) {
      logger.d("error in setPasscode");
    }
  }

  Future<String?> getPasscode() async {
    try {
      return await storage.read(key: _storedPasscodeKey);
    } catch (e) {
      return null;
    }
  }

  // Face ID methods
  Future<bool> authenticateWithFaceCode() async {
    try {
      final isAuthenticated = await storage.read(key: _faceCodeKey);
      return isAuthenticated == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> setAuthenticateWithFaceCode({required bool value}) async {
    try {
      await storage.write(key: _faceCodeKey, value: "$value");
    } catch (e) {
      logger.d("error in setAuthenticateWithFaceCode");
    }
  }

  // Failed attempts and lockout logic
  Future<int> incrementFailedAttempts() async {
    try {
      final attempts = await storage.read(key: _failedAttemptsKey);
      int currentAttempts = int.tryParse(attempts ?? '0') ?? 0;
      currentAttempts++;
      await storage.write(key: _failedAttemptsKey, value: '$currentAttempts');
      logger.d("Failed attempts incremented to: $currentAttempts");
      return currentAttempts;
    } catch (e) {
      return 0;
    }
  }

  Future<int> incrementFailedAttemptsWithoutStorage() async {
    try {
      int currentAttempts = await getFailedAttempts();
      currentAttempts++;
      await storage.write(key: _failedAttemptsKey, value: '$currentAttempts');
      logger.d("Failed attempts incremented to: $currentAttempts");
      return currentAttempts;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getFailedAttempts() async {
    try {
      final attempts = await storage.read(key: _failedAttemptsKey);
      return int.tryParse(attempts ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> resetFailedAttempts() async {
    try {
      await storage.write(key: _failedAttemptsKey, value: '0');
      logger.d("Failed attempts reset");
    } catch (e) {
      logger.d("error in resetFailedAttempts");
    }
  }

  // Set a lockout with a specified duration
  Future<void> setLockout(Duration duration) async {
    try {
      final lockoutStart = DateTime.now().millisecondsSinceEpoch;
      final lockoutDurationMs = duration.inMilliseconds;

      await storage.write(
          key: _lockoutStartKey, value: lockoutStart.toString());
      await storage.write(
          key: _lockoutDurationKey, value: lockoutDurationMs.toString());
      logger.d(
          "Lockout set: Start at $lockoutStart, Duration: $lockoutDurationMs ms");
    } catch (e) {
      logger.d("error in setLockout");
    }
  }

  // Check if the app is currently locked out
  Future<bool> isLockedOut() async {
    try {
      final lockoutStartStr = await storage.read(key: _lockoutStartKey);
      final lockoutDurationStr = await storage.read(key: _lockoutDurationKey);

      if (lockoutStartStr == null || lockoutDurationStr == null) {
        return false;
      }

      final lockoutStart = int.tryParse(lockoutStartStr) ?? 0;
      final lockoutDuration = int.tryParse(lockoutDurationStr) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final lockoutEnd = lockoutStart + lockoutDuration;

      if (now < lockoutEnd) {
        logger.d("Still locked out. Now: $now, End: $lockoutEnd");
        return true;
      } else {
        // Lockout expired, clear data
        await storage.delete(key: _lockoutStartKey);
        await storage.delete(key: _lockoutDurationKey);
        await resetFailedAttempts();
        logger.d("Lockout expired, cleared");
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get the remaining lockout time in seconds
  Future<int> getRemainingLockoutSeconds() async {
    final lockoutStartStr = await storage.read(key: _lockoutStartKey);
    final lockoutDurationStr = await storage.read(key: _lockoutDurationKey);

    if (lockoutStartStr == null || lockoutDurationStr == null) {
      return 0;
    }

    final lockoutStart = int.tryParse(lockoutStartStr) ?? 0;
    final lockoutDuration = int.tryParse(lockoutDurationStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lockoutEnd = lockoutStart + lockoutDuration;
    final remainingMs = lockoutEnd - now;

    if (remainingMs <= 0) {
      // Clear lockout data if expired
      await storage.delete(key: _lockoutStartKey);
      await storage.delete(key: _lockoutDurationKey);
      await resetFailedAttempts();
      logger.d("Lockout expired, cleared");
      return 0;
    }

    final remainingSeconds = (remainingMs / 1000).ceil();
    logger.d("Remaining lockout seconds: $remainingSeconds");
    return remainingSeconds;
  }

// Remove outdated method (setLockoutTimestamp)
// Future<void> setLockoutTimestamp() async {
//   final lockoutTime =
//       DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
//   await storage.write(key: _lockoutTimestampKey, value: '$lockoutTime');
// }
}
