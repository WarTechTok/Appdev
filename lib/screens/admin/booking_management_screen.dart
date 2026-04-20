// lib/screens/admin/booking_management_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});
  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  List<BookingModel> _bookings = [];
  bool _loading = true;
  String _statusFilter = 'All';
  String _search = '';

  final _statuses = ['All', 'Pending', 'Confirmed', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _loading = true);
    try {
      debugPrint('Fetching bookings from /api/admin/bookings');
      final result = await ApiService.get('/api/admin/bookings', auth: true);
      
      debugPrint('API Response type: ${result.runtimeType}');
      debugPrint('API Response: $result');
      
      List<BookingModel> fetchedBookings = [];
      
      // Handle different response formats
      if (result is List) {
        fetchedBookings = result.map((b) => BookingModel.fromJson(b as Map<String, dynamic>)).toList();
      } else if (result is Map) {
        // Check various possible response structures
        if (result['bookings'] is List) {
          fetchedBookings = (result['bookings'] as List)
              .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
              .toList();
        } else if (result['data'] is List) {
          fetchedBookings = (result['data'] as List)
              .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
              .toList();
        } else if (result['success'] == false) {
          debugPrint('API Error: ${result['message'] ?? 'Unknown error'}');
        }
      }
      
      setState(() {
        _bookings = fetchedBookings;
        _loading = false;
        debugPrint('Loaded ${_bookings.length} bookings');
      });
    } catch (e, stack) {
      debugPrint('Error fetching bookings: $e');
      debugPrint('Stack trace: $stack');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    }
  }

  List<BookingModel> get _filtered => _bookings.where((b) {
        final matchStatus = _statusFilter == 'All' || b.status == _statusFilter;
        final matchSearch = _search.isEmpty ||
            b.customerName.toLowerCase().contains(_search.toLowerCase()) ||
            b.oasis.toLowerCase().contains(_search.toLowerCase());
        return matchStatus && matchSearch;
      }).toList();

  Future<void> _updateStatus(BookingModel booking, String newStatus) async {
    await ApiService.patch('/api/admin/bookings/${booking.id}/status', {'status': newStatus});
    _fetchBookings();
  }

  Future<void> _updatePayment(BookingModel booking, String newPaymentStatus) async {
    await ApiService.patch('/api/admin/bookings/${booking.id}/payment',
        {'paymentStatus': newPaymentStatus});
    _fetchBookings();
  }

  void _showBookingDetails(BookingModel b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: ctrl,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Booking Details',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  StatusBadge(b.status),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow('Customer', b.customerName),
              _DetailRow('Contact', b.customerContact),
              if (b.customerEmail != null) _DetailRow('Email', b.customerEmail!),
              _DetailRow('Oasis', b.oasis),
              _DetailRow('Package', b.package),
              _DetailRow('Date', DateFormat('MMMM d, yyyy (EEEE)').format(b.bookingDate)),
              _DetailRow('Guests', '${b.pax}'),
              _DetailRow('Downpayment', formatPeso(b.downpayment)),
              _DetailRow('Payment Method', b.paymentMethod),
              _DetailRow('Payment Status', b.paymentStatus),
              if (b.createdAt != null)
                _DetailRow('Booked on', formatDateTime(b.createdAt!)),
              const SizedBox(height: 20),
              Text('Update Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['Pending', 'Confirmed', 'Completed', 'Cancelled'].map((s) {
                  final isCurrent = b.status == s;
                  return GestureDetector(
                    onTap: isCurrent ? null : () {
                      Navigator.pop(context);
                      _updateStatus(b, s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isCurrent ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(s,
                          style: GoogleFonts.poppins(
                              color: isCurrent ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Update Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['Pending', 'Partial', 'Paid'].map((s) {
                  final isCurrent = b.paymentStatus == s;
                  return GestureDetector(
                    onTap: isCurrent ? null : () {
                      Navigator.pop(context);
                      _updatePayment(b, s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.success : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isCurrent ? AppColors.success : AppColors.border),
                      ),
                      child: Text(s,
                          style: GoogleFonts.poppins(
                              color: isCurrent ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchBookings)],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                        hintText: 'Search by name or oasis...', prefixIcon: Icon(Icons.search), isDense: true),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: _statuses.map((s) {
                      final sel = s == _statusFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(s,
                                style: GoogleFonts.poppins(
                                    color: sel ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _filtered.isEmpty
                    ? const EmptyState(message: 'No bookings found', icon: Icons.book_online_outlined)
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final b = _filtered[i];
                            return GestureDetector(
                              onTap: () => _showBookingDetails(b),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(b.customerName,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700, fontSize: 15)),
                                        ),
                                        StatusBadge(b.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.pool, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('${b.oasis} · ${b.package}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(DateFormat('MMM d, yyyy').format(b.bookingDate),
                                            style: GoogleFonts.poppins(
                                                fontSize: 12, color: AppColors.textSecondary)),
                                        const Spacer(),
                                        StatusBadge(b.paymentStatus),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.payments_outlined, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(formatPeso(b.downpayment),
                                            style: GoogleFonts.poppins(
                                                fontSize: 12, fontWeight: FontWeight.w600)),
                                        Text(' downpayment via ${b.paymentMethod}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
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

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
          ),
          const Text(': '),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
