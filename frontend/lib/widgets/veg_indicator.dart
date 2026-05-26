import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Green square (veg) or red square (non-veg) indicator
class VegIndicator extends StatelessWidget {
  final bool? isVeg;
  final double size;

  const VegIndicator({super.key, this.isVeg, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (isVeg == null) return const SizedBox.shrink();
    final color = isVeg! ? AppTheme.vegGreen : AppTheme.nonVegRed;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          width: size * 0.45,
          height: size * 0.45,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
