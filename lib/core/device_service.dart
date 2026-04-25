import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages device identity and CircleHub API authentication.
///
/// On first run the device generates a UUID, registers with the API,
/// and stores the returned JWT. Subsequent runs reuse the stored token.
class DeviceService {
  static const _prefDeviceId = 'device_id';
  static const _prefToken    = 'device_token';

  static const apiBase = String.fromEnvironment(
    'CIRCLEHUB_API_BASE',
    defaultValue: 'http://10.0.2.2:5150',
  );

  /// Returns the stored device ID, or null if not yet registered.
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefDeviceId);
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Return cached token if present
    final cached = prefs.getString(_prefToken);
    if (cached != null && cached.isNotEmpty) return cached;

    // First run — register the device
    final deviceId = await _ensureDeviceId(prefs);
    final token    = await _register(deviceId);

    await prefs.setString(_prefToken, token);
    return token;
  }

  Future<String> _ensureDeviceId(SharedPreferences prefs) async {
    var id = prefs.getString(_prefDeviceId);
    if (id == null || id.isEmpty) {
      // Generate a stable UUID-like device ID
      id = generateId();
      await prefs.setString(_prefDeviceId, id);
    }
    return id;
  }

  Future<String> _register(String deviceId) async {
    final response = await http.post(
      Uri.parse('$apiBase/api/devices/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Device registration failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['token'] as String;
  }

  /// Returns the device's configured city from the API (falls back to 'Chicago').
  Future<String> fetchLocation(String token) async {
    final response = await http.get(
      Uri.parse('$apiBase/api/location'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return 'Chicago';
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['city'] as String?) ?? 'Chicago';
  }

  /// Returns the device's synced Google Calendar events from the API.
  Future<List<dynamic>> fetchCalendarEvents(String token) async {
    final response = await http.get(
      Uri.parse('$apiBase/api/calendar/events'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return [];
    return jsonDecode(response.body) as List;
  }

  /// Simple timestamp-based ID — stable per device per install.
  static String generateId() {
    final ts   = DateTime.now().millisecondsSinceEpoch;
    final rand = ts.toRadixString(16).padLeft(12, '0');
    return 'ch-$rand';
  }
}

final deviceServiceProvider = Provider((_) => DeviceService());
