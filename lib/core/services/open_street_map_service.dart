import 'dart:convert';

import 'package:http/http.dart' as http;

class OSMPlace {
  final String displayName;
  final double latitude;
  final double longitude;

  const OSMPlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

/// Uses OpenStreetMap's public Nominatim endpoint for low-volume, user-triggered
/// address searches and reverse geocoding. Do not use for autocomplete or
/// high-volume production traffic; see the SQL/README notes for alternatives.
class OpenStreetMapService {
  OpenStreetMapService._();

  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Map<String, String> _headers = {
    'User-Agent': 'QuickSalonFlutterApp/1.0 (location picker)',
    'Accept': 'application/json',
  };

  static Future<List<OSMPlace>> search(String query) async {
    final value = query.trim();
    if (value.isEmpty) return <OSMPlace>[];

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': value,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
      'countrycodes': 'in',
    });

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Address search is temporarily unavailable. Please try again.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <OSMPlace>[];

    return decoded.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return OSMPlace(
        displayName: (map['display_name'] ?? '').toString(),
        latitude: double.parse(map['lat'].toString()),
        longitude: double.parse(map['lon'].toString()),
      );
    }).toList();
  }

  static Future<OSMPlace> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'addressdetails': '1',
    });

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Could not retrieve the address for this map location.');
    }

    final decoded = Map<String, dynamic>.from(
      jsonDecode(response.body) as Map,
    );
    final displayName = (decoded['display_name'] ?? '').toString().trim();
    if (displayName.isEmpty) {
      throw Exception('No readable address was found for this location.');
    }

    return OSMPlace(
      displayName: displayName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
