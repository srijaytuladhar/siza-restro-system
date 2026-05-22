import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/menu_item_model.dart';
import '../providers/booking_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';
import 'qr_scanner_screen.dart';
import '../utils/constants.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingProvider).activeBooking;
    final menuState = ref.watch(menuProvider);
    final cartState = ref.watch(cartProvider);

    // Filter items based on query
    List<MenuItemModel> filteredItems = menuState.items.where((item) {
      final nameMatches = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatches = item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || descMatches;
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final tableNum = booking?.tableNumber ?? 'Table';
        final shouldCancel = await _showCancelBookingDialog(context, tableNum);
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF16161E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Cancel Booking',
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Siza Restro Menu',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (booking != null)
              Text(
                booking.tableNumber,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu_rounded, color: Colors.white),
            tooltip: 'Track Active Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderTrackingScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: menuState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : menuState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Failed to load menu',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(menuProvider.notifier).fetchMenu(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        child: Text('Retry', style: GoogleFonts.outfit(color: Colors.black)),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search dishes...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white30),
                          prefixIcon: const Icon(Icons.search, color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF16161E),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.amber.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ),

                    // Categories TabBar
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.amber,
                      labelColor: Colors.amber,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Starters'),
                        Tab(text: 'Mains'),
                        Tab(text: 'Drinks'),
                        Tab(text: 'Desserts'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tab View content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMenuCategoryList(filteredItems, MenuCategory.STARTERS),
                          _buildMenuCategoryList(filteredItems, MenuCategory.MAIN_COURSE),
                          _buildMenuCategoryList(filteredItems, MenuCategory.DRINKS),
                          _buildMenuCategoryList(filteredItems, MenuCategory.DESSERTS),
                        ],
                      ),
                    ),
                  ],
                ),
                
      // Floating Cart Summary Button
      floatingActionButton: cartState.totalCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(),
                  ),
                );
              },
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.black,
              label: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartState.totalCount}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View Basket',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${Constants.currencySymbol}${cartState.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              icon: const Icon(Icons.shopping_basket_rounded),
            )
          : null,
      ),
    );
  }

  Widget _buildMenuCategoryList(List<MenuItemModel> allItems, MenuCategory category) {
    final items = allItems.where((i) => i.category == category).toList();

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No dishes found in this category',
          style: GoogleFonts.outfit(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 88, top: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    final cartState = ref.watch(cartProvider);
    final cartItem = cartState.items[item.id];
    final quantity = cartItem?.quantity ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${Constants.currencySymbol}${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Action Buttons
          Column(
            children: [
              if (quantity > 0)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: Colors.amber),
                        onPressed: () {
                          ref.read(cartProvider.notifier).removeItem(item.id);
                        },
                      ),
                      Text(
                        '$quantity',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: Colors.amber),
                        onPressed: () {
                          ref.read(cartProvider.notifier).addItem(item);
                        },
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(item);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ADD',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
