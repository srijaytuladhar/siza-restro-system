  import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SizaRestroApp(),
    ),
  );
}

class SizaRestroApp extends StatelessWidget {
  const SizaRestroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siza Restro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.amber[700],
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        colorScheme: ColorScheme.dark(
          primary: Colors.amber[700]!,
          secondary: Colors.amber[600]!,
          surface: const Color(0xFF16161E),
          error: Colors.redAccent,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const QrScannerScreen(),
    );
  }
}
