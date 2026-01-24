import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_keys.dart';
import 'local_data_source.dart';

class HiveDataSource extends LocalDataSource {
  // Singleton pattern
  static final HiveDataSource _instance = HiveDataSource._internal();

  HiveDataSource._internal(); // Private constructor

  factory HiveDataSource() => _instance;

  // Box? _authBox; // Add this cache
  LazyBox? _authBox; // Add this cache

  Future<LazyBox> openBox(String boxName) async {
    if (_authBox != null && _authBox!.isOpen) {
      return _authBox!;
    }

    try {
      _authBox = await Hive.openLazyBox(boxName);
      log('📦 LazyBox opened successfully: $boxName');
      return _authBox!;
    } catch (e) {
      log('❌ Error opening LazyBox: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAccessToken() async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      await hiveAuthBox.delete(HIVE_TOKEN_KEY);
    } catch (e) {}
  }

  @override
  Future<bool> isFirstInstalled() async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      final result = await hiveAuthBox.get(HIVE_STATUS_KEY);
      return result ?? true;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> updateFirstInstalled(bool value) async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      await hiveAuthBox.put(HIVE_STATUS_KEY, value);
      return await isFirstInstalled();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> updateAccessToken(String token) async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      await hiveAuthBox.put(HIVE_TOKEN_KEY, token);
      return await getAccessToken();
    } catch (e) {
      return '';
    }
  }

  Future<String> setUserId(String userId) async {
    try {
      if (userId.isEmpty) {
        print('Error: User ID is empty');
        return '';
      }
      final hiveProfileBox = await openBox(HIVE_PROFILE_BOX);
      await hiveProfileBox.put(HIVE_PROFILE_KEY, userId);
      return 'User ID updated successfully';
    } catch (e) {
      print('Error updating user ID: $e');
      return '';
    }
  }

  Future<String?> getUserId() async {
    try {
      final hiveProfileBox = await openBox(HIVE_PROFILE_BOX);
      final userId = await hiveProfileBox.get(HIVE_PROFILE_KEY);
      return userId;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> getAccessToken() async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      final result = await hiveAuthBox.get(HIVE_TOKEN_KEY);

      log("Access token Get :  ${result ?? ''}");
      return result ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      await hiveAuthBox.delete(HIVE_REFRESH_TOKEN_KEY);
    } catch (e) {}
  }

  @override
  Future<String> getRefreshToken() async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      final result = await hiveAuthBox.get(HIVE_REFRESH_TOKEN_KEY);

      return result ?? '';
    } catch (e) {
      return '';
    }
  }

  @override
  Future<String> updateRefreshToken(String token) async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      await hiveAuthBox.put(HIVE_REFRESH_TOKEN_KEY, token);
      return await getRefreshToken();
    } catch (e) {
      return '';
    }
  }

  // New methods for token expiration
  Future<void> setTokenExpiration(String expirationTime) async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      await hiveAuthBox.put(HIVE_TOKEN_EXPIRATION_KEY, expirationTime);
    } catch (e) {}
  }

  Future<String?> getTokenExpiration() async {
    try {
      final hiveAuthBox = await openBox(HIVE_TOKEN_BOX);
      return await hiveAuthBox.get(HIVE_TOKEN_EXPIRATION_KEY);
    } catch (e) {
      return null;
    }
  }

  // New method to clear all data in the Hive box
  Future<void> clearAll() async {
    try {
      await clearRefreshToken();
      await clearAccessToken();
      log('📦 All data cleared ');
    } catch (e) {
      log('❌ Error clearing Hive box: $e');
    }
  }

  @override
  Future<void> clearDb() {
    // TODO: implement clearDb
    throw UnimplementedError();
  }
}
