import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'entitlement_store.dart';

class IapController extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  final EntitlementStore _entitlementStore = EntitlementStore();

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // State
  bool isAvailable = false;
  List<ProductDetails> products = [];
  bool isPurchasing = false;
  String? errorMessage;
  
  // List of product IDs you have configured in App Store Connect
  final Set<String> _kProductIds = {
    // Add your exact App Store Connect product IDs here
    // 'course_flutter_beginner',
    // 'course_uiux_masterclass',
  };

  IapController() {
    _initialize();
  }

  // Adds a product ID to the list of known IDs to fetch details for
  void setProductIds(Set<String> ids) {
    _kProductIds.clear();
    _kProductIds.addAll(ids);
    if (isAvailable) {
      _loadProducts();
    }
  }

  Future<void> _initialize() async {
    isAvailable = await _iap.isAvailable();
    if (isAvailable) {
      if (_kProductIds.isNotEmpty) {
        await _loadProducts();
      }
      final purchaseUpdated = _iap.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) {
          errorMessage = error.toString();
          notifyListeners();
        },
      );
    } else {
      errorMessage = "Store is not available.";
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(_kProductIds);
    if (response.error != null) {
      errorMessage = response.error!.message;
    } else {
      products = response.productDetails;
    }
    notifyListeners();
  }

  // Restore purchases behavior
  Future<void> restorePurchases() async {
    errorMessage = null;
    isPurchasing = true;
    notifyListeners();
    try {
      if (Platform.isIOS) {
        await _iap.restorePurchases();
      } else {
        errorMessage = "Restore purchases is only available on iOS in this implementation.";
        isPurchasing = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Failed to restore purchases: $e";
      isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> buyCourse(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    isPurchasing = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      // buy a non-consumable course
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      errorMessage = "Failed to start purchase: $e";
      isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        isPurchasing = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          errorMessage = purchaseDetails.error?.message ?? 'Purchase failed';
        } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // Verify purchase either mock or with backend
          bool isValid = await _verifyPurchase(purchaseDetails);

          if (isValid) {
             // Grant entitlement locally
            await _entitlementStore.grantEntitlement(purchaseDetails.productID);
          } else {
            errorMessage = "Purchase validation failed.";
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          try {
             await _iap.completePurchase(purchaseDetails);
          } catch(e) {
             debugPrint("Error completing purchase: $e");
          }
        }
        
        isPurchasing = false;
      }
    }
    notifyListeners();
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Only accept if in our known list (optional, but good for security)
    if (_kProductIds.isNotEmpty && !_kProductIds.contains(purchaseDetails.productID)) {
      return false;
    }

    String receiptData = "";
    if (purchaseDetails.verificationData.serverVerificationData.isNotEmpty) {
      receiptData = purchaseDetails.verificationData.serverVerificationData;
    }
    
    // Call the mock backend verification which you can update later
    return await _entitlementStore.verifyPurchaseWithBackend(purchaseDetails.productID, receiptData);
  }

  // Gating helper: check locally if owned
  Future<bool> canAccessCourse(String productId) async {
    return _entitlementStore.hasEntitlement(productId);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
