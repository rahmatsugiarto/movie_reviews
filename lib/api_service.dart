import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  //! Bug Fix 1: Renew the baseUrl
  static String baseUrl =
      'https://crudcrud.com/api/f5ced915df424d68bee30687971ea188';

  Future<bool> registerUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        return users.any((user) => user['username'] == username);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginUser(String username, String password) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        return users.any((user) =>
            user['username'] == username && user['password'] == password);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getReviews(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reviews'));
      if (response.statusCode == 200) {
        final List reviews = jsonDecode(response.body);
        return reviews
            .where((review) => review['username'] == username)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addReview(
    String username,
    String title,
    int rating,
    String comment,
    String? image,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'title': title,
          'rating': rating,
          'comment': comment,
          'image': image ?? ""
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  //! Bug Fix 2: Add Username at body
  Future<bool> updateReview(
    String username,
    String id,
    String title,
    int rating,
    String comment,
    String? image,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'title': title,
          'rating': rating,
          'comment': comment,
          'image': image
        }),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  Future<bool> deleteReview(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/reviews/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  Future<bool> firstLike(String movieId, String user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'movies_id': movieId,
          'username': user,
          'status_like': 1,
        }),
      );

      return response.statusCode == 201; // Success on insert
    } catch (e) {
      print('Error baseUrl: $baseUrl/like');
      return false;
    }
  }

  Future<bool> unlike(String id, String movieId, String user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/like/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'movies_id': movieId,
          'username': user,
          'status_like': 0,
        }),
      );

      return response.statusCode == 200; // Success on update
    } catch (e) {
      print('Error baseUrl: $baseUrl/like');
      return false;
    }
  }

Future<bool> like(String id, String movieId, String user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/like/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'movies_id': movieId,
          'username': user,
          'status_like': 1,
        }),
      );

      return response.statusCode == 200; // Success on update
    } catch (e) {
      print('Error baseUrl: $baseUrl/like');
      return false;
    }
  }

  Future<List<dynamic>> getLikeBy(String movieId, String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/like'));
      if (response.statusCode == 200) {
        final List<dynamic> likes = jsonDecode(response.body);
        // Filter data berdasarkan movies_id dan username
        return likes.where((like) =>
        like['movies_id'] == movieId && like['username'] == username
        ).toList();
      }
      return []; // Jika statusCode bukan 200
    } catch (e) {
      return []; // Jika ada kesalahan
    }
  }

  Future<bool> deleteLike(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/like/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}
