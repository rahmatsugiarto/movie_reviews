import 'dart:convert';

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
      body: Builder(builder: (context) {
        // When isLoading
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // When no review
        if (_reviews.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada review. Tambahkan sekarang!',
            ),
          );
        }

        // When has review
        if (!_isLoading) {
          return ListView.separated(
            itemCount: _reviews.length,
            padding: const EdgeInsets.symmetric(vertical: 10),
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(
                height: 4,
              );
            },
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.memory(
                            base64Decode(review['image']),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 150,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                width: 100,
                                height: 150,
                                color: Colors.grey,
                              );
                            },
                          ),
                          const SizedBox(
                            width: 10.0,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review['title'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${review['rating']} / 10",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${review['comment']}",
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.thumb_up_outlined),
                            onPressed: () {},
                          ),
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
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox();
      }),
    );
  }
}
