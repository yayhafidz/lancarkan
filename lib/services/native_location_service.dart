import 'package:flutter/services.dart';

typedef NavigationStoppedCallback = void Function();

class NativeLocationService {
  static const MethodChannel _channel = MethodChannel('com.android.lancarkan/nav_location');
  static NavigationStoppedCallback? _onNavigationStopped;

  static void setNavigationStoppedCallback(NavigationStoppedCallback? callback) {
    _onNavigationStopped = callback;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNavigationStopped') {
        _onNavigationStopped?.call();
      }
    });
  }

  static Future<bool> startNavigation({
    required double lat,
    required double lng,
    required double alt,
    required double accuracy,
    required double speed,
    required double bearing,
  }) async {
    try {
      final result = await _channel.invokeMethod('startMock', {
        'lat': lat,
        'lng': lng,
        'alt': alt,
        'accuracy': accuracy,
        'speed': speed,
        'bearing': bearing,
      });
      return result as bool;
    } catch (e) {
      print("Failed to start navigation: $e");
      return false;
    }
  }

  static Future<bool> updateNavigation({
    required double lat,
    required double lng,
    required double alt,
    required double accuracy,
    required double speed,
    required double bearing,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateMock', {
        'lat': lat,
        'lng': lng,
        'alt': alt,
        'accuracy': accuracy,
        'speed': speed,
        'bearing': bearing,
      });
      return result as bool;
    } catch (e) {
      print("Failed to update navigation: $e");
      return false;
    }
  }

  static Future<bool> stopNavigation() async {
    try {
      final result = await _channel.invokeMethod('stopMock');
      return result as bool;
    } catch (e) {
      print("Failed to stop navigation: $e");
      return false;
    }
  }

  static Future<void> moveToBackground() async {
    try {
      await _channel.invokeMethod('moveToBackground');
    } catch (e) {
      print("Failed to move to background: $e");
    }
  }
}
