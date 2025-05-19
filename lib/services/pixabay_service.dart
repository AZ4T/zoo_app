// lib/services/pixabay_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PixabayService {
  /// Fetches a random animal image URL for [query].
  /// 
  /// Throws on missing API key, network errors, timeouts, or empty results.
  static Future<String> getRandomAnimalImage(String query) async {
    // 1) Validate API key
    final apiKey = dotenv.env['PIXABAY_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Pixabay API key is not configured');
    }

    // 2) Build URL
    final uri = Uri.https(
      'pixabay.com',
      '/api/',
      {
        'key': apiKey,
        'q':   query,
        'image_type': 'photo',
        'category':   'animals',
        'per_page':   '20',
      },
    );

    try {
      // 3) Perform GET with timeout
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      // 4) Check HTTP status
      if (response.statusCode != 200) {
        throw Exception(
            'Pixabay API returned HTTP ${response.statusCode}');
      }

      // 5) Decode JSON
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['hits'] is! List) {
        throw Exception('Unexpected Pixabay response structure');
      }

      final List hits = data['hits'] as List;
      if (hits.isEmpty) {
        throw Exception('No images found for "$query"');
      }

      // 6) Pick a truly random index
      final idx = Random().nextInt(hits.length);
      final url = hits[idx]['webformatURL'];
      if (url is String && url.isNotEmpty) {
        return url;
      } else {
        throw Exception('Invalid image URL in Pixabay response');
      }
    } on TimeoutException catch (_) {
      debugPrint('Pixabay request for "$query" timed out');
      throw Exception('Request to Pixabay timed out');
    } on http.ClientException catch (e, st) {
      debugPrint('HTTP error fetching Pixabay: $e\n$st');
      throw Exception('Network error fetching image');
    } catch (e, st) {
      debugPrint('Error in getRandomAnimalImage: $e\n$st');
      rethrow; // allow callers to display or handle this exception
    }
  }
}
