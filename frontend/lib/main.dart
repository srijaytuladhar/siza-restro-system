import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/constants.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/backend_config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final savedDomain = prefs.getString('backend_domain');
  
  Widget initialScreen;
  if (savedDomain != null && savedDomain.isNotEmpty) {
    Constants.setBaseUrl(savedDomain);
    initialScreen = const QrScannerScreen();
  } else {
    initialScreen = const BackendConfigScreen();
  }

  runApp(
    ProviderScope(
      child: SizaRestroApp(initialScreen: initialScreen),
    ),
  );
}

class SizaRestroApp extends StatelessWidget {
  final Widget initialScreen;

  const SizaRestroApp({super.key, required this.initialScreen});

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
      home: initialScreen,
    );
  }
}
