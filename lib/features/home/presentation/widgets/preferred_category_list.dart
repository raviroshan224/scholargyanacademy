import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../models/homepage_models.dart' as home_models;
import '../../../explore/presentation/pages/explore_page.dart';

class PreferredCategoryList extends StatelessWidget {
  const PreferredCategoryList({
    super.key,
    required this.categories,
    this.isLoading = false,
  });

  final List<home_models.Category> categories;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => _ShimmerCard(),
        ),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryCard(
            category: category,
            index: index,
          );
        },
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // gradient: LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: [
            //     AppColors.gray100,
            //     AppColors.gray100,
            //     AppColors.gray100,
            //   ],
            //   stops: [
            //     _controller.value - 0.3,
            //     _controller.value,
            //     _controller.value + 0.3,
            //   ].map((e) => e.clamp(0.0, 1.0)).toList(),
            // ),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.index,
  });

  final home_models.Category category;
  final int index;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        if (widget.category.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExplorePage(
                initialCategoryId: widget.category.id,
              ),
            ),
          );
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 100, // Fixed small width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? Colors.black.withOpacity(0.04)
                    : Colors.black.withOpacity(0.02),
                blurRadius: _isPressed ? 8 : 12,
                offset: _isPressed ? const Offset(0, 2) : const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CustomCachedNetworkImage(
                    imageUrl: widget.category.categoryImageUrl ??
                        AppAssets.dummyNetImg,
                    fitStatus: BoxFit.contain, // Maintain contain for icons
                  ),
                ),
              ),

              // Text Section
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.gray100, // Subtle contrast
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.category.categoryName ?? 'Category',
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
