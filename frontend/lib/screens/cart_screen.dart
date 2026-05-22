import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/booking_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import 'order_tracking_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final booking = ref.watch(bookingProvider).activeBooking;
    final orderState = ref.watch(orderProvider);

    final subtotal = cartState.totalAmount;
    final tax = subtotal * 0.13; // 13% standard tax
    final grandTotal = subtotal + tax;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        elevation: 0,
        title: Text(
          'Your Order Basket',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: cartState.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'Your basket is empty',
                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go back and add some delicious items!',
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final item = cartState.items.values.toList()[index];
                      return _buildCartItemCard(context, ref, item);
                    },
                  ),
                ),

                // Pricing Summary panel
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16161E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('VAT (13%)', '\$${tax.toStringAsFixed(2)}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Colors.white10),
                        ),
                        _buildSummaryRow(
                          'Total Amount', 
                          '\$${grandTotal.toStringAsFixed(2)}',
                          isBold: true,
                          valueColor: Colors.amber
                        ),
                        const SizedBox(height: 24),
                        
                        // Submit Order Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: orderState.isLoading || booking == null
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(orderProvider.notifier)
                                        .placeCartOrder(booking.id);
                                    
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Order Placed Successfully!', style: GoogleFonts.outfit()),
                                          backgroundColor: const Color(0xFF2ECC71),
                                        ),
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const OrderTrackingScreen(),
                                        ),
                                      );
                                    } else if (!success && context.mounted) {
                                      final error = ref.read(orderProvider).errorMessage ?? 'Order placement failed';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(error, style: GoogleFonts.outfit()),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      ref.read(orderProvider.notifier).clearError();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: orderState.isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                                    'Confirm & Place Order',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, WidgetRef ref, CartItem item) {
    final itemTotal = item.menuItem.price * item.quantity;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.menuItem.price.toStringAsFixed(2)} each',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${itemTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Increment/Decrement
          Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16, color: Colors.amber),
                  onPressed: () {
                    ref.read(cartProvider.notifier).removeItem(item.menuItem.id);
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: Colors.amber),
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(item.menuItem);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.white : Colors.white60,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? (isBold ? Colors.white : Colors.white70),
          ),
        ),
      ],
    );
  }
}
