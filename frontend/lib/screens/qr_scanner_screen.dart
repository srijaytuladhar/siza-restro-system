import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/booking_provider.dart';
import '../providers/api_providers.dart';
import 'booking_confirmation_screen.dart';
import 'backend_config_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _mockController = TextEditingController();
  bool _isScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _mockController.dispose();
    super.dispose();
  }

  void _handleQrCode(String code) {
    if (_isScanned) return;
    
    // Resolve mock numbers or standard URLs/raw input to secure tokens
    String token = code.trim();
    
    // If the scanned code is a full URL, extract the last segment or parameter
    final Uri? uri = Uri.tryParse(token);
    if (uri != null) {
      final queryParam = uri.queryParameters['token'] ?? uri.queryParameters['qrCodeToken'];
      if (queryParam != null) {
        token = queryParam;
      } else if (uri.pathSegments.isNotEmpty) {
        // Fallback to last segment if query parameter not found but path exists (e.g. siza-restro://table/scan/token)
        // Ensure we don't just capture 'scan' as the token if there are no other segments
        if (uri.pathSegments.last != 'scan' || uri.pathSegments.length > 1) {
          token = uri.pathSegments.last;
        }
      }
    }
    
    // Map mock numerical entries (1-5) to seeded table tokens
    if (token == '1') {
      token = 't1-token-uuid-12345';
    } else if (token == '2') {
      token = 't2-token-uuid-23456';
    } else if (token == '3') {
      token = 't3-token-uuid-34567';
    } else if (token == '4') {
      token = 't4-token-uuid-45678';
    } else if (token == '5') {
      token = 't5-token-uuid-56789';
    }

    if (token.isNotEmpty) {
      setState(() {
        _isScanned = true;
      });
      _submitTableBooking(token);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid QR Code / Token. Please try again.', 
            style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submitTableBooking(String qrCodeToken) async {
    final notifier = ref.read(bookingProvider.notifier);
    await notifier.scanAndBookTable(qrCodeToken);
    
    if (!mounted) return;

    final bookingState = ref.read(bookingProvider);
    if (bookingState.activeBooking != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BookingConfirmationScreen(),
        ),
      );
    } else if (bookingState.errorMessage != null) {
      setState(() {
        _isScanned = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingState.errorMessage!, style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      notifier.clearError();
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Exit Siza Restro?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to close the app?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.amber),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Exit',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F13), // Premium Dark
        appBar: AppBar(
          title: Text(
            'S I Z A   R E S T R O',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.amber[700],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70),
              tooltip: 'Configure Server Connection',
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackendConfigScreen(isEditing: true),
                  ),
                );
                if (updated == true && mounted) {
                  ref.invalidate(apiServiceProvider);
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Scan QR to Book Table',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Locate the QR code sticker on your table and aim your camera.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Scanner box container
                Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              if (barcode.rawValue != null) {
                                _handleQrCode(barcode.rawValue!);
                                break;
                              }
                            }
                          },
                        ),
                        // Scanner Overlay Overlay Grid
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withOpacity(0.5),
                              width: 30,
                            ),
                          ),
                        ),
                        // Animated scanning bar
                        if (bookingState.isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Divider OR text
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR MOCK FOR TESTING',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Quick Mock buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [1, 2, 3].map((tableNum) {
                    return ElevatedButton(
                      onPressed: bookingState.isLoading || _isScanned
                          ? null
                          : () => _handleQrCode(tableNum.toString()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        foregroundColor: Colors.amber,
                        elevation: 0,
                        side: BorderSide(color: Colors.amber.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Mock Table $tableNum',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
  
                const SizedBox(height: 20),
  
                // Text input mock field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mockController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter Table ID manually',
                          hintStyle: GoogleFonts.outfit(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.03),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.amber.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: bookingState.isLoading || _isScanned
                          ? null
                          : () {
                              if (_mockController.text.trim().isNotEmpty) {
                                _handleQrCode(_mockController.text.trim());
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
