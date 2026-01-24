import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> write(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _secureStorage.read(key: key);
  }

  Future<void> delete(String key) {
    return _secureStorage.delete(key: key);
  }

  Future<void> deleteAll() {
    return _secureStorage.deleteAll();
  }
}
