import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class DeezerService {
  static const String _baseUrl = 'https://api.deezer.com';

  static Future<List<Track>> searchTracks(String query) async {
    final url = '$_baseUrl/search?q=$query';
    debugPrint('Requesting Deezer URL: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tracksData = data['data'] as List<dynamic>;
      debugPrint('Received ${tracksData.length} tracks from Deezer.');
      return tracksData
          .map((trackJson) => Track.fromDeezerJson(trackJson))
          .toList();
    } else {
      debugPrint('Deezer response error: ${response.body}');
      throw Exception(
          'Failed to load tracks from Deezer: ${response.statusCode}');
    }
  }
}
