import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class TableBookingScreen extends StatefulWidget {
  final String restaurantName;
  final String timeSlot;

  const TableBookingScreen({
    super.key,
    required this.restaurantName,
    required this.timeSlot,
  });

  @override
  State<TableBookingScreen> createState() => _TableBookingScreenState();
}

class _TableBookingScreenState extends State<TableBookingScreen> {
  late TextEditingController _timeCtrl;
  int _guests = 2;
  DateTime _selectedDate = DateTime.now();
  bool _confirmed = false;
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _timeCtrl = TextEditingController(text: widget.timeSlot);
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
      _bookingId = 'TBL${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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
                  child: const Icon(Icons.restaurant_rounded, color: AppTheme.primary, size: 28),
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

          _sectionLabel('Date'),
          GestureDetector(
            onTap: _pickDate,
            child: _inputFieldBox(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Time Slot'),
          _inputFieldBox(
            child: TextField(
              controller: _timeCtrl,
              style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 6:45 PM',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Number of Guests'),
          _inputFieldBox(
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Text('$_guests Guests',
                    style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3A2A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_restaurant_rounded,
                  color: Color(0xFF2ECC71), size: 56),
            ).animate().scale(
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
            Text(
              '${widget.restaurantName.isNotEmpty ? widget.restaurantName : "Restaurant"} • ${_timeCtrl.text} • $_guests Guests',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text('Booking ID: $_bookingId',
                style: GoogleFonts.outfit(
                    color: AppTheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              ),
              child: Text('Done',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
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
