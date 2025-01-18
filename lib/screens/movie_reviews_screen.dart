import 'package:flutter/material.dart';
import 'package:movie_reviews/widgets/custom_loading.dart';

import '../api_service.dart';
import 'add_edit_review_screen.dart';

class MovieReviewsScreen extends StatefulWidget {
  final String username;

  const MovieReviewsScreen({super.key, required this.username});

  @override
  State<MovieReviewsScreen> createState() => _MovieReviewsScreenState();
}

class _MovieReviewsScreenState extends State<MovieReviewsScreen> {
  final _apiService = ApiService();
  List<dynamic> _reviews = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    final reviews = await _apiService.getReviews(widget.username);
    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
  }

  void _deleteReview(String id) async {
    // Show loading
    CustomLoading.show();

    final success = await _apiService.deleteReview(id);
    if (success) {
      // Dismiss loading
      CustomLoading.dismiss();

      _loadReviews();
    } else {
      // Dismiss loading
      CustomLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus review')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Film Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddEditReviewScreen(username: widget.username),
                ),
              );
              if (result == true) _loadReviews();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_reviews.isEmpty) {
            return const Center(
                child: Text('Belum ada review. Tambahkan sekarang!'));
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_isLoading) {
            return ListView.builder(
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return ListTile(
                  title: Text(review['title']),
                  subtitle:
                      Text('${review['rating']} / 10\n${review['comment']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditReviewScreen(
                                username: widget.username,
                                review: review,
                              ),
                            ),
                          );
                          if (result == true) _loadReviews();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteReview(review['_id']),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
