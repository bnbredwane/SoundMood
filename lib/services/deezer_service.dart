// TODO Implement this library.import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/track_model.dart';

class DeezerService {
  // Base URL for the Deezer API.
  static const String _baseUrl = 'https://api.deezer.com';

  /// Searches for tracks on Deezer based on a query.
  /// For example, you can pass a genre or mood tag (like "rock", "jazz", etc.).
  /// Returns a list of Track objects.
  static Future<List<Track>> searchTracks(String query) async {
    final url = '$_baseUrl/search?q=$query&limit=20';
    debugPrint('Requesting Deezer URL: $url');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tracksData = data['data'] as List<dynamic>;
      debugPrint('Received ${tracksData.length} tracks from Deezer.');
      return tracksData.map((trackJson) => Track.fromDeezerJson(trackJson)).toList();
    } else {
      debugPrint('Deezer response error: ${response.body}');
      throw Exception('Failed to load tracks from Deezer: ${response.statusCode}');
    }
  }
}
