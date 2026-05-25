import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  static const String currencySymbol = 'Rs. ';
  
  static String? _customBaseUrl;

  static void setBaseUrl(String domain) {
    String url = domain.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    _customBaseUrl = url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
    } catch (_) {}
    return 'http://localhost:8080';
  }

  static String get wsUrl {
    final base = baseUrl;
    if (base.startsWith('https://')) {
      return '${base.replaceFirst('https://', 'wss://')}/ws';
    } else if (base.startsWith('http://')) {
      return '${base.replaceFirst('http://', 'ws://')}/ws';
    }
    return 'ws://localhost:8080/ws';
  }
}
