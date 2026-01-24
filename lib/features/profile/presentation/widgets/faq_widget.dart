import 'package:flutter/material.dart';
import '../../../../core/core.dart';

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String content;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: CText(widget.title, type: TextType.bodyLarge, color: AppColors.black),
        trailing: Icon(
          isExpanded ? Icons.remove : Icons.add,
          color: isExpanded ? AppColors.gray600 : AppColors.black,
        ),
        onExpansionChanged: (expanded) {
          setState(() => isExpanded = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CText(widget.content, type: TextType.bodyMedium, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}