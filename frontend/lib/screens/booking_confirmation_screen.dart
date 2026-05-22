import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../providers/order_provider.dart';
import 'menu_screen.dart';
import 'qr_scanner_screen.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  Future<bool> _showCancelBookingDialog(BuildContext context, String tableNumber) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(
              'Cancel Booking?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel your booking for $tableNumber? This will release the table and end your active session.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Booking',
              style: GoogleFonts.outfit(color: Colors.amber),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);
    final booking = bookingState.activeBooking;

    // Guard: If booking is somehow null, redirect back to scanner
    if (booking == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QrScannerScreen()),
        );
      });
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F13),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(booking.createdAt);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldCancel = await _showCancelBookingDialog(context, booking.tableNumber);
        if (shouldCancel && context.mounted) {
          await ref.read(bookingProvider.notifier).closeActiveBooking();
          if (context.mounted && ref.read(bookingProvider).activeBooking == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const QrScannerScreen()),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F13),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Checkmark Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ECC71).withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF2ECC71),
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Table Confirmed!',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your booking is active and linked to this device.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
  
                  // Booking Info Card (Glassmorphic look)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(context, 'Table Number', booking.tableNumber, isHighlight: true),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(context, 'Booking ID', '#${booking.id}'),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(context, 'Time', formattedDate),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(
                          context, 
                          'Status', 
                          booking.status.name, 
                          valueColor: const Color(0xFF2ECC71),
                          fontWeight: FontWeight.bold
                        ),
                      ],
                    ),
                  ),
  
                  const SizedBox(height: 48),
  
                  // CTA Button - Start Ordering
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Fetch order history for active booking session
                        ref.read(orderProvider.notifier).fetchOrders(booking.id);
                        
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MenuScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Ordering',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
  
                  const SizedBox(height: 16),
  
                  // Secondary Button - Cancel/Leave Table
                  TextButton(
                    onPressed: bookingState.isLoading
                        ? null
                        : () async {
                            await ref.read(bookingProvider.notifier).closeActiveBooking();
                            if (context.mounted && ref.read(bookingProvider).activeBooking == null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                              );
                            }
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[300],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: bookingState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                          )
                        : Text(
                            'Release Table / Leave',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, 
    String label, 
    String value, {
    bool isHighlight = false,
    Color? valueColor,
    FontWeight? fontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.white38,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isHighlight ? 20 : 15,
            fontWeight: fontWeight ?? (isHighlight ? FontWeight.bold : FontWeight.w500),
            color: valueColor ?? (isHighlight ? Colors.amber : Colors.white),
          ),
        ),
      ],
    );
  }
}
