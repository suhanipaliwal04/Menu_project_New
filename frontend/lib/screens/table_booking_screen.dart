import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/chat_models.dart';

class TableBookingScreen extends StatefulWidget {
  final String restaurantName;
  final String timeSlot;
  final int numberOfGuests;

  /// When true, the screen opens directly in the confirmed state
  /// (voice agent already booked the table).
  final bool isVoiceConfirmed;
  final String? bookingId;
  final String? bookingDate;

  /// If non-empty, show alternative time-slot chips (test case 2).
  final List<String> alternativeSlots;

  /// If non-empty, show nearby restaurant cards (test case 3).
  final List<NearbyRestaurant> nearbyRestaurants;

  /// Called when user taps an alternative slot chip.
  final void Function(String slot)? onAlternativeSlotSelected;

  /// Called when user taps a nearby restaurant card.
  final void Function(NearbyRestaurant restaurant)? onNearbyRestaurantSelected;

  const TableBookingScreen({
    super.key,
    required this.restaurantName,
    required this.timeSlot,
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
  late TextEditingController _timeCtrl;
  late int _guests;
  DateTime _selectedDate = DateTime.now();
  bool _confirmed = false;
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _timeCtrl   = TextEditingController(text: widget.timeSlot);
    _guests     = widget.numberOfGuests;
    _confirmed  = widget.isVoiceConfirmed;
    _bookingId  = widget.bookingId ??
        (widget.isVoiceConfirmed
            ? 'TBL${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
            : null);
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_timeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a time slot', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _confirmed = true;
      _bookingId ??= 'TBL${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    });
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Book a Table',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
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
          // Confirmed badge
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3A2A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.table_restaurant_rounded,
                color: Color(0xFF2ECC71), size: 56),
          )
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                  duration: 800.ms),
          const SizedBox(height: 24),

          Text('Table Booked! 🥂',
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          // Booking summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _bookingRow(Icons.restaurant_rounded,
                    widget.restaurantName.isNotEmpty ? widget.restaurantName : 'Restaurant'),
                const SizedBox(height: 12),
                _bookingRow(Icons.access_time_rounded, _timeCtrl.text.isNotEmpty ? _timeCtrl.text : widget.timeSlot),
                const SizedBox(height: 12),
                _bookingRow(Icons.people_alt_rounded, '$_guests Guests'),
                const SizedBox(height: 12),
                _bookingRow(Icons.calendar_today_rounded,
                    widget.bookingDate ?? '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                const Divider(height: 28, color: Color(0xFF2C2C3E)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_number_rounded,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Booking ID: $_bookingId',
                        style: GoogleFonts.outfit(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 28),

          // Voice confirmation badge
          if (widget.isVoiceConfirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Reserved via Voice AI',
                      style: GoogleFonts.outfit(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Done',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
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
        Text(label,
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
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
          // Restaurant header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5E6D3), Color(0xFFFDF5E6)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.restaurant_rounded,
                      color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurantName.isNotEmpty
                            ? widget.restaurantName
                            : 'Selected Restaurant',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppTheme.textPrimary),
                      ),
                      Text('Table Reservation',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 28),

          // Alternative slots (test case 2)
          if (widget.alternativeSlots.isNotEmpty) ...[
            _sectionLabel('Available Time Slots'),
            _buildSlotChips(),
            const SizedBox(height: 24),
          ],

          // Nearby restaurants (test case 3)
          if (widget.nearbyRestaurants.isNotEmpty) ...[
            _sectionLabel('Nearby Restaurants'),
            _buildNearbyRestaurants(),
            const SizedBox(height: 24),
          ],

          _sectionLabel('Date'),
          GestureDetector(
            onTap: _pickDate,
            child: _inputFieldBox(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: GoogleFonts.outfit(
                        fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Time Slot'),
          _inputFieldBox(
            child: TextField(
              controller: _timeCtrl,
              style: GoogleFonts.outfit(
                  fontSize: 16, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 6:45 PM',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.access_time_rounded,
                    color: AppTheme.primary, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Number of Guests'),
          _inputFieldBox(
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Text('$_guests Guests',
                    style: GoogleFonts.outfit(
                        fontSize: 16, color: AppTheme.textPrimary)),
                const Spacer(),
                _GuestButton(
                  icon: Icons.remove_rounded,
                  onTap: _guests > 1 ? () => setState(() => _guests--) : null,
                ),
                const SizedBox(width: 16),
                _GuestButton(
                  icon: Icons.add_rounded,
                  onTap: _guests < 20 ? () => setState(() => _guests++) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_restaurant_rounded),
                  const SizedBox(width: 10),
                  Text('Confirm Booking',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Slot chips ────────────────────────────────────────────────────────────
  Widget _buildSlotChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.alternativeSlots.map((slot) {
        return GestureDetector(
          onTap: () {
            setState(() => _timeCtrl.text = slot);
            widget.onAlternativeSlotSelected?.call(slot);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(slot,
                    style: GoogleFonts.outfit(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Nearby restaurants ────────────────────────────────────────────────────
  Widget _buildNearbyRestaurants() {
    return Column(
      children: widget.nearbyRestaurants.map((r) {
        return GestureDetector(
          onTap: () => widget.onNearbyRestaurantSelected?.call(r),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${r.cuisine} • ${r.area}',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF39C12), size: 16),
                    const SizedBox(width: 4),
                    Text(r.rating.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 80.ms);
      }).toList(),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textSecondary)),
    );
  }

  Widget _inputFieldBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: child,
    );
  }
}

class _GuestButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _GuestButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.primary : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
