// lib/screens/admin/inventory_management_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});
  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  List<InventoryModel> _items = [];
  bool _loading = true;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.get('/api/admin/inventory');
      if (result is Map && result['inventory'] is List) {
        setState(() {
          _items = (result['inventory'] as List).map((i) => InventoryModel.fromJson(i)).toList();
          _loading = false;
        });
      } else if (result is List) {
        setState(() {
          _items = result.map((i) => InventoryModel.fromJson(i)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error fetching inventory: $e');
      setState(() => _loading = false);
    }
  }

  List<InventoryModel> get _filtered =>
      _showLowStockOnly ? _items.where((i) => i.isLowStock).toList() : _items;

  void _showAddEditDialog({InventoryModel? item}) {
    final itemCtrl = TextEditingController(text: item?.item ?? '');
    final qtyCtrl = TextEditingController(text: item?.quantity.toString() ?? '');
    final unitCtrl = TextEditingController(text: item?.unit ?? '');
    final alertCtrl = TextEditingController(text: item?.lowStockAlert.toString() ?? '5');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item == null ? 'Add Inventory Item' : 'Edit Item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: itemCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: unitCtrl,
                  decoration: const InputDecoration(labelText: 'Unit (e.g. Liters, Boxes)')),
              const SizedBox(height: 12),
              TextFormField(
                  controller: alertCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Low Stock Alert Threshold')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final body = {
                'item': itemCtrl.text,
                'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                'unit': unitCtrl.text,
                'lowStockAlert': int.tryParse(alertCtrl.text) ?? 5,
              };
              if (item == null) {
                await ApiService.post('/api/admin/inventory', body);
              } else {
                await ApiService.put('/api/admin/inventory/${item.id}', body);
              }
              _fetchInventory();
            },
            child: Text(item == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showUseDialog(InventoryModel item) {
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Use "${item.item}"',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${item.quantity} ${item.unit ?? ''}',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextFormField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity Used'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.post('/api/admin/inventory/${item.id}/use',
                  {'quantityUsed': int.tryParse(qtyCtrl.text) ?? 1});
              _fetchInventory();
            },
            child: const Text('Confirm Use'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(InventoryModel item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Item',
      message: 'Delete "${item.item}"?',
    );
    if (confirmed == true) {
      await ApiService.delete('/api/admin/inventory/${item.id}');
      _fetchInventory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _items.where((i) => i.isLowStock).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchInventory)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (lowStockCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber, color: AppColors.error, size: 14),
                        const SizedBox(width: 4),
                        Text('$lowStockCount low stock',
                            style: GoogleFonts.poppins(
                                color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Text('Low stock only',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                    Switch(
                      value: _showLowStockOnly,
                      onChanged: (v) => setState(() => _showLowStockOnly = v),
                      activeColor: AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _filtered.isEmpty
                    ? EmptyState(
                        message: _showLowStockOnly
                            ? 'No low stock items!'
                            : 'No inventory items',
                        icon: Icons.inventory_2_outlined)
                    : RefreshIndicator(
                        onRefresh: _fetchInventory,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final item = _filtered[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: item.isLowStock
                                    ? Border.all(color: AppColors.error.withOpacity(0.4))
                                    : null,
                                boxShadow: [BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (item.isLowStock ? AppColors.error : AppColors.success)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.inventory_2,
                                        color: item.isLowStock ? AppColors.error : AppColors.success,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(item.item,
                                                  style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w700, fontSize: 14)),
                                            ),
                                            if (item.isLowStock)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text('Low Stock',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        color: AppColors.error,
                                                        fontWeight: FontWeight.w600)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text('Qty: ',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 13, color: AppColors.textSecondary)),
                                            Text(
                                              '${item.quantity} ${item.unit ?? ''}',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: item.isLowStock ? AppColors.error : AppColors.textPrimary),
                                            ),
                                            Text(' / Alert: ${item.lowStockAlert}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        Text(item.itemId,
                                            style: GoogleFonts.poppins(
                                                fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'use', child: Text('Log Usage')),
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                    onSelected: (v) {
                                      if (v == 'use') _showUseDialog(item);
                                      if (v == 'edit') _showAddEditDialog(item: item);
                                      if (v == 'delete') _deleteItem(item);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
