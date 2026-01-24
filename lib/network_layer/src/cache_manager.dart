import 'package:flutter/foundation.dart';

class OptimizedStateManager extends ChangeNotifier {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};

  Future<T> loadWithCache<T>(
    String key,
    Future<T> Function() loader, {
    Duration expiry = const Duration(minutes: 5),
  }) async {
    // Check if cached data exists & is still valid
    if (_cache.containsKey(key) &&
        _cacheExpiry.containsKey(key) &&
        DateTime.now().isBefore(_cacheExpiry[key]!)) {
      return _cache[key] as T;
    }

    // Fetch fresh data
    final result = await loader();
    _cache[key] = result;
    _cacheExpiry[key] = DateTime.now().add(expiry);
    notifyListeners();
    return result;
  }

  void clearCache() {
    _cache.clear();
    _cacheExpiry.clear();
    notifyListeners();
  }

  void clearExpiredCache() {
    final now = DateTime.now();
    _cacheExpiry.removeWhere((key, expiry) => expiry.isBefore(now));
    _cache.removeWhere((key, _) => !_cacheExpiry.containsKey(key));
  }
}
