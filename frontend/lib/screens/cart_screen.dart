import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    'ASAP',
    '12:00 PM', '12:30 PM', '1:00 PM', '1:30 PM',
    '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM', '9:00 PM'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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
        title: Text('Your Cart',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => Visibility(
              visible: cart.items.isNotEmpty,
              child: TextButton(
                onPressed: cart.clearCart,
                child: Text('Clear',
                    style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.orderPlaced) return _buildOrderSuccess(context, cart);
          if (cart.items.isEmpty) return _buildEmptyCart(context);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOrderTypeToggle(cart),
                    ...cart.items.map((item) => _buildCartItem(context, item, cart)),
                    const SizedBox(height: 24),
                    if (cart.orderType.toLowerCase() == 'takeaway') ...[
                      _buildTakeawayDetails(),
                      const SizedBox(height: 24),
                    ],
                    _buildPaymentSelector(cart),
                    const SizedBox(height: 24),
                    _buildOrderSummary(cart),
                  ],
                ),
              ),
              _buildCheckoutBar(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderTypeToggle(CartProvider cart) {
    final isDelivery = cart.orderType.toLowerCase() == 'delivery';
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => cart.setOrderType('Delivery'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDelivery ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('Delivery',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: isDelivery ? Colors.white : AppTheme.textSecondary)),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => cart.setOrderType('Takeaway'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isDelivery ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('Takeaway',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: !isDelivery ? Colors.white : AppTheme.textSecondary)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                Text(item.restaurantName,
                    style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary, fontSize: 12)),
                if (item.price > 0)
                  Text('₹${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                          color: AppTheme.primary, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                onTap: () => cart.decrementItem(item.id),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary)),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onTap: () => cart.addItem(
                  id: item.id,
                  name: item.name,
                  price: item.price,
                  restaurantName: item.restaurantName,
                  restaurantId: item.restaurantId,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildTakeawayDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Takeaway Details',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text('Time Slot', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider),
                  ),
                  child: Text(slot,
                      style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelector(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ...PaymentMethod.values.map((method) {
            if (cart.orderType.toLowerCase() == 'takeaway' && method != PaymentMethod.cashOnDelivery) {
              return const SizedBox.shrink();
            }
            final selected = cart.paymentMethod == method;
            return GestureDetector(
              onTap: () => cart.setPaymentMethod(method),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(method.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(method.label,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: selected ? AppTheme.primary : AppTheme.textPrimary)),
                    const Spacer(),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', '₹${cart.totalPrice.toStringAsFixed(0)}'),
          _summaryRow('Delivery', 'FREE'),
          _summaryRow('Taxes', '₹${(cart.totalPrice * 0.05).toStringAsFixed(0)}'),
          const Divider(height: 24, color: AppTheme.divider),
          _summaryRow(
            'Total',
            '₹${(cart.totalPrice * 1.05).toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
                  fontSize: bold ? 16 : 14)),
          Text(value,
              style: GoogleFonts.outfit(
                  color: bold ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (cart.orderType.toLowerCase() == 'takeaway') {
              if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _selectedTimeSlot == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all Takeaway details')),
                );
                return;
              }
            }
            cart.placeOrder(
              customerName: _nameCtrl.text.trim(),
              customerPhone: _phoneCtrl.text.trim(),
              timeSlot: _selectedTimeSlot,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_rounded),
              const SizedBox(width: 10),
              Text(
                'Place Order • ${cart.paymentMethod.label}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Your cart is empty',
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Use voice commands to add items!',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSuccess(BuildContext context, CartProvider cart) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3A2A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF2ECC71), size: 56),
          ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0),
              curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 24),
          Text('Order Placed! 🎉',
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Order ID: ${cart.lastOrderId}',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(cart.paymentMethod.label,
              style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              cart.resetOrder();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text('Back to Home',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Icon(icon, size: 16, color: AppTheme.primary),
      ),
    );
  }
}
