import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../models/chat_models.dart';
import '../providers/cart_provider.dart';
import '../services/voice_service.dart';
import '../services/voice_action_handler.dart';

enum VoiceAgentState { idle, listening, thinking, speaking, error }

/// A single turn in the conversation history.
class ConversationTurn {
  final bool isUser;
  final String text;
  final DateTime time;
  ConversationTurn({required this.isUser, required this.text})
      : time = DateTime.now();
}

/// Central provider for the Voice AI Agent.
///
/// Owns the full loop:
///   user speaks → STT → backend AI → TTS → in-app action
class VoiceAgentProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();
  final VoiceActionHandler _actionHandler = VoiceActionHandler();
  final CartProvider _cartProvider;

  VoiceAgentProvider(this._cartProvider);

  // ── State ────────────────────────────────────────────────────────────────
  VoiceAgentState _state = VoiceAgentState.idle;
  String _liveTranscript = '';     // what the user is currently saying (live)
  String _lastAiReply  = '';       // last AI text response
  String? _errorMessage;
  bool _voiceReplyEnabled = true;  // user can toggle TTS on/off
  void Function(VoiceAction)? onActionTriggered;
  VoiceAction? _pendingAction;

  final List<ConversationTurn> _history = [];

  // Context carried across turns
  String _currentArea   = '';
  String _currentRestaurantId = '';
  String _currentRestaurantName = '';

  // Voice session ID — maintained across turns for multi-turn context
  String? _voiceSessionId;

  // ── Getters ───────────────────────────────────────────────────────────────
  VoiceAgentState get state        => _state;
  String get liveTranscript        => _liveTranscript;
  String get lastAiReply           => _lastAiReply;
  String? get errorMessage         => _errorMessage;
  bool get voiceReplyEnabled       => _voiceReplyEnabled;
  bool get isListening             => _state == VoiceAgentState.listening;
  bool get isThinking              => _state == VoiceAgentState.thinking;
  bool get isSpeaking              => _state == VoiceAgentState.speaking;
  List<ConversationTurn> get history => List.unmodifiable(_history);
  String get currentRestaurantName => _currentRestaurantName;
  String get currentArea           => _currentArea;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _voiceService.init();
    // Create a voice session for multi-turn conversation context
    try {
      _voiceSessionId = await ApiService().createVoiceSession(
        areaName: _currentArea.isNotEmpty ? _currentArea : null,
      );
      debugPrint('Voice session created: $_voiceSessionId');
    } catch (e) {
      // Non-fatal — falls back to stateless /chat endpoint
      debugPrint('Voice session creation failed (non-fatal): $e');
      _voiceSessionId = null;
    }
  }

  // ── Toggle TTS ────────────────────────────────────────────────────────────
  void toggleVoiceReply() {
    _voiceReplyEnabled = !_voiceReplyEnabled;
    if (!_voiceReplyEnabled) _voiceService.stopSpeaking();
    notifyListeners();
  }

  // ── Set Context (called by screens) ──────────────────────────────────────
  void setRestaurantContext(String id, String name) {
    _currentRestaurantId = id;
    _currentRestaurantName = name;
  }

  void setAreaContext(String area) {
    _currentArea = area;
  }

  // ── Main: Toggle Listening ────────────────────────────────────────────────
  /// Tap-once-to-start / tap-again-to-stop.
  Future<void> toggleListening() async {
    if (_state == VoiceAgentState.listening) {
      await _voiceService.stopListening();
      _setState(VoiceAgentState.idle);
      if (_liveTranscript.isNotEmpty) {
        await _processQuery(_liveTranscript);
      }
      return;
    }

    if (_state == VoiceAgentState.speaking) {
      await _voiceService.stopSpeaking();
    }

    _liveTranscript = '';
    _errorMessage = null;
    _setState(VoiceAgentState.listening);

    final started = await _voiceService.startListening(
      onResult: (words, isFinal) {
        _liveTranscript = words;
        notifyListeners();
        if (isFinal && words.isNotEmpty) {
          _processQuery(words);
        }
      },
      onDone: () {
        if (_state == VoiceAgentState.listening) {
          _setState(VoiceAgentState.idle);
        }
      },
    );

    if (!started) {
      _errorMessage = 'Microphone not available. Please grant permission.';
      _setState(VoiceAgentState.error);
    }
  }

  // ── Core Processing Loop ──────────────────────────────────────────────────
  Future<VoiceAction> processQueryAndGetAction(String query) async {
    return await _processQuery(query);
  }

  Future<VoiceAction> _processQuery(String query) async {
    if (query.trim().isEmpty) return const VoiceAction(type: VoiceActionType.none);

    // Add user turn to history
    _history.add(ConversationTurn(isUser: true, text: query));
    _setState(VoiceAgentState.thinking);

    // ── 1. Check if we need to fill missing parameters locally ──
    if (_pendingAction != null) {
      _pendingAction = _actionHandler.fillMissingParams(_pendingAction!, query);
      
      if (_pendingAction!.params['cancel'] == true) {
        _pendingAction = null;
        final reply = "Okay, cancelled.";
        _lastAiReply = reply;
        _history.add(ConversationTurn(isUser: false, text: reply));
        await _speakAndFinish(reply);
        return const VoiceAction(type: VoiceActionType.none);
      }

      if (_pendingAction!.isComplete) {
        final actionToRun = _pendingAction!;
        _pendingAction = null;
        
        final reply = _getSuccessReplyFor(actionToRun);
        _lastAiReply = reply;
        _history.add(ConversationTurn(isUser: false, text: reply));
        
        _handleActionPreReqs(actionToRun, query);
        await _speakAndFinish(reply);
        onActionTriggered?.call(actionToRun);
        return actionToRun;
      } else {
        // Still missing
        final prompt = _getPromptForMissing(_pendingAction!);
        _lastAiReply = prompt;
        _history.add(ConversationTurn(isUser: false, text: prompt));
        await _speakAndFinish(prompt);
        return const VoiceAction(type: VoiceActionType.none);
      }
    }

    // ── 2. Normal AI RAG Flow — uses /voice/chat if session exists, else /chat ──
    String aiReply;
    try {
      if (_voiceSessionId != null) {
        // Use voice endpoint with session continuity
        final response = await ApiService().voiceChat(
          query: query,
          sessionId: _voiceSessionId,
          areaName: _currentArea.isNotEmpty ? _currentArea : null,
          restaurantId: _currentRestaurantId.isNotEmpty ? _currentRestaurantId : null,
        );
        aiReply = response.answer;
        // Update session ID in case backend rotated it
        _voiceSessionId = response.sessionId.isNotEmpty ? response.sessionId : _voiceSessionId;
      } else {
        // Fallback: stateless /chat endpoint
        final response = await ApiService().chat(
          query: query,
          areaName: _currentArea.isNotEmpty ? _currentArea : null,
          restaurantId: _currentRestaurantId.isNotEmpty ? _currentRestaurantId : null,
        );
        aiReply = response.answer;
      }
    } on ApiException catch (e) {
      aiReply = 'Sorry, I could not connect to the server. ${e.message}';
    } catch (_) {
      aiReply = 'Sorry, something went wrong. Please try again.';
    }

    _lastAiReply = aiReply;
    _history.add(ConversationTurn(isUser: false, text: aiReply));

    // Parse action from the query + reply
    final action = _actionHandler.parse(
      userQuery: query,
      aiReply: aiReply,
    );

    // Intercept if action is incomplete
    if (!action.isComplete) {
       _pendingAction = action;
       final prompt = _getPromptForMissing(action);
       _lastAiReply = prompt;
       // Replace the API's textual answer with a targeted question
       _history.removeLast();
       _history.add(ConversationTurn(isUser: false, text: prompt));
       await _speakAndFinish(prompt);
       return const VoiceAction(type: VoiceActionType.none);
    }

    _handleActionPreReqs(action, query);
    await _speakAndFinish(aiReply);

    onActionTriggered?.call(action);
    return action;
  }

  void _handleActionPreReqs(VoiceAction action, String query) {
    // Handle cart action
    if (action.type == VoiceActionType.addToCart || 
        (action.type == VoiceActionType.placeOrder && (action.params['item'] as String? ?? '').isNotEmpty)) {
      final itemName = action.params['item'] as String? ?? query;
      _cartProvider.addItemByName(
        name: itemName,
        restaurantName: _currentRestaurantName,
        restaurantId: _currentRestaurantId,
        price: 0.0,
      );
    }
    // Handle payment method
    if (action.type == VoiceActionType.placeOrder) {
      final payment = action.params['payment'] as String? ?? 'Cash on Delivery';
      _cartProvider.setPaymentMethodFromString(payment);
    }
  }

  Future<void> _speakAndFinish(String text) async {
    if (_voiceReplyEnabled) {
      _setState(VoiceAgentState.speaking);
      await _voiceService.speak(text);
      if (_state == VoiceAgentState.speaking) {
        _setState(VoiceAgentState.idle);
      }
    } else {
      if (_state == VoiceAgentState.thinking) {
        _setState(VoiceAgentState.idle);
      }
    }
  }

  String _getPromptForMissing(VoiceAction action) {
    final missing = action.missingParams;
    if (missing.isEmpty) return "";

    final t = missing.first;
    if (t == 'alternative_time_confirm') {
      return "${action.params['original_time']} is currently unavailable. Would ${action.params['time']} work for you instead?";
    }
    if (t == 'time') return "For what time?";
    if (t == 'item') {
      if (action.type == VoiceActionType.scheduleTakeaway) return "What item would you like to take away?";
      return "What item would you like to order?";
    }
    if (t == 'confirm') {
      if (action.type == VoiceActionType.bookTable) return "Shall I proceed with booking the table for ${action.params['time']}?";
      if (action.type == VoiceActionType.scheduleTakeaway) return "Shall I proceed with the takeaway order for ${action.params['item']} at ${action.params['time']}?";
      if (action.type == VoiceActionType.placeOrder) return "Shall I proceed with placing the order for ${action.params['item']}?";
      return "Shall I proceed?";
    }
    return "Please provide more details.";
  }

  String _getSuccessReplyFor(VoiceAction action) {
    if (action.type == VoiceActionType.scheduleTakeaway) {
      return "Okay, I will inform the restaurant about your takeaway order for ${action.params['time']}.";
    }
    if (action.type == VoiceActionType.bookTable) {
      return "Okay, I'll prepare your table booking for ${action.params['time']}.";
    }
    return "Got it! Doing that now.";
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setState(VoiceAgentState s) {
    _state = s;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _liveTranscript = '';
    _lastAiReply = '';
    _errorMessage = null;
    _pendingAction = null;
    _setState(VoiceAgentState.idle);
  }

  @override
  void dispose() {
    // Clean up the server-side voice session
    if (_voiceSessionId != null) {
      ApiService().endVoiceSession(_voiceSessionId!).catchError((_) {});
    }
    _voiceService.dispose();
    super.dispose();
  }
}
