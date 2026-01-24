import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../../../core/core.dart';

class PriceState {
  final double taxableAmount;
  final double vatAmount;
  final double totalAmount;

  PriceState({
    this.taxableAmount = 0.0,
    this.vatAmount = 0.0,
    this.totalAmount = 0.0,
  });

  PriceState copyWith({
    double? taxableAmount,
    double? vatAmount,
    double? totalAmount,
  }) {
    return PriceState(
      taxableAmount: taxableAmount ?? this.taxableAmount,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  factory PriceState.initial() => PriceState();
}

class PriceNotifier extends StateNotifier<PriceState> {
  PriceNotifier() : super(PriceState.initial()) {
    calculatePrice(4000);
  }

  void calculatePrice(double total) {
    final taxable = total / 1.13;
    final vat = total - taxable;

    state = state.copyWith(
      taxableAmount: taxable,
      vatAmount: vat,
      totalAmount: total,
    );
  }
}

final priceProvider =
    StateNotifierProvider<PriceNotifier, PriceState>((Ref ref) {
  return PriceNotifier();
});

class PriceSectionWidget extends ConsumerWidget {
  const PriceSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceState = ref.watch(priceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CText('Price', type: TextType.bodyLarge, color: AppColors.black),
        const Divider(thickness: 1),
        AppSpacing.verticalSpaceSmall,
        _buildPriceRow(
          'Taxable amount',
          priceState.taxableAmount,
          AppColors.gray600,
        ),
        AppSpacing.verticalSpaceMedium,
        _buildPriceRow(
          'Vat amount (13.0%)',
          priceState.vatAmount,
          AppColors.gray600,
        ),
        const Divider(thickness: 1),
        AppSpacing.verticalSpaceSmall,
        _buildPriceRow(
          'Total amount',
          priceState.totalAmount,
          AppColors.black,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CText(label, type: TextType.bodySmall, color: color),
        CText(
          'Rs. ${amount.toStringAsFixed(1)}',
          type: TextType.bodySmall,
          color: color,
        ),
      ],
    );
  }
}
