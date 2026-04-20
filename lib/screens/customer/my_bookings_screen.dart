// lib/screens/customer/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final auth = context.read<AuthProvider>();
    
    // Check if user is logged in
    if (auth.user == null) {
      setState(() {
        _loading = false;
        _error = 'Please log in to view your bookings.';
      });
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final email = Uri.encodeComponent(auth.user!.email);
      final result = await ApiService.get(
          '/api/bookings/customer/$email',
          auth: false);
      if (result is List) {
        setState(() {
          _bookings = result.map((b) => BookingModel.fromJson(b)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _bookings = [];
          _loading = false;
          _error = result['message'];
        });
      }
    } catch (_) {
      setState(() { _loading = false; _error = 'Failed to fetch bookings.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: _loading
          ? const LoadingWidget(message: 'Loading your bookings...')
          : auth.user == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text('Please log in',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('to view your bookings',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('Go to Login'),
                      ),
                    ],
                  ),
                )
              : _bookings.isEmpty
                  ? EmptyState(message: _error ?? 'No bookings found.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _BookingCard(booking: _bookings[i]),
                    ),
      floatingActionButton: !_loading && auth.user != null
          ? FloatingActionButton(
              onPressed: _fetchBookings,
              tooltip: 'Refresh',
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.oasis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(booking.package,
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              StatusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _InfoRow(Icons.person_outlined, booking.customerName),
          _InfoRow(Icons.calendar_today_outlined,
              DateFormat('MMMM d, yyyy (EEEE)').format(booking.bookingDate)),
          _InfoRow(Icons.group_outlined, '${booking.pax} guest(s)'),
          _InfoRow(Icons.payments_outlined,
              'Downpayment: ${formatPeso(booking.downpayment)} via ${booking.paymentMethod}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Status:',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
              StatusBadge(booking.paymentStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
