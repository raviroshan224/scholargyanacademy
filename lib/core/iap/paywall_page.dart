import 'package:flutter/material.dart';

import '../constant/app_colors.dart';
import '../widgets/buttons/reusable_buttons.dart';
import 'iap_controller_ios.dart';

class PaywallPage extends StatefulWidget {
  final String productId;
  final IapController iapController;

  const PaywallPage({
    super.key,
    required this.productId,
    required this.iapController,
  });

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  bool _isOwned = false;

  @override
  void initState() {
    super.initState();
    _checkEntitlement();
    widget.iapController.addListener(_onIapChanged);
    
    // Ensure product is added to the controller so it fetches it from the store
    if (!widget.iapController.products.any((p) => p.id == widget.productId)) {
        widget.iapController.setProductIds({widget.productId, ...widget.iapController.products.map((e) => e.id)});
    }
  }

  @override
  void dispose() {
    widget.iapController.removeListener(_onIapChanged);
    super.dispose();
  }

  void _onIapChanged() {
    if (mounted) {
      setState(() {}); // Rebuild on state change
    }
    _checkEntitlement();
  }

  Future<void> _checkEntitlement() async {
    final owned = await widget.iapController.canAccessCourse(widget.productId);
    if (mounted && owned != _isOwned) {
      setState(() {
        _isOwned = owned;
      });
      // If purchased successfully and now owned, pop back with true
      if (owned) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.iapController.isAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text("Enroll")),
        body: const Center(child: Text("Store is unavailable.")),
      );
    }

    final hasProduct = widget.iapController.products.any((p) => p.id == widget.productId);
    if (!hasProduct && widget.iapController.isPurchasing) {
       return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!hasProduct) {
       return Scaffold(
        appBar: AppBar(title: const Text("Enroll")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Product not found in StoreKit."),
              if (widget.iapController.errorMessage != null)
                 Text(widget.iapController.errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          )
        ),
      );
    }

    final product = widget.iapController.products.firstWhere(
      (p) => p.id == widget.productId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Unlock Course", style: TextStyle(color: AppColors.black)),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 80, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  product.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gray600, fontSize: 16),
                ),
                const SizedBox(height: 48),
                if (_isOwned) ...[
                  const Icon(Icons.check_circle, color: AppColors.success, size: 64),
                  const SizedBox(height: 16),
                  const Text("Purchased! You own this course.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ] else ...[
                  ReusableButton(
                    onPressed: () => widget.iapController.buyCourse(product),
                    text: "Buy for ${product.price}",
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => widget.iapController.restorePurchases(),
                    child: const Text("Restore Purchases", style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
                if (widget.iapController.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Text(
                      widget.iapController.errorMessage!,
                      style: const TextStyle(color: AppColors.failure),
                      textAlign: TextAlign.center,
                    ),
                  )
              ],
            ),
          ),
          if (widget.iapController.isPurchasing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
}
