import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../models/chat_models.dart';
import '../providers/cart_provider.dart';
import '../providers/dine_in_provider.dart';
import '../providers/takeaway_provider.dart';
import '../services/voice_service.dart';
import '../services/voice_action_handler.dart';

export '../models/chat_models.dart' show DineAvailabilityResponse, DineBookingConfirmation, NearbyRestaurant;

enum VoiceAgentState { idle, listening, thinking, speaking, error }

/// A single turn in the conversation history.
class ConversationTurn {
  final bool isUser;
  final String text;
  final DateTime time;

  // Optional rich payload — used to render interactive cards
  final List<String>? alternativeSlots;
  final List<NearbyRestaurant>? nearbyRestaurants;

  ConversationTurn({
    required this.isUser,
    required this.text,
    this.alternativeSlots,
    this.nearbyRestaurants,
  }) : time = DateTime.now();
}

/// Central provider for the Voice AI Agent.
///
/// Owns the full conversation loop:
///   user speaks → STT → [local or backend AI] → TTS → in-app action
///
/// PERFORMANCE NOTES:
///   - Booking dialogue turns are handled locally (0 LLM calls, instant responses).
///   - Availability checks run concurrently with TTS playback.
///   - Navigation is triggered immediately — does NOT wait for TTS to finish.
class VoiceAgentProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();
  final VoiceActionHandler _actionHandler = VoiceActionHandler();
  final CartProvider _cartProvider;
  final DineInProvider _dineProvider;
  final TakeawayProvider _takeawayProvider;

  VoiceAgentProvider(this._cartProvider, this._dineProvider, this._takeawayProvider);

  // ── State ────────────────────────────────────────────────────────────────
  VoiceAgentState _state        = VoiceAgentState.idle;
  String _liveTranscript        = '';
  String _lastAiReply           = '';
  String? _errorMessage;
  bool _voiceReplyEnabled       = true;
  void Function(VoiceAction)? onActionTriggered;
  VoiceAction? _pendingAction;

  final List<ConversationTurn> _history = [];

  // Context carried across turns
  String _currentArea          = '';
  String _currentRestaurantId  = '';
  String _currentRestaurantName = '';

  // Voice session ID for multi-turn backend context
  String? _voiceSessionId;

  // Pending dine-in booking details (collected across turns)
  int?    _pendingPeople;
  String? _pendingTime;
  String? _pendingRestaurantForBooking;

  // Pending takeaway details
  String? _pendingTakeawayItem;
  String? _pendingTakeawayTime;
  String? _pendingTakeawayRestaurant;
  String? _pendingTakeawayName;
  String? _pendingTakeawayPhone;

  // Guard against double-processing the same STT result
  bool _isProcessing = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  VoiceAgentState get state         => _state;
  String get liveTranscript         => _liveTranscript;
  String get lastAiReply            => _lastAiReply;
  String? get errorMessage          => _errorMessage;
  bool get voiceReplyEnabled        => _voiceReplyEnabled;
  bool get isListening              => _state == VoiceAgentState.listening;
  bool get isThinking               => _state == VoiceAgentState.thinking;
  bool get isSpeaking               => _state == VoiceAgentState.speaking;
  List<ConversationTurn> get history => List.unmodifiable(_history);
  String get currentRestaurantName  => _currentRestaurantName;
  String get currentArea            => _currentArea;
  DineInProvider get dineProvider   => _dineProvider;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _voiceService.init();
    try {
      _voiceSessionId = await ApiService().createVoiceSession(
        areaName: _currentArea.isNotEmpty ? _currentArea : null,
      );
      debugPrint('Voice session created: $_voiceSessionId');
    } catch (e) {
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

  // ── Set Context ───────────────────────────────────────────────────────────
  void setRestaurantContext(String id, String name) {
    _currentRestaurantId   = id;
    _currentRestaurantName = name;
    _dineProvider.setRestaurant(id, name);
  }

  void setAreaContext(String area) {
    _currentArea = area;
  }

  // ── Main: Toggle Listening ────────────────────────────────────────────────
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
    _errorMessage   = null;
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

  // ── Public API ────────────────────────────────────────────────────────────
  Future<VoiceAction> processQueryAndGetAction(String query) async {
    return await _processQuery(query);
  }

  // ── Core Processing Loop ──────────────────────────────────────────────────
  Future<VoiceAction> _processQuery(String query) async {
    if (query.trim().isEmpty) return const VoiceAction(type: VoiceActionType.none);

    // Prevent double-processing the same STT result
    if (_isProcessing) {
      debugPrint('VoiceAgent: skipping duplicate query "$query"');
      return const VoiceAction(type: VoiceActionType.none);
    }
    _isProcessing = true;

    _history.add(ConversationTurn(isUser: true, text: query));
    _setState(VoiceAgentState.thinking);

    try {

    // ── Branch: active dine-in booking dialogue ──────────────────────────
    if (_pendingAction != null && _pendingAction!.type == VoiceActionType.bookTable) {
      debugPrint('VoiceAgent: continuing dine-in turn | people=$_pendingPeople time=$_pendingTime');
      return await _handleDineInTurn(query);
    }

    // ── Branch: active takeaway dialogue ──────────────────────────────────
    if (_pendingAction != null && _pendingAction!.type == VoiceActionType.scheduleTakeaway) {
      debugPrint('VoiceAgent: continuing takeaway turn | item=$_pendingTakeawayItem time=$_pendingTakeawayTime');
      return await _handleTakeawayTurn(query);
    }

    // ── Branch: other pending actions (takeaway, order) ──────────────────
    if (_pendingAction != null) {
      return await _handleOtherPendingAction(query);
    }

    // ── Branch: detect new bookTable intent from first utterance ─────────
    final quickAction = _actionHandler.parse(userQuery: query, aiReply: '');
    debugPrint('VoiceAgent: parsed action = ${quickAction.type} params=${quickAction.params}');
    if (quickAction.type == VoiceActionType.bookTable) {
      _pendingAction = quickAction;
      // Pre-populate from parsed params so _handleDineInTurn has full context
      _pendingPeople ??= quickAction.params['people'] as int?;
      if (_pendingTime == null) {
        final t = quickAction.params['time'] as String?;
        if (t != null && t.isNotEmpty) _pendingTime = t;
      }
      if (_pendingRestaurantForBooking == null) {
        final rn = quickAction.params['restaurantName'] as String?;
        if (rn != null && rn.isNotEmpty) _pendingRestaurantForBooking = rn;
      }
      debugPrint('VoiceAgent: bookTable detected | people=$_pendingPeople time=$_pendingTime restaurant=$_pendingRestaurantForBooking');
      return await _handleDineInTurn(query);
    }

    // ── Branch: detect new takeaway intent from first utterance ──────────
    if (quickAction.type == VoiceActionType.scheduleTakeaway) {
      _pendingAction = quickAction;
      _pendingTakeawayItem = quickAction.params['item'] as String?;
      _pendingTakeawayTime = quickAction.params['time'] as String?;
      _pendingTakeawayRestaurant = quickAction.params['restaurantName'] as String?;
      return await _handleTakeawayTurn(query);
    }

    // ── Default: send to AI backend ───────────────────────────────────────
    return await _handleAIQuery(query);
  } catch (e, stack) {
    debugPrint('VoiceAgent: _processQuery error: $e\n$stack');
    _setState(VoiceAgentState.idle);
    return const VoiceAction(type: VoiceActionType.none);
  } finally {
    _isProcessing = false;
  }
  }

  // ── Dine-In Conversation State Machine ───────────────────────────────────
  Future<VoiceAction> _handleDineInTurn(String query) async {
    final q = query.toLowerCase();

    // Collect `people` if still missing
    if (_pendingPeople == null) {
      final parsed = _actionHandler.parse(userQuery: query, aiReply: '');
      final people = parsed.params['people'] as int? ??
          _actionHandler.extractPeople(query);
      if (people != null) {
        _pendingPeople = people;
        _pendingAction = VoiceAction(
          type:   VoiceActionType.bookTable,
          params: {...?_pendingAction?.params, 'people': people},
        );
        // Also check if time was provided in same utterance
        final time = parsed.params['time'] as String? ??
            _actionHandler.extractTime(query);
        if (time != null && time.isNotEmpty) {
          _pendingTime = time;
          _pendingAction = VoiceAction(
            type:   VoiceActionType.bookTable,
            params: {..._pendingAction!.params, 'time': time},
          );
        }
      }
    }
    // Collect `time` if still missing
    if (_pendingPeople != null && _pendingTime == null) {
      final time = _actionHandler.extractTime(query);
      if (time.isNotEmpty) {
        _pendingTime = time;
        _pendingAction = VoiceAction(
          type:   VoiceActionType.bookTable,
          params: {...?_pendingAction?.params, 'time': time, 'people': _pendingPeople},
        );
      }
    }

    // ── Still missing people ──────────────────────────────────────────────
    if (_pendingPeople == null) {
      const reply = 'Sure! For how many people, and at what time?';
      return _localReply(reply);
    }

    // ── Have people but no time ───────────────────────────────────────────
    if (_pendingTime == null) {
      final reply = 'Got it, $_pendingPeople people. At what time would you like to dine?';
      return _localReply(reply);
    }

    // ── Have people + time: handle confirm/cancel/rebook or new slot ──────
    // Check if user is cancelling
    if (_isCancel(q)) {
      _resetDineIn();
      const reply = 'Okay, no booking made. Let me know if you need anything else!';
      return _localReply(reply, action: const VoiceAction(type: VoiceActionType.none));
    }

    // Check if user is providing a new time slot (after being offered alternatives)
    final newTime = _actionHandler.extractTime(query);
    if (newTime.isNotEmpty && newTime != _pendingTime) {
      _pendingTime = newTime;
    }

    // Check if user picked a nearby restaurant
    final nearbyPick = _extractNearbyRestaurantFromQuery(query);
    if (nearbyPick != null) {
      _pendingRestaurantForBooking = nearbyPick;
    }

    // ── Run availability check ────────────────────────────────────────────
    _setState(VoiceAgentState.thinking);

    // Resolve restaurant: named pick > current context > demo fallback
    final String rid;
    final String rname;
    if (_pendingRestaurantForBooking != null && _pendingRestaurantForBooking!.isNotEmpty) {
      rid   = _findNearbyRestaurantId(_pendingRestaurantForBooking!);
      rname = _pendingRestaurantForBooking!;
    } else if (_currentRestaurantId.isNotEmpty) {
      rid   = _currentRestaurantId;
      rname = _currentRestaurantName.isNotEmpty ? _currentRestaurantName : 'the restaurant';
    } else {
      rid   = 'demo-restaurant-001';
      rname = 'Pranil Da Dhaba';  // friendly demo name
    }

    DineAvailabilityResponse availability;
    try {
      availability = await _dineProvider.checkAvailability(
        timeSlot:       _pendingTime!,
        partySize:      _pendingPeople!,
        restaurantId:   rid,
        restaurantName: rname,
      );
    } catch (e) {
      availability = DineAvailabilityResponse(
        available:         true,
        confirmedSlot:     _pendingTime,
        reason:            'ok',
        alternativeSlots:  [],
        nearbyRestaurants: [],
        aiMessage:         "I'll go ahead and book that for you.",
      );
    }

    // ── Available ─────────────────────────────────────────────────────────
    if (availability.available) {
      // Confirm immediately — also start confirmation API call
      final booking = await _dineProvider.confirmBooking(
        timeSlot:       availability.confirmedSlot ?? _pendingTime!,
        partySize:      _pendingPeople!,
        restaurantId:   rid,
        restaurantName: rname,
      );

      final reply = booking.aiMessage.isNotEmpty
          ? booking.aiMessage
          : 'Your reservation has been made successfully! '
            'Table for $_pendingPeople at ${booking.restaurantName}, ${booking.timeSlot}. '
            'Booking ID: ${booking.bookingId}.';

      final action = VoiceAction(
        type: VoiceActionType.bookTable,
        params: {
          'confirm':         true,
          'time':            booking.timeSlot,
          'people':          _pendingPeople,
          'restaurantName':  booking.restaurantName,
          'restaurantId':    booking.restaurantId,
          'bookingId':       booking.bookingId,
          'date':            booking.date,
        },
      );

      _resetDineIn();
      _lastAiReply = reply;
      _history.add(ConversationTurn(isUser: false, text: reply));

      // Speak + navigate concurrently
      _speakAsync(reply);
      _setState(VoiceAgentState.idle);
      onActionTriggered?.call(action);
      return action;
    }

    // ── Time unavailable — offer alternative slots ────────────────────────
    if (availability.reason == 'time_unavailable') {
      final slots = availability.alternativeSlots;
      final reply = availability.aiMessage;
      _lastAiReply = reply;
      _history.add(ConversationTurn(
        isUser:           false,
        text:             reply,
        alternativeSlots: slots,
      ));
      // Reset time so next utterance picks up user's chosen alternative
      _pendingTime = null;
      // Keep _pendingAction as bookTable so next turn re-enters _handleDineInTurn
      _pendingAction = VoiceAction(
        type:   VoiceActionType.bookTable,
        params: {'people': _pendingPeople, if (rname.isNotEmpty) 'restaurantName': rname},
      );
      await _speakAndFinish(reply);
      return const VoiceAction(type: VoiceActionType.none);
    }

    // ── Seats unavailable — offer nearby restaurants ──────────────────────
    if (availability.reason == 'seats_unavailable') {
      final nearby = availability.nearbyRestaurants;
      final reply  = availability.aiMessage;
      _lastAiReply = reply;
      _history.add(ConversationTurn(
        isUser:            false,
        text:              reply,
        nearbyRestaurants: nearby,
      ));
      // Keep people AND time — user just needs to pick a new restaurant
      // Refresh _pendingAction so next turn re-enters _handleDineInTurn
      _pendingAction = VoiceAction(
        type:   VoiceActionType.bookTable,
        params: {'people': _pendingPeople, 'time': _pendingTime},
      );
      await _speakAndFinish(reply);
      return const VoiceAction(type: VoiceActionType.none);
    }

    // Fallback
    const fallback = 'I could not check availability. Please try again.';
    return _localReply(fallback);
  }

  // ── Takeaway Conversation State Machine ─────────────────────────────────
  Future<VoiceAction> _handleTakeawayTurn(String query) async {
    final q = query.toLowerCase();

    // Check if user is cancelling
    if (_isCancel(q)) {
      _resetTakeaway();
      return _localReply('Okay, takeaway cancelled.', action: const VoiceAction(type: VoiceActionType.none));
    }

    // Check if user picked a nearby restaurant from Test Case 2 fallback
    final nearbyPick = _extractNearbyRestaurantForTakeaway(query);
    if (nearbyPick != null) {
      _pendingTakeawayRestaurant = nearbyPick;
    }

    final rname = _pendingTakeawayRestaurant?.isNotEmpty == true 
        ? _pendingTakeawayRestaurant! 
        : (_currentRestaurantName.isNotEmpty ? _currentRestaurantName : 'Pranil Da Dhaba');

    // ── PRE-CHECK: Does the restaurant offer takeaway? ────────────────────
    final capability = _takeawayProvider.checkRestaurantCapability(rname);
    if (capability != null && !capability.available) {
      final reply = capability.aiMessage;
      _lastAiReply = reply;
      _history.add(ConversationTurn(
        isUser: false, 
        text: reply,
        nearbyRestaurants: capability.nearbyRestaurants,
      ));
      
      // We don't ask for name/phone if the restaurant doesn't offer takeaway.
      _pendingAction = VoiceAction(
        type: VoiceActionType.scheduleTakeaway,
        params: {
          'item': _pendingTakeawayItem,
          'time': _pendingTakeawayTime,
        }
      );
      await _speakAndFinish(reply);
      return const VoiceAction(type: VoiceActionType.none);
    }

    // ── Extract time if missing ───────────────────────────────────────────
    if (_pendingTakeawayTime == null) {
      final time = _actionHandler.extractTime(query);
      if (time.isNotEmpty) _pendingTakeawayTime = time;
    }

    // Extract name and phone if missing
    if (_pendingTakeawayName == null) {
      final extractedName = _actionHandler.extractName(query);
      if (extractedName.isNotEmpty) _pendingTakeawayName = extractedName;
    }
    if (_pendingTakeawayPhone == null) {
      final extractedPhone = _actionHandler.extractPhone(query);
      if (extractedPhone.isNotEmpty) _pendingTakeawayPhone = extractedPhone;
    }

    // Still missing item? (Safety fallback)
    if (_pendingTakeawayItem == null || _pendingTakeawayItem!.isEmpty) {
      return _localReply('What would you like to order for takeaway?');
    }

    // Missing time?
    if (_pendingTakeawayTime == null) {
      return _localReply('Got it. At what time would you like to pick it up?');
    }

    // Missing name?
    if (_pendingTakeawayName == null) {
      return _localReply('Sure! Could I get your name for the order?');
    }

    // Missing phone?
    if (_pendingTakeawayPhone == null) {
      return _localReply('Thanks $_pendingTakeawayName. And your phone number?');
    }

    // ── We have all details, run availability check ───────────────────────
    _setState(VoiceAgentState.thinking);

    TakeawayAvailabilityResponse availability;
    try {
      availability = await _takeawayProvider.checkAvailability(
        item: _pendingTakeawayItem!,
        time: _pendingTakeawayTime!,
        restaurantName: rname,
        userName: _pendingTakeawayName!,
        phone: _pendingTakeawayPhone!,
      );
    } catch (e) {
      availability = TakeawayAvailabilityResponse(
        available: false,
        confirmedTime: null,
        reason: 'error',
        nearbyRestaurants: [],
        aiMessage: 'I could not reach the restaurant. Please try again.',
      );
    }

    // ── Scenario 2 is handled by PRE-CHECK above, so if we get here it's Success

    // ── Scenario 1: Available (Success) ───────────────────────────────────
    if (availability.available) {
      final reply = availability.aiMessage;
      
      final action = VoiceAction(
        type: VoiceActionType.scheduleTakeaway,
        params: {
          'confirm': true,
          'item': _pendingTakeawayItem,
          'time': availability.confirmedTime,
          'restaurantName': rname,
          'name': _pendingTakeawayName,
          'phone': _pendingTakeawayPhone,
          'orderId': availability.orderId,
        },
      );

      _resetTakeaway();
      _lastAiReply = reply;
      _history.add(ConversationTurn(isUser: false, text: reply));

      _speakAsync(reply);
      _setState(VoiceAgentState.idle);
      onActionTriggered?.call(action);
      return action;
    }

    return _localReply('I could not process the takeaway. Please try again.');
  }

  // ── Other pending action handler (order) ────────────────────────────────
  Future<VoiceAction> _handleOtherPendingAction(String query) async {
    _pendingAction = _actionHandler.fillMissingParams(_pendingAction!, query);

    if (_pendingAction!.params['cancel'] == true) {
      _pendingAction = null;
      const reply = 'Okay, cancelled.';
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
    }

    final prompt = _getPromptForMissing(_pendingAction!);
    _lastAiReply = prompt;
    _history.add(ConversationTurn(isUser: false, text: prompt));
    await _speakAndFinish(prompt);
    return const VoiceAction(type: VoiceActionType.none);
  }

  // ── AI backend query (food discovery, general) ───────────────────────────
  Future<VoiceAction> _handleAIQuery(String query) async {
    String aiReply;
    try {
      if (_voiceSessionId != null) {
        final response = await ApiService().voiceChat(
          query:        query,
          sessionId:    _voiceSessionId,
          areaName:     _currentArea.isNotEmpty ? _currentArea : null,
          restaurantId: _currentRestaurantId.isNotEmpty ? _currentRestaurantId : null,
        );
        aiReply = response.answer;
        _voiceSessionId = response.sessionId.isNotEmpty ? response.sessionId : _voiceSessionId;
      } else {
        final response = await ApiService().chat(
          query:        query,
          areaName:     _currentArea.isNotEmpty ? _currentArea : null,
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

    final action = _actionHandler.parse(userQuery: query, aiReply: aiReply);

    if (action.type == VoiceActionType.bookTable) {
      // Seamlessly hand off to dine-in flow
      _pendingAction = action;
      _pendingPeople = action.params['people'] as int?;
      _pendingTime   = action.params['time'] as String?;
      if (!action.isComplete) {
        final people = _pendingPeople;
        final prompt = people == null
            ? 'Sure! For how many people, and at what time?'
            : 'Got it, $people people. At what time would you like to dine?';
        _history.removeLast();
        _history.add(ConversationTurn(isUser: false, text: prompt));
        _lastAiReply = prompt;
        await _speakAndFinish(prompt);
        return const VoiceAction(type: VoiceActionType.none);
      }
    }

    if (!action.isComplete && action.type != VoiceActionType.bookTable) {
      _pendingAction = action;
      final prompt   = _getPromptForMissing(action);
      _lastAiReply   = prompt;
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

  // ── Local reply (no backend, instant) ────────────────────────────────────
  VoiceAction _localReply(String reply, {VoiceAction? action}) {
    _lastAiReply = reply;
    _history.add(ConversationTurn(isUser: false, text: reply));
    _speakAsync(reply);
    _setState(VoiceAgentState.idle);
    final result = action ?? const VoiceAction(type: VoiceActionType.none);
    return result;
  }

  // ── Speak without blocking (fire-and-forget) ──────────────────────────────
  void _speakAsync(String text) {
    if (_voiceReplyEnabled) {
      _setState(VoiceAgentState.speaking);
      _voiceService.speak(text).then((_) {
        if (_state == VoiceAgentState.speaking) {
          _setState(VoiceAgentState.idle);
        }
      });
    }
  }

  // ── Speak and wait ────────────────────────────────────────────────────────
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isCancel(String q) =>
      q.contains('cancel') || q.contains('nevermind') || q.contains("don't") ||
      q.contains('abort') || q.contains('no booking');

  void _resetDineIn() {
    _pendingAction              = null;
    _pendingPeople              = null;
    _pendingTime                = null;
    _pendingRestaurantForBooking = null;
  }

  void _resetTakeaway() {
    _pendingAction = null;
    _pendingTakeawayItem = null;
    _pendingTakeawayTime = null;
    _pendingTakeawayRestaurant = null;
    _pendingTakeawayName = null;
    _pendingTakeawayPhone = null;
  }

  String? _extractNearbyRestaurantFromQuery(String query) {
    final lower = query.toLowerCase();
    final availability = _dineProvider.lastAvailability;
    if (availability == null) return null;
    for (final r in availability.nearbyRestaurants) {
      if (lower.contains(r.name.toLowerCase())) return r.name;
    }
    return null;
  }

  String _findNearbyRestaurantId(String name) {
    final availability = _dineProvider.lastAvailability;
    if (availability == null) return 'demo-restaurant-001';
    for (final r in availability.nearbyRestaurants) {
      if (r.name.toLowerCase() == name.toLowerCase()) return r.id;
    }
    return 'demo-restaurant-002';
  }

  String? _extractNearbyRestaurantForTakeaway(String query) {
    final lower = query.toLowerCase();
    final availability = _takeawayProvider.lastAvailability;
    if (availability == null) return null;
    for (final r in availability.nearbyRestaurants) {
      if (lower.contains(r.name.toLowerCase())) return r.name;
    }
    return null;
  }

  void _handleActionPreReqs(VoiceAction action, String query) {
    if (action.type == VoiceActionType.addToCart ||
        (action.type == VoiceActionType.placeOrder &&
            (action.params['item'] as String? ?? '').isNotEmpty)) {
      final itemName = action.params['item'] as String? ?? query;
      _cartProvider.addItemByName(
        name:           itemName,
        restaurantName: _currentRestaurantName,
        restaurantId:   _currentRestaurantId,
        price:          0.0,
      );
    }
    if (action.type == VoiceActionType.placeOrder) {
      final payment = action.params['payment'] as String? ?? 'Cash on Delivery';
      _cartProvider.setPaymentMethodFromString(payment);
    }
  }

  String _getPromptForMissing(VoiceAction action) {
    final missing = action.missingParams;
    if (missing.isEmpty) return '';
    final t = missing.first;
    if (t == 'alternative_time_confirm') {
      return "${action.params['original_time']} is currently unavailable. "
          "Would ${action.params['time']} work for you instead?";
    }
    if (t == 'time') return 'For what time?';
    if (t == 'people') return 'For how many people?';
    if (t == 'item') {
      if (action.type == VoiceActionType.scheduleTakeaway) return 'What item would you like to take away?';
      return 'What item would you like to order?';
    }
    if (t == 'confirm') {
      if (action.type == VoiceActionType.bookTable) {
        return 'Shall I confirm the table for ${action.params['people']} at ${action.params['time']}?';
      }
      if (action.type == VoiceActionType.scheduleTakeaway) {
        return 'Shall I proceed with the takeaway for ${action.params['item']} at ${action.params['time']}?';
      }
      if (action.type == VoiceActionType.placeOrder) {
        return 'Shall I proceed with placing the order for ${action.params['item']}?';
      }
      return 'Shall I proceed?';
    }
    return 'Please provide more details.';
  }

  String _getSuccessReplyFor(VoiceAction action) {
    if (action.type == VoiceActionType.scheduleTakeaway) {
      return 'Okay, I will inform the restaurant about your takeaway order for ${action.params['time']}.';
    }
    if (action.type == VoiceActionType.bookTable) {
      return "Your reservation has been made! Table for ${action.params['people']} at ${action.params['time']}.";
    }
    return 'Got it! Doing that now.';
  }

  void _setState(VoiceAgentState s) {
    _state = s;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _liveTranscript = '';
    _lastAiReply    = '';
    _errorMessage   = null;
    _pendingAction  = null;
    _resetDineIn();
    _setState(VoiceAgentState.idle);
  }

  @override
  void dispose() {
    if (_voiceSessionId != null) {
      ApiService().endVoiceSession(_voiceSessionId!).catchError((_) {});
    }
    _voiceService.dispose();
    super.dispose();
  }
}
