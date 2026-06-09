// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/chat_models.dart';
import '../providers/customer_bookings_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TableBookingScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String timeSlot;
  final int numberOfGuests;

  final bool isVoiceConfirmed;
  final String? bookingId;
  final String? bookingDate;

  final List<String> alternativeSlots;
  final List<NearbyRestaurant> nearbyRestaurants;

  final void Function(String slot)? onAlternativeSlotSelected;
  final void Function(NearbyRestaurant restaurant)? onNearbyRestaurantSelected;

  const TableBookingScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.timeSlot = '',
    this.numberOfGuests = 2,
    this.isVoiceConfirmed = false,
    this.bookingId,
    this.bookingDate,
    this.alternativeSlots = const [],
    this.nearbyRestaurants = const [],
    this.onAlternativeSlotSelected,
    this.onNearbyRestaurantSelected,
  });

  @override
  State<TableBookingScreen> createState() => _TableBookingScreenState();
}

class _TableBookingScreenState extends State<TableBookingScreen> {
  late String _selectedTime;
  late int _guests;
  DateTime _selectedDate = DateTime.now();
  bool _confirmed = false;
  String? _bookingId;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  bool _isLoadingSlots = false;
  List<Map<String, dynamic>> _slots = [];

  bool _isConfirming = false;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.timeSlot;
    _guests = widget.numberOfGuests;
    _confirmed = widget.isVoiceConfirmed;
    _bookingId = widget.bookingId;
    if (!_confirmed && widget.restaurantId.isNotEmpty) {
      _loadSlots();
    }
    _loadSavedContact();
  }

  Future<void> _loadSavedContact() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'booking_name');
    final phone = await storage.read(key: 'booking_phone');
    if (mounted) {
      if (name != null) _nameCtrl.text = name;
      if (phone != null) _phoneCtrl.text = phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final slots = await ApiService().getAvailableSlots(widget.restaurantId, dateStr);
      setState(() {
        _slots = slots;
      });
    } catch (e) {
      debugPrint("Error loading slots: $e");
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = ''; // reset time
      });
      _loadSlots();
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });

    final nameText = _nameCtrl.text.trim();
    final phoneText = _phoneCtrl.text.trim();
    
    bool hasError = false;

    if (nameText.isEmpty) {
      _nameError = 'Name cannot be empty';
      hasError = true;
    }

    if (phoneText.isEmpty) {
      _phoneError = 'Phone number cannot be empty';
      hasError = true;
    } else if (phoneText.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phoneText)) {
      _phoneError = 'Phone number must be exactly 10 digits';
      hasError = true;
    }

    if (hasError || _selectedTime.isEmpty) {
      if (_selectedTime.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time slot'), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    setState(() => _isConfirming = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final res = await ApiService().confirmDineBooking(
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        timeSlot: _selectedTime,
        partySize: _guests,
        dateStr: dateStr,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
      );

      // Save to local storage
      if (mounted) {
        await context.read<CustomerBookingsProvider>().addBookingId(res.bookingId);
      }
      
      const storage = FlutterSecureStorage();
      await storage.write(key: 'booking_name', value: _nameCtrl.text.trim());
      await storage.write(key: 'booking_phone', value: _phoneCtrl.text.trim());

      setState(() {
        _confirmed = true;
        _bookingId = res.bookingId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Book a Table', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
      ),
      body: _confirmed ? _buildSuccess() : _buildForm(),
    );
  }

  // ── Success State ─────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3A2A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.deck_rounded, color: Color(0xFF2ECC71), size: 56),
          ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 24),

          Text('Table Booked! 🥂', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _bookingRow(Icons.restaurant_rounded, widget.restaurantName.isNotEmpty ? widget.restaurantName : 'Restaurant'),
                const SizedBox(height: 12),
                _bookingRow(Icons.access_time_rounded, _selectedTime.isNotEmpty ? _selectedTime : widget.timeSlot),
                const SizedBox(height: 12),
                _bookingRow(Icons.people_alt_rounded, '$_guests Guests'),
                const SizedBox(height: 12),
                _bookingRow(Icons.calendar_today_rounded, widget.bookingDate ?? '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                const Divider(height: 28, color: Color(0xFF2C2C3E)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_number_rounded, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Flexible(child: Text('Booking ID: $_bookingId', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Form State ────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF5E6D3), Color(0xFFFDF5E6)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.restaurantName.isNotEmpty ? widget.restaurantName : 'Selected Restaurant',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                      Text('Table Reservation', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 28),

          _sectionLabel('Customer Details'),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Full Name',
              hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
              errorText: _nameError,
              prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: AppTheme.surface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Phone Number',
              hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
              errorText: _phoneError,
              prefixText: '+91 ',
              prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primary, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: AppTheme.surface,
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Date & Guests'),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: _pickDate,
                  child: _inputFieldBox(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: GoogleFonts.outfit(fontSize: 15, color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _inputFieldBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _guests > 1 ? () => setState(() => _guests--) : null,
                        child: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text('$_guests', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _guests < 20 ? () => setState(() => _guests++) : null,
                        child: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _sectionLabel('Available Slots'),
          _buildSlotsGrid(),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isConfirming ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isConfirming
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.deck_rounded),
                        const SizedBox(width: 10),
                        Text('Confirm Booking', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsGrid() {
    if (widget.restaurantId.isEmpty) {
      return Text("Slots not available for this restaurant.", style: GoogleFonts.outfit(color: AppTheme.textSecondary));
    }
    if (_isLoadingSlots) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_slots.isEmpty) {
      return Text("No slots available.", style: GoogleFonts.outfit(color: AppTheme.textSecondary));
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _slots.map((slot) {
        final time = slot['time_slot'] as String;
        final available = slot['available'] == true;
        final isSelected = _selectedTime == time;

        return GestureDetector(
          onTap: available ? () => setState(() => _selectedTime = time) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: available
                  ? (isSelected ? AppTheme.primary : AppTheme.surfaceAlt)
                  : AppTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: available
                    ? (isSelected ? AppTheme.primary : AppTheme.divider)
                    : AppTheme.error.withOpacity(0.5),
              ),
            ),
            child: Text(
              time,
              style: GoogleFonts.outfit(
                color: available
                    ? (isSelected ? Colors.white : AppTheme.textPrimary)
                    : AppTheme.error,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: available ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textSecondary)),
    );
  }

  Widget _inputFieldBox({required Widget child, bool hasError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? AppTheme.error : AppTheme.divider,
          width: hasError ? 1.5 : 1.0,
        ),
      ),
      child: child,
    );
  }
}
