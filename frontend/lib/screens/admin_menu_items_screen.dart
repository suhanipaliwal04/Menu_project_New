import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../providers/admin_provider.dart';

class AdminMenuItemsScreen extends StatefulWidget {
  const AdminMenuItemsScreen({super.key});

  @override
  State<AdminMenuItemsScreen> createState() => _AdminMenuItemsScreenState();
}

class _AdminMenuItemsScreenState extends State<AdminMenuItemsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchMenuItems();
    });
  }

  // ── Delete (called from Dismissible onDismissed) ──────────────────────────
  // ── Edit Bottom Sheet ───────────────────────────────────────────────────────
  void _showEditSheet(BuildContext context, AdminMenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditItemSheet(item: item),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Consumer<AdminProvider>(
          builder: (_, provider, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Menu Items', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 17)),
              if (provider.selectedRestaurant != null)
                Text(provider.selectedRestaurant!.restaurantName,
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          Consumer<AdminProvider>(
            builder: (_, provider, __) => IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
              onPressed: provider.state == AdminState.loading ? null : provider.fetchMenuItems,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.state == AdminState.loading && provider.menuItems.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (provider.state == AdminState.error && provider.menuItems.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                const SizedBox(height: 12),
                Text(provider.errorMessage ?? 'Failed to load items',
                    style: GoogleFonts.outfit(color: AppTheme.error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.fetchMenuItems,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: Text('Retry', style: GoogleFonts.outfit(color: Colors.white)),
                ),
              ]),
            );
          }

          // Filter items by search
          final filtered = provider.menuItems
              .where((i) =>
                  _searchQuery.isEmpty ||
                  i.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  i.sectionName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          // Group by section
          final Map<String, List<AdminMenuItem>> grouped = {};
          for (final item in filtered) {
            grouped.putIfAbsent(item.sectionName, () => []).add(item);
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: TextField(
                    style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search items or sections…',
                      hintStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _pill('${provider.menuItems.length} total', AppTheme.primary),
                    const SizedBox(width: 8),
                    _pill('${provider.menuItems.where((i) => i.isVeg).length} veg 🥦', const Color(0xFF27AE60)),
                    const SizedBox(width: 8),
                    _pill('${provider.menuItems.where((i) => !i.isAvailable).length} unavailable', AppTheme.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No items found.', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.fetchMenuItems,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 80, top: 4),
                      children: grouped.entries.map((entry) {
                        return _buildSectionGroup(context, entry.key, entry.value, provider);
                      }).toList(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionGroup(
      BuildContext context, String section, List<AdminMenuItem> items, AdminProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(section,
                  style: GoogleFonts.outfit(
                      color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text('${items.length} items',
                style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
          ]),
        ),
        ...items.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          return _buildItemTile(context, item, provider)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 30 * idx.clamp(0, 15)))
              .slideX(begin: 0.05, end: 0);
        }),
      ],
    );
  }

  Widget _buildItemTile(BuildContext context, AdminMenuItem item, AdminProvider provider) {
    return Dismissible(
      key: Key(item.itemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        bool confirmed = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Delete?', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            content: Text('Delete "${item.itemName}"?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary))),
              TextButton(onPressed: () { confirmed = true; Navigator.pop(ctx, true); }, child: Text('Delete', style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold))),
            ],
          ),
        );
        return confirmed;
      },
      onDismissed: (_) async {
        await provider.deleteMenuItem(item.itemId);
      },
      child: GestureDetector(
        onTap: () => _showEditSheet(context, item),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isAvailable ? AppTheme.divider : AppTheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Veg indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isVeg ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                  border: Border.all(color: item.isVeg ? const Color(0xFF27AE60) : const Color(0xFFE74C3C)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: GoogleFonts.outfit(
                            color: item.isAvailable ? AppTheme.textPrimary : AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: item.isAvailable ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (!item.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Unavail.', style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text('₹${item.price.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                      if (item.calories != null) ...[
                        const SizedBox(width: 8),
                        Text('${item.calories} kcal',
                            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                      if (item.healthScore != null) ...[
                        const SizedBox(width: 8),
                        Text('⭐ ${item.healthScore}/10',
                            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit Item Bottom Sheet ────────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  final AdminMenuItem item;
  const _EditItemSheet({required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _healthScoreCtrl;
  late bool _isVeg;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.itemName);
    _descCtrl = TextEditingController(text: widget.item.description ?? '');
    _priceCtrl = TextEditingController(text: widget.item.price.toStringAsFixed(0));
    _healthScoreCtrl = TextEditingController(text: widget.item.healthScore?.toString() ?? '');
    _isVeg = widget.item.isVeg;
    _isAvailable = widget.item.isAvailable;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _healthScoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Item name cannot be empty', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final desc = _descCtrl.text.trim();
    final hsStr = _healthScoreCtrl.text.trim();
    final hs = hsStr.isNotEmpty ? int.tryParse(hsStr) : null;

    final updates = <String, dynamic>{
      'item_name': name,
      if (price != null) 'price': price,
      'is_veg': _isVeg,
      'is_available': _isAvailable,
      'description': desc.isNotEmpty ? desc : null,
      if (hs != null) 'health_score': hs,
    };

    final success = await context.read<AdminProvider>().updateMenuItem(widget.item.itemId, updates);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Item updated!' : context.read<AdminProvider>().errorMessage ?? 'Update failed',
            style: GoogleFonts.outfit()),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit Item', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(widget.item.sectionName, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),

            // Name field
            _buildField('Item Name', _nameCtrl),
            const SizedBox(height: 12),
            _buildField('Description', _descCtrl, maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildField('Price (₹)', _priceCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildField('Health (1-10)', _healthScoreCtrl, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),

            // Toggles
            Row(children: [
              Expanded(
                child: _buildToggle(
                  label: 'Vegetarian',
                  value: _isVeg,
                  activeColor: const Color(0xFF27AE60),
                  icon: Icons.eco_rounded,
                  onChanged: (v) => setState(() => _isVeg = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggle(
                  label: 'Available',
                  value: _isAvailable,
                  activeColor: AppTheme.primary,
                  icon: Icons.check_circle_rounded,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            Consumer<AdminProvider>(
              builder: (_, provider, __) => ElevatedButton(
                onPressed: provider.state == AdminState.loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: provider.state == AdminState.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required Color activeColor,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? activeColor.withValues(alpha: 0.4) : AppTheme.divider),
        ),
        child: Row(children: [
          Icon(icon, color: value ? activeColor : AppTheme.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.outfit(color: value ? activeColor : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
    );
  }
}
