import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Manages all voice I/O for the AI Agent:
/// - Speech-to-Text (listening to user)
/// - Text-to-Speech (AI speaking back)
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _sttAvailable = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.55); // Faster pace
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);

    // STT setup
    try {
      _sttAvailable = await _stt.initialize(
        onError: (e) => debugPrint('STT error: $e'),
        onStatus: (s) => debugPrint('STT status: $s'),
      );
    } catch (e) {
      debugPrint('STT init error: $e');
      _sttAvailable = false;
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Returns true if mic permission is granted (or just granted).
  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // ── Speech-to-Text ────────────────────────────────────────────────────────

  /// Start listening. [onResult] fires with partial/final transcripts.
  /// [onDone] fires when the user stops speaking (silence detected).
  Future<bool> startListening({
    required void Function(String words, bool isFinal) onResult,
    VoidCallback? onDone,
  }) async {
    if (_isListening) return false;

    final hasPermission = await requestMicPermission();
    if (!hasPermission) return false;

    if (!_sttAvailable) {
      _sttAvailable = await _stt.initialize();
    }
    if (!_sttAvailable) return false;

    // Interrupt any ongoing speech before listening
    await stopSpeaking();

    _isListening = true;

    _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _isListening = false;
          onDone?.call();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_IN',
    );

    return true;
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _stt.stop();
      _isListening = false;
    }
  }

  // ── Text-to-Speech ────────────────────────────────────────────────────────

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      // Chrome SpeechSynthesisErrorEvent — non-fatal, just log it
      debugPrint('TTS speak error (non-fatal): $e');
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop error (non-fatal): $e');
    }
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
  }
}
