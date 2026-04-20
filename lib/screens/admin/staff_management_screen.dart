// lib/screens/admin/staff_management_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<StaffModel> _staff = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.get('/api/admin/staff');
      if (result is Map && result['staff'] is List) {
        setState(() {
          _staff = (result['staff'] as List).map((s) => StaffModel.fromJson(s)).toList();
          _loading = false;
        });
      } else if (result is List) {
        setState(() {
          _staff = result.map((s) => StaffModel.fromJson(s)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error fetching staff: $e');
      setState(() => _loading = false);
    }
  }

  List<StaffModel> get _filtered => _staff
      .where((s) =>
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.position.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  void _showStaffDialog({StaffModel? staff}) {
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final emailCtrl = TextEditingController(text: staff?.email ?? '');
    final passwordCtrl = TextEditingController();
    String role = staff?.role ?? 'staff';
    String position = staff?.position ?? 'Housekeeper';
    String status = staff?.status ?? 'Active';

    final positions = ['Receptionist', 'Housekeeper', 'Manager', 'Maintenance', 'Chef', 'Other'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(staff == null ? 'Add Staff' : 'Edit Staff',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                if (staff == null)
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                if (staff == null) const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['staff', 'admin']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setModal(() => role = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: position,
                  decoration: const InputDecoration(labelText: 'Position'),
                  items: positions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setModal(() => position = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Active', 'Disabled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModal(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final body = {
                  'name': nameCtrl.text,
                  'email': emailCtrl.text,
                  'role': role,
                  'position': position,
                  'status': status,
                  if (staff == null && passwordCtrl.text.isNotEmpty)
                    'password': passwordCtrl.text,
                };
                if (staff == null) {
                  await ApiService.post('/api/admin/staff', body);
                } else {
                  await ApiService.put('/api/admin/staff/${staff.id}', body);
                }
                _fetchStaff();
              },
              child: Text(staff == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(StaffModel staff) async {
    final newStatus = staff.status == 'Active' ? 'Disabled' : 'Active';
    await ApiService.patch('/api/admin/staff/${staff.id}/status', {'status': newStatus});
    _fetchStaff();
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Staff',
      message: 'Delete "${staff.name}"? This cannot be undone.',
    );
    if (confirmed == true) {
      await ApiService.delete('/api/admin/staff/${staff.id}');
      _fetchStaff();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Management', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStaff)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStaffDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: TextFormField(
              decoration: const InputDecoration(
                hintText: 'Search staff...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _filtered.isEmpty
                    ? const EmptyState(message: 'No staff found', icon: Icons.people_outlined)
                    : RefreshIndicator(
                        onRefresh: _fetchStaff,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final s = _filtered[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    child: Text(s.name[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(s.name,
                                                  style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w700, fontSize: 14)),
                                            ),
                                            StatusBadge(s.status),
                                          ],
                                        ),
                                        Text(s.email,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12, color: AppColors.textSecondary)),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.info.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(s.position,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 11, color: AppColors.info,
                                                      fontWeight: FontWeight.w600)),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(s.staffId,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(
                                          value: 'toggle',
                                          child: Text(s.status == 'Active' ? 'Disable' : 'Enable')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                    onSelected: (v) {
                                      if (v == 'edit') _showStaffDialog(staff: s);
                                      if (v == 'toggle') _toggleStatus(s);
                                      if (v == 'delete') _deleteStaff(s);
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
