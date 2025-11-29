import 'dart:async';
import 'package:flutter/services.dart';

class LocalTimezone {
  static const MethodChannel _channel = MethodChannel('smarttasbih/timezone');

  static Future<String> getLocalTimezone() async {
    try {
      final tz = await _channel.invokeMethod<String>('getLocalTimezone');
      if (tz == null || tz.isEmpty) {
        // Fallback to UTC if platform doesn't return a value
        return 'UTC';
      }
      return tz;
    } catch (_) {
      return 'UTC';
    }
  }
}


