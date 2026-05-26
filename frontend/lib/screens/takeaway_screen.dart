import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class TakeawayScreen extends StatefulWidget {
  final String restaurantName;
  final String pickupTime;
  final String itemName;

  const TakeawayScreen({
    super.key,
    required this.restaurantName,
    required this.pickupTime,
    required this.itemName,
  });

  @override
  State<TakeawayScreen> createState() => _TakeawayScreenState();
}

class _TakeawayScreenState extends State<TakeawayScreen> {
  late TextEditingController _timeCtrl;
  late TextEditingController _itemCtrl;
  late TextEditingController _noteCtrl;
  bool _confirmed = false;
  String? _takeawayId;

  @override
  void initState() {
    super.initState();
    _timeCtrl = TextEditingController(text: widget.pickupTime);
    _itemCtrl = TextEditingController(text: widget.itemName);
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _itemCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_timeCtrl.text.trim().isEmpty || _itemCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in the item and pickup time',
              style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _confirmed = true;
      _takeawayId = 'TWY${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    });
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
        title: Text('Takeaway Order',
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
          // Restaurant card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('🥡', style: TextStyle(fontSize: 28)),
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
                      Text('Takeaway / Self-Pickup',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 28),

          _sectionLabel('Item(s)'),
          _inputFieldBox(
            child: TextField(
              controller: _itemCtrl,
              style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Vegetable Sandwich',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.fastfood_rounded, color: AppTheme.primary, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Pickup Time'),
          _inputFieldBox(
            child: TextField(
              controller: _timeCtrl,
              style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 7:00 PM',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Note to Restaurant (optional)'),
          _inputFieldBox(
            child: TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Any special instructions...',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The restaurant will be notified about your pickup time.',
                    style: GoogleFonts.outfit(
                        color: AppTheme.primary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

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
                  const Text('🥡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text('Confirm Takeaway',
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
            const Text('🥡', style: TextStyle(fontSize: 80))
                .animate()
                .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 24),
            Text('Takeaway Confirmed! 🎉',
                style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  _infoRow('🍽️ Item', _itemCtrl.text),
                  const Divider(height: 16, color: AppTheme.divider),
                  _infoRow('🕐 Pickup', _timeCtrl.text),
                  const Divider(height: 16, color: AppTheme.divider),
                  _infoRow('📍 From',
                      widget.restaurantName.isNotEmpty ? widget.restaurantName : 'Restaurant'),
                  const Divider(height: 16, color: AppTheme.divider),
                  _infoRow('🔖 ID', _takeawayId ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 28),
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

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ],
    );
  }
}
