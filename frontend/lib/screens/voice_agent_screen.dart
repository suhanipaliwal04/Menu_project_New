import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/voice_agent_provider.dart';
import '../services/voice_action_handler.dart';
import 'results_screen.dart';
import 'cart_screen.dart';
import 'table_booking_screen.dart';
import 'takeaway_screen.dart';

/// Immersive fullscreen Voice AI Agent overlay.
/// Slides up from bottom. Tap mic to start/stop.
class VoiceAgentScreen extends StatefulWidget {
  const VoiceAgentScreen({super.key});

  @override
  State<VoiceAgentScreen> createState() => _VoiceAgentScreenState();
}

class _VoiceAgentScreenState extends State<VoiceAgentScreen>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _waveController;
  late VoiceAgentProvider _vp;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Init voice agent
    _vp = context.read<VoiceAgentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vp.onActionTriggered = _handleActionFromProvider;
      _vp.init();
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _waveController.dispose();
    _vp.onActionTriggered = null;
    super.dispose();
  }

  void _handleActionFromProvider(VoiceAction action) {
    if (mounted) {
      _handleAction(action, _vp);
    }
  }

  // ── Entry Point: tap mic button ───────────────────────────────────────────
  Future<void> _handleMicTap() async {
    final provider = context.read<VoiceAgentProvider>();
    await provider.toggleListening();
  }

  Future<void> _handleAction(VoiceAction action, VoiceAgentProvider vp) async {
    if (!mounted) return;
    switch (action.type) {
      case VoiceActionType.search:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ResultsScreen()));
        break;
      case VoiceActionType.placeOrder:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CartScreen()));
        break;
      case VoiceActionType.bookTable:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TableBookingScreen(
              restaurantName: vp.currentRestaurantName,
              timeSlot: action.params['time'] as String? ?? '',
            ),
          ),
        );
        break;
      case VoiceActionType.scheduleTakeaway:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TakeawayScreen(
              restaurantName: vp.currentRestaurantName,
              pickupTime: action.params['time'] as String? ?? '',
              itemName: action.params['item'] as String? ?? '',
            ),
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A14), Color(0xFF12101E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildConversationLog()),
              _buildLiveTranscript(),
              _buildAiReplyBubble(),
              _buildMicSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const Spacer(),
          Text(
            'AI Voice Agent',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // TTS toggle
          Consumer<VoiceAgentProvider>(
            builder: (_, vp, __) => GestureDetector(
              onTap: vp.toggleVoiceReply,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: vp.voiceReplyEnabled
                      ? AppTheme.primary.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  vp.voiceReplyEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: vp.voiceReplyEnabled ? AppTheme.primary : Colors.white54,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── Conversation Log ──────────────────────────────────────────────────────
  Widget _buildConversationLog() {
    return Consumer<VoiceAgentProvider>(
      builder: (_, vp, __) {
        if (vp.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎙️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Tap the mic and start talking',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"I want to eat something healthy"\n"Add tomato soup to cart"\n"Book me a table at 6:45 PM"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white30,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: vp.history.length,
          itemBuilder: (context, i) {
            final turn = vp.history[i];
            return _buildBubble(turn);
          },
        );
      },
    );
  }

  Widget _buildBubble(ConversationTurn turn) {
    final isUser = turn.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primary.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          turn.text,
          style: GoogleFonts.outfit(
            color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0);
  }

  // ── Live transcript (while speaking) ─────────────────────────────────────
  Widget _buildLiveTranscript() {
    return Consumer<VoiceAgentProvider>(
      builder: (_, vp, __) {
        if (!vp.isListening || vp.liveTranscript.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            vp.liveTranscript,
            style: GoogleFonts.outfit(
                color: AppTheme.primary, fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ).animate().fadeIn(duration: 200.ms);
      },
    );
  }

  // ── AI "thinking" / reply indicator ──────────────────────────────────────
  Widget _buildAiReplyBubble() {
    return Consumer<VoiceAgentProvider>(
      builder: (_, vp, __) {
        if (vp.isThinking) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.primary, size: 16),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 600.ms),
                const SizedBox(width: 12),
                Text('Thinking...',
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
              ],
            ),
          );
        }
        if (vp.state == VoiceAgentState.error && vp.errorMessage != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              vp.errorMessage!,
              style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 13),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── Mic orb + controls ────────────────────────────────────────────────────
  Widget _buildMicSection() {
    return Consumer<VoiceAgentProvider>(
      builder: (_, vp, __) {
        final listening = vp.isListening;
        final thinking  = vp.isThinking;
        final speaking  = vp.isSpeaking;

        Color orbColor = listening
            ? AppTheme.primary
            : speaking
                ? const Color(0xFF2ECC71)
                : thinking
                    ? const Color(0xFFF39C12)
                    : Colors.white.withValues(alpha: 0.15);

        String label = listening
            ? 'Listening… tap to send'
            : speaking
                ? 'Speaking…'
                : thinking
                    ? 'Thinking…'
                    : 'Tap to speak';

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wave rings behind orb
              Stack(
                alignment: Alignment.center,
                children: [
                  if (listening || speaking)
                    ...[1.4, 1.7, 2.0].map((scale) => AnimatedBuilder(
                      animation: _orbController,
                      builder: (_, __) => Transform.scale(
                        scale: scale + _orbController.value * 0.15,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: orbColor.withValues(
                                alpha: (0.12 - (scale - 1.4) * 0.04)
                                    .clamp(0.0, 1.0)),
                          ),
                        ),
                      ),
                    )),
                  // Main mic button
                  GestureDetector(
                    onTap: thinking ? null : _handleMicTap,
                    child: AnimatedBuilder(
                      animation: _orbController,
                      builder: (_, __) {
                        return Transform.scale(
                          scale: listening
                              ? (1.0 + _orbController.value * 0.08)
                              : 1.0,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: orbColor,
                              boxShadow: [
                                BoxShadow(
                                  color: orbColor.withValues(alpha: 0.5),
                                  blurRadius: listening ? 28 : 12,
                                  spreadRadius: listening ? 6 : 0,
                                )
                              ],
                            ),
                            child: Icon(
                              listening
                                  ? Icons.stop_rounded
                                  : thinking
                                      ? Icons.hourglass_top_rounded
                                      : Icons.mic_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Quick action chips
              if (!listening && !thinking && !speaking) _buildQuickChips(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickChips() {
    final chips = [
      '🥗 Healthy food',
      '🛒 View cart',
      '📋 Book table',
      '🥡 Takeaway',
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) {
        return GestureDetector(
          onTap: () async {
            final vp = context.read<VoiceAgentProvider>();
            await vp.processQueryAndGetAction(c.replaceAll(RegExp(r'[^\w\s]'), '').trim());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              c,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 200.ms);
  }
}
