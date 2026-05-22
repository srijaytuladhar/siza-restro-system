import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../providers/booking_provider.dart';
import '../providers/order_provider.dart';
import '../providers/notification_provider.dart';
import 'thank_you_screen.dart';
import '../utils/constants.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final Map<int, bool> _expandedMockControls = {};

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingProvider).activeBooking;
    final orderState = ref.watch(orderProvider);

    ref.listen(notificationProvider, (previous, next) {
      if (next.latestNotification != null && next.latestNotification != previous?.latestNotification) {
        final notif = next.latestNotification!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        notif.message,
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16161E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Also refresh orders to sync state
        final activeBooking = ref.read(bookingProvider).activeBooking;
        if (activeBooking != null) {
          ref.read(orderProvider.notifier).fetchOrders(activeBooking.id);
        }
        
        // Clear latest notification to avoid repeating
        ref.read(notificationProvider.notifier).clearLatestNotification();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        elevation: 0,
        title: Text(
          'Track Your Orders',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              if (booking != null) {
                ref.read(orderProvider.notifier).fetchOrders(booking.id);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: booking == null
          ? Center(
              child: Text(
                'No active booking found.',
                style: GoogleFonts.outfit(color: Colors.white38),
              ),
            )
          : orderState.isLoading && orderState.orders.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : orderState.orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            'No orders placed yet',
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your orders will show up here once placed.',
                            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orderState.orders.length,
                      itemBuilder: (context, index) {
                        final order = orderState.orders[index];
                        return _buildOrderTrackingCard(context, ref, order);
                      },
                    ),
    );
  }

  Widget _buildOrderTrackingCard(BuildContext context, WidgetRef ref, OrderModel order) {
    final showMock = _expandedMockControls[order.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Order Number, Cost and Dropdown Trigger
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} items  •  ${Constants.currencySymbol}${order.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                    ),
                  ],
                ),
                
                // Demo control button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _expandedMockControls[order.id] = !showMock;
                    });
                  },
                  icon: Icon(
                    showMock ? Icons.expand_less_rounded : Icons.construction_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                  label: Text(
                    showMock ? 'Hide Control' : 'Simulate Kitchen',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Kitchen Admin Simulator Control Drawer
          if (showMock)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEMO: SIMULATE KITCHEN ACTIONS',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMockStatusButton(ref, order.id, OrderStatus.PENDING, 'Pending', Colors.grey),
                      const SizedBox(width: 8),
                      _buildMockStatusButton(ref, order.id, OrderStatus.PREPARING, 'Prepare', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMockStatusButton(ref, order.id, OrderStatus.READY, 'Ready', Colors.orange),
                      const SizedBox(width: 8),
                      _buildMockStatusButton(ref, order.id, OrderStatus.SERVED, 'Serve', const Color(0xFF2ECC71)),
                    ],
                  ),
                ],
              ),
            ),

          // Payment Status Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      order.paymentStatus == 'PAID' 
                          ? Icons.payment_rounded 
                          : Icons.pending_actions_rounded,
                      size: 16,
                      color: order.paymentStatus == 'PAID' ? const Color(0xFF2ECC71) : Colors.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.paymentStatus == 'PAID' ? 'Paid via ${order.paymentMethod}' : 'Payment Pending',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: order.paymentStatus == 'PAID' ? const Color(0xFF2ECC71) : Colors.amber,
                      ),
                    ),
                  ],
                ),
                if (order.paymentStatus != 'PAID')
                  ElevatedButton.icon(
                    onPressed: order.status == OrderStatus.SERVED
                        ? () {
                            _showPaymentBottomSheet(context, ref, order);
                          }
                        : null,
                    icon: const Icon(Icons.credit_card_rounded, size: 14),
                    label: Text(
                      'Pay Now',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white.withOpacity(0.06),
                      disabledForegroundColor: Colors.white30,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: Colors.white10),
          ),

          // Stepper Timeline Status Tracker
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTimelineStep(
                  'Order Received', 
                  'We have received your order and sent it to the kitchen.', 
                  isActive: _isStepActive(order.status, OrderStatus.PENDING),
                  isCompleted: _isStepCompleted(order.status, OrderStatus.PENDING),
                  isFirst: true,
                ),
                _buildTimelineStep(
                  'Preparing in Kitchen', 
                  'Chef is preparing your fresh meal now.', 
                  isActive: _isStepActive(order.status, OrderStatus.PREPARING),
                  isCompleted: _isStepCompleted(order.status, OrderStatus.PREPARING),
                ),
                _buildTimelineStep(
                  'Ready to Serve', 
                  'Your food is ready! A server will bring it shortly.', 
                  isActive: _isStepActive(order.status, OrderStatus.READY),
                  isCompleted: _isStepCompleted(order.status, OrderStatus.READY),
                ),
                _buildTimelineStep(
                  'Served', 
                  'Enjoy your delicious meal!', 
                  isActive: _isStepActive(order.status, OrderStatus.SERVED),
                  isCompleted: _isStepCompleted(order.status, OrderStatus.SERVED),
                  isLast: true,
                ),
              ],
            ),
          ),
          
          // Order Summary Items (Accordion style details)
          ExpansionTile(
            title: Text(
              'View Order Details',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w500),
            ),
            iconColor: Colors.amber,
            collapsedIconColor: Colors.white38,
            children: [
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity}x  ${item.menuItemName}',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${Constants.currencySymbol}${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockStatusButton(
    WidgetRef ref, 
    int orderId, 
    OrderStatus status, 
    String label, 
    Color color
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(orderProvider.notifier).mockKitchenStatusUpdate(orderId, status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  bool _isStepActive(OrderStatus current, OrderStatus step) {
    return current == step;
  }

  bool _isStepCompleted(OrderStatus current, OrderStatus step) {
    const list = [OrderStatus.PENDING, OrderStatus.PREPARING, OrderStatus.READY, OrderStatus.SERVED];
    return list.indexOf(current) >= list.indexOf(step);
  }

  Widget _buildTimelineStep(
    String title, 
    String subtitle, {
    required bool isActive, 
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final dotColor = isActive
        ? Colors.amber
        : isCompleted
            ? Colors.amber.withOpacity(0.6)
            : Colors.white12;
            
    final titleColor = isActive 
        ? Colors.white 
        : isCompleted 
            ? Colors.white70 
            : Colors.white30;
            
    final subColor = isActive 
        ? Colors.white70 
        : isCompleted 
            ? Colors.white38 
            : Colors.white24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper dots and connector lines
        Column(
          children: [
            // Upper line
            Container(
              width: 2,
              height: 16,
              color: isFirst ? Colors.transparent : Colors.amber.withOpacity(isCompleted ? 0.6 : 0.05),
            ),
            // Middle Dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 16 : 10,
              height: isActive ? 16 : 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: Colors.amber[200]!, width: 2) : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
            // Lower line
            Container(
              width: 2,
              height: 32,
              color: isLast ? Colors.transparent : Colors.amber.withOpacity(isCompleted && !isActive ? 0.6 : 0.05),
            ),
          ],
        ),
        const SizedBox(width: 20),
        
        // Text details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentBottomSheet(BuildContext context, WidgetRef ref, OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select Payment Method',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order #${order.id}  •  Amount: ${Constants.currencySymbol}${order.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Cash option
                  _buildPaymentOption(
                    context,
                    ref,
                    order,
                    title: 'Pay with Cash',
                    subtitle: 'Request a server to collect cash at your table',
                    icon: Icons.money_rounded,
                    color: const Color(0xFF2ECC71),
                    onTap: () async {
                      Navigator.pop(context);
                      _processMockPayment(context, ref, order, 'CASH');
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Digital wallet option
                  _buildPaymentOption(
                    context,
                    ref,
                    order,
                    title: 'Digital Wallet (Simulated)',
                    subtitle: 'Pay instantly via Fonepay / eSewa / Khalti QR',
                    icon: Icons.qr_code_scanner_rounded,
                    color: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      _showDigitalWalletDialog(context, ref, order);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    WidgetRef ref,
    OrderModel order, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Future<void> _processMockPayment(BuildContext context, WidgetRef ref, OrderModel order, String method) async {
    // Show Loading with safety mechanisms to prevent race conditions (spinning loader hangs)
    BuildContext? dialogContext;
    bool isDone = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) {
        dialogContext = dContext;
        if (isDone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dContext.mounted) {
              Navigator.pop(dContext);
            }
          });
        }
        return const Center(child: CircularProgressIndicator(color: Colors.amber));
      },
    );

    final success = await ref.read(orderProvider.notifier).processOrderPayment(
      order.id,
      method,
      order.totalAmount,
    );

    isDone = true;
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.pop(dialogContext!);
    }

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment processed successfully! Order status updated.', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF2ECC71),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ThankYouScreen(),
        ),
      );
    } else if (context.mounted) {
      final error = ref.read(orderProvider).errorMessage ?? 'Payment failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      ref.read(orderProvider.notifier).clearError();
    }
  }

  void _showDigitalWalletDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF16161E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header representing Fonepay / Wallet SDK
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FONEPAY SECURE PAY',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.red[600],
                        letterSpacing: 1,
                      ),
                    ),
                    const Icon(Icons.security, color: Colors.green, size: 16),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                
                // Merchant Details
                Text(
                  'Merchant: Siza Restro',
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'Amount: ${Constants.currencySymbol}${order.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.amber),
                ),
                const SizedBox(height: 20),
                
                // Simulated QR Code or processing icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 150,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Scan the QR or click complete to simulate success',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _processMockPayment(context, ref, order, 'DIGITAL_WALLET');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Complete Pay',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
