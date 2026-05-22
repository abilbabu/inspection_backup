import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CustomShimmerLoader extends StatelessWidget {
  final bool isLoading;

  const CustomShimmerLoader({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Shimmer(
        duration: const Duration(seconds: 2),
        interval: const Duration(milliseconds: 300),
        color: Colors.white,
        colorOpacity: 0.3,
        enabled: true,
        direction: const ShimmerDirection.fromLTRB(),
        child: Column(
          children: List.generate(4, (index) {
            return Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade300,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 30,
                    width: 150,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 20,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Container(height: 20, width: 200, color: Colors.grey),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
