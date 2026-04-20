// lib/screens/customer/booking_receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';

class BookingReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingReceiptScreen({
    super.key,
    required this.bookingData,
  });

  @override
  State<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends State<BookingReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    final booking = widget.bookingData;
    final bookingDate = DateTime.parse(booking['bookingDate']);
    final formattedDate = DateFormat('MMMM d, yyyy (EEEE)').format(bookingDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Receipt', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Booking Confirmed!',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Text('Your reservation has been received',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'We will contact you shortly to confirm your reservation. Please save this receipt for your records.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Booking Details
            Text('Booking Details',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _ReceiptCard(
              children: [
                _ReceiptRow('Oasis', booking['oasis']),
                _ReceiptRow('Package', booking['package']),
                _ReceiptRow('Booking Date', formattedDate),
                _ReceiptRow('Session', booking['session']),
                _ReceiptRow('Number of Guests', '${booking['pax']} guest(s)'),
              ],
            ),
            const SizedBox(height: 20),

            // Guest Information
            Text('Guest Information',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _ReceiptCard(
              children: [
                _ReceiptRow('Name', booking['customerName']),
                _ReceiptRow('Email', booking['customerEmail']),
                _ReceiptRow('Contact', booking['customerContact']),
              ],
            ),
            const SizedBox(height: 20),

            // Add-ons (if any)
            if ((booking['addons'] as List?)?.isNotEmpty ?? false) ...[
              Text('Add-ons',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _ReceiptCard(
                children: (booking['addons'] as List)
                    .map((addon) => _ReceiptRow('•', addon as String))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Payment Information
            Text('Payment Information',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _ReceiptCard(
              children: [
                _ReceiptRow('Payment Method', booking['paymentMethod']),
                _ReceiptRow(
                  'Down Payment',
                  '₱${(booking['downpayment'] as num).toStringAsFixed(2)}',
                  isHighlight: true,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Pending Confirmation',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Important Notes
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text('Important Notes',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Your booking is pending confirmation from our team\n'
                    '• You will receive a confirmation email shortly\n'
                    '• Full payment is required before your visit\n'
                    '• Cancellation must be done 24 hours in advance',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Share receipt or print
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt feature coming soon')),
                  );
                },
                icon: const Icon(Icons.share, size: 20),
                label: Text('Share Receipt',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                icon: const Icon(Icons.home, size: 20),
                label: Text('Back to Home',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/my-bookings');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side:
                      BorderSide(color: AppColors.textSecondary.withOpacity(0.3), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('View My Bookings',
                    style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final List<Widget> children;

  const _ReceiptCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          children.length,
          (i) => Column(
            children: [
              children[i],
              if (i < children.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _ReceiptRow(this.label, this.value, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                  color: isHighlight ? AppColors.primary : AppColors.textPrimary)),
        ),
      ],
    );
  }
}
