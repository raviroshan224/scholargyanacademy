import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntitlementStore {
  static const String _purchasedKey = 'purchased_courses';

  Future<List<String>> getPurchasedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_purchasedKey) ?? [];
  }

  // --- MOCK BACKEND BEHAVIOR ---
  // In a real application, you would send the product ID and the receipt data 
  // (from the App Store) to your backend for validation.
  // Then the backend would grant the entitlement in its database.
  Future<bool> verifyPurchaseWithBackend(String productId, String receiptData) async {
    // TODO: Send receiptData to backend endpoint once it's available.
    // Example:
    // final response = await api.post('/verify-receipt', data: {'productId': productId, 'receipt': receiptData});
    // return response.statusCode == 200;
    
    debugPrint("Mocking backend verification for product: $productId");
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return true; // Assume valid for now
  }

  Future<void> grantEntitlement(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = await getPurchasedCourses();
    
    if (!owned.contains(productId)) {
      owned.add(productId);
      await prefs.setStringList(_purchasedKey, owned);
      debugPrint("Granted entitlement for: $productId");
    }
  }

  Future<bool> hasEntitlement(String productId) async {
    final owned = await getPurchasedCourses();
    return owned.contains(productId);
  }
}
