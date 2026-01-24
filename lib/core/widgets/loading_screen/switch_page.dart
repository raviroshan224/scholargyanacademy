import 'package:flutter/material.dart';
import '../../../core/widgets/shimmer/reusable_shimmer_widget.dart';

class SimulatedLoadingScreen extends StatefulWidget {
  const SimulatedLoadingScreen({super.key});

  @override
  _SimulatedLoadingScreenState createState() => _SimulatedLoadingScreenState();
}

class _SimulatedLoadingScreenState extends State<SimulatedLoadingScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate a network call
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Shimmer Demo'),
        ),
        body: isLoading
            ? ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => const Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ShimmerLoading(height: 16, width: double.infinity),
                ),
              )
            : Center(
                child: Text(
                  'Data Loaded!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ));
  }
}
