import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/voice_agent_provider.dart';
import '../screens/voice_agent_screen.dart';

class VoiceFab extends StatelessWidget {
  const VoiceFab({super.key});

  void _showVoiceSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceAgentScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceAgentProvider>(
      builder: (context, vp, _) {
        return GestureDetector(
          onTap: () => _showVoiceSearch(context),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFFE0873A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.06, duration: 1500.ms, curve: Curves.easeInOut),
        );
      },
    );
  }
}
