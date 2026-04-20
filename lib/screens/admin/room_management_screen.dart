// lib/screens/admin/room_management_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});
  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  List<RoomModel> _rooms = [];
  bool _loading = true;
  String _filter = 'All';

  final List<String> _statusFilters = ['All', 'Available', 'Booked', 'Maintenance'];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.get('/api/admin/rooms');
      if (result is List) {
        setState(() {
          _rooms = result.map((r) => RoomModel.fromJson(r)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<RoomModel> get _filtered =>
      _filter == 'All' ? _rooms : _rooms.where((r) => r.status == _filter).toList();

  void _showRoomDialog({RoomModel? room}) {
    final nameCtrl = TextEditingController(text: room?.name ?? '');
    final capacityCtrl = TextEditingController(text: room?.capacity.toString() ?? '');
    final priceCtrl = TextEditingController(text: room?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: room?.description ?? '');
    String status = room?.status ?? 'Available';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(room == null ? 'Add Room' : 'Edit Room',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Room Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price per Night (₱)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Available', 'Booked', 'Maintenance']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final body = {
                  'name': nameCtrl.text,
                  'capacity': int.tryParse(capacityCtrl.text) ?? 0,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'description': descCtrl.text,
                  'status': status,
                };
                if (room == null) {
                  await ApiService.post('/api/admin/rooms', body);
                } else {
                  await ApiService.put('/api/admin/rooms/${room.id}', body);
                }
                _fetchRooms();
              },
              child: Text(room == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Room',
      message: 'Are you sure you want to delete "${room.name}"?',
    );
    if (confirmed == true) {
      await ApiService.delete('/api/admin/rooms/${room.id}');
      _fetchRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room Management', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchRooms),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoomDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((f) {
                  final sel = f == _filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(f,
                            style: GoogleFonts.poppins(
                                color: sel ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _filtered.isEmpty
                    ? const EmptyState(message: 'No rooms found', icon: Icons.hotel_outlined)
                    : RefreshIndicator(
                        onRefresh: _fetchRooms,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final room = _filtered[i];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.hotel, color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(room.name,
                                                  style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w700, fontSize: 15)),
                                            ),
                                            StatusBadge(room.status),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.group, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text('${room.capacity} pax',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12, color: AppColors.textSecondary)),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.attach_money, size: 14, color: AppColors.textSecondary),
                                            Text(formatPeso(room.price),
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        if (room.description != null && room.description!.isNotEmpty)
                                          Text(room.description!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                    onSelected: (v) {
                                      if (v == 'edit') _showRoomDialog(room: room);
                                      if (v == 'delete') _deleteRoom(room);
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
