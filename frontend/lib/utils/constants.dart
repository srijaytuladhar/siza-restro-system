import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  // Replace this with your computer's local IP address (e.g., '192.168.1.5')
  // when testing on a physical mobile device connected to the same Wi-Fi.
  static const String _localIp = '10.12.101.141'; // Host IP for physical device / network testing
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://$_localIp:8080';
      }
    } catch (_) {}
    return 'http://localhost:8080';
  }

  static String get wsUrl {
    if (kIsWeb) {
      return 'ws://localhost:8080/ws';
    }
    try {
      if (Platform.isAndroid) {
        return 'ws://$_localIp:8080/ws';
      }
    } catch (_) {}
    return 'ws://localhost:8080/ws';
  }
}
