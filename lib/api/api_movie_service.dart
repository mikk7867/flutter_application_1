import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets/api_keys.dart'; // Import the secured API key

class MovieService {
  // Fetches a movie by title using OMDb API
  static Future<Map<String, dynamic>?> fetchMovieByTitle(String title) async {
    final query = Uri.parse(
      'https://www.omdbapi.com/?t=${Uri.encodeComponent(title)}&apikey=${ApiKeys.omdbApiKey}',
    );

    try {
      final response = await http.get(query);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Response'] == 'True') {
          return data; // Successfully found movie
        } else {
          print('Movie not found: ${data['Error']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API call: $e');
    }

    return null; // Return null on failure
  }

  // Searches for movies by keyword and returns a list of results
  static Future<List<Map<String, dynamic>>> searchMovies(String queryTerm) async {
    final query = Uri.parse(
      'https://www.omdbapi.com/?s=${Uri.encodeComponent(queryTerm)}&apikey=${ApiKeys.omdbApiKey}',
    );

    try {
      final response = await http.get(query);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Response'] == 'True' && data['Search'] is List) {
          return List<Map<String, dynamic>>.from(data['Search']);
        } else {
          print('No results found: ${data['Error']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API search: $e');
    }

    return []; // Return empty list on failure
  }
}
