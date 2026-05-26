import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

/// A shimmer-style skeleton placeholder shown while AI results are loading.
/// Mimics the shape of FoodItemCard so the layout doesn't jump.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmer(height: 10, width: 60, radius: 6),
                      const SizedBox(height: 14),
                      _shimmer(height: 18, width: double.infinity, radius: 8),
                      const SizedBox(height: 8),
                      _shimmer(height: 13, width: 140, radius: 6),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _shimmer(height: 18, width: 70, radius: 6),
                          const Spacer(),
                          _shimmer(height: 26, width: 60, radius: 10),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _shimmer(height: 100, width: 100, radius: 16),
              ],
            ),
          ),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24)),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.5),
        );
  }

  Widget _shimmer({
    required double height,
    required double width,
    required double radius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
