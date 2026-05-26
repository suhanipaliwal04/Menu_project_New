import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// Color-coded health score badge (1-10 scale from RAG endpoint)
class HealthBadge extends StatelessWidget {
  final int? score;
  final String? label;

  const HealthBadge({super.key, this.score, this.label});

  Color get _color {
    if (score != null) return AppTheme.healthColor(score);
    return AppTheme.healthLabelColor(label);
  }

  String get _text {
    if (score != null) return '♥ $score/10';
    if (label != null) return label![0].toUpperCase() + label!.substring(1);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _text,
        style: GoogleFonts.outfit(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
