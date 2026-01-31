import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../../courses/view_model/course_view_model.dart';

class HomeCourseCard extends ConsumerWidget {
  const HomeCourseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.courseId,
    this.isSaved = false,
    this.enrollmentCost,
    this.discountedPrice,
    this.hasOffer,
    this.durationHours,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final String? courseId;
  final bool isSaved;
  final int? enrollmentCost;
  final int? discountedPrice;
  final bool? hasOffer;
  final int? durationHours;

  // static const double _width = 160;
  static const double _width = 160;
  static const double _height = 256;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFree = enrollmentCost == 0;
    final bool hasValidDiscount = hasOffer == true &&
        enrollmentCost != null &&
        discountedPrice != null &&
        enrollmentCost! > discountedPrice!;

    return SizedBox(
      width: _width,
      height: _height,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray600.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: CustomCachedNetworkImage(
                      imageUrl: imagePath,
                      fitStatus: BoxFit.cover,
                      errorImage: AppAssets.errorImage,
                    ),
                  ),
                ),
                if (hasValidDiscount)
                  _badge('${_discount()}% OFF', const Color(0xFFEA4335)),
                if (isFree) _badge('FREE', const Color(0xFF0F9D58)),
                if (courseId != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _bookmark(ref, context),
                  ),
              ],
            ),

            /// CONTENT
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 36,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        durationHours != null && durationHours! > 0
                            ? '$durationHours hrs'
                            : 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _price(isFree, hasValidDiscount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- HELPERS ----------

  Widget _badge(String text, Color color) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _bookmark(WidgetRef ref, BuildContext context) {
    return GestureDetector(
      onTap: courseId == null
          ? null
          : () async {
              await ref
                  .read(coursesViewModelProvider.notifier)
                  .toggleSave(courseId!, currentlySaved: isSaved);
            },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          size: 18,
          color: isSaved ? AppColors.primary : AppColors.gray600,
        ),
      ),
    );
  }

  Widget _price(bool isFree, bool hasDiscount) {
    if (isFree) {
      return const Text(
        'Free',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F9D58),
        ),
      );
    }

    if (hasDiscount) {
      return Row(
        children: [
          Text(
            'Rs ${NumberFormat('#,##,###').format(discountedPrice)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            'Rs ${NumberFormat('#,##,###').format(enrollmentCost)}',
            style: const TextStyle(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }

    if (enrollmentCost != null) {
      return Text(
        'Rs ${NumberFormat('#,##,###').format(enrollmentCost)}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      );
    }

    return const SizedBox.shrink();
  }

  int _discount() {
    if (enrollmentCost == null ||
        discountedPrice == null ||
        enrollmentCost == 0) return 0;
    return (((enrollmentCost! - discountedPrice!) / enrollmentCost!) * 100)
        .round();
  }
}
