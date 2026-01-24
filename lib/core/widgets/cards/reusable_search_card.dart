import 'package:flutter/material.dart';
import '../../constant/app_colors.dart';
import '../../utils/ui_helper/app_spacing.dart';
import '../text/custom_text.dart';

class ReusableSearchCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const ReusableSearchCard({
    super.key,
    required this.text,
    required this.icon,
    this.iconColor = Colors.grey,
    required this.onTap,
  });

  @override
  _ReusableSearchCardState createState() => _ReusableSearchCardState();
}

class _ReusableSearchCardState extends State<ReusableSearchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Card(
                elevation: 4.0,
                surfaceTintColor: AppColors.gray300,
                color: AppColors.gray300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  side: const BorderSide(width: 2.0, color: AppColors.gray300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: widget.iconColor),
                      AppSpacing.horizontalSpaceSmall,
                      Expanded(
                        child: Row(
                          children: [
                            CText(
                              widget.text,
                              type: TextType.bodyLarge,
                            ),
                            AppSpacing.horizontalSpaceSmall,
                            _buildCursor(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCursor() {
    return FadeTransition(
      opacity: _cursorController,
      child: Container(
        width: 2,
        height: 20,
        color: Colors.black,
      ),
    );
  }
}
