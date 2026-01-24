import 'package:flutter/material.dart';
import 'package:scholarsgyanacademy/core/widgets/shimmer/reusable_shimmer_widget.dart';

class LoadingListView extends StatelessWidget {
  const LoadingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shimmer Example')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                // Shimmer for image
                ShimmerLoading(
                  height: 60,
                  width: 60,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                SizedBox(width: 16),
                // Shimmer for text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(height: 16, width: 200),
                    SizedBox(height: 8),
                    ShimmerLoading(height: 16, width: 150),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
