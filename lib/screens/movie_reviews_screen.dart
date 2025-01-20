import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../widgets/custom_loading.dart';
import 'add_edit_review_screen.dart';

class MovieReviewsScreen extends StatefulWidget {
  final String username;

  const MovieReviewsScreen({super.key, required this.username});

  @override
  State<MovieReviewsScreen> createState() => _MovieReviewsScreenState();
}

class _MovieReviewsScreenState extends State<MovieReviewsScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  List<dynamic> _reviews = [];
  bool _isLoading = false;
  late AnimationController _likeAnimationController;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadReviews();
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
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

  void _toggleLike(String movieId, String username) async {
    final List<dynamic> likes = await _apiService.getLikeBy(movieId, username);
    final totalLike = likes.length;
    final int statusLike = likes.isNotEmpty ? likes.first['status_like'] : 0;
    if (likes.length > 1) {
      for (int i = 1; i < likes.length; i++) {
        await _apiService.deleteLike(likes[i]['_id']);
      }
    }

    final isLiked = statusLike > 0;

    if (!isLiked) _likeAnimationController.forward(from: 0);

    final success = isLiked && totalLike > 0
        ? await _apiService.unlike(likes.first['_id'], movieId, username)
        : !isLiked && totalLike > 0 ? await _apiService.like(likes.first['_id'], movieId, username)
        : await _apiService.firstLike(movieId, username);

    if (success) {
      _loadReviews(); // Refresh data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah status suka')),
      );
    }
  }


  List<Widget> _buildStarRating(int rating) {
    const int maxStars = 5;
    final double normalizedRating = rating / 2;

    List<Widget> stars = [];
    for (int i = 1; i <= maxStars; i++) {
      if (i <= normalizedRating) {
        stars.add(const Icon(Icons.star, color: Colors.yellow, size: 20));
      } else if (i - 0.5 == normalizedRating) {
        stars.add(const Icon(Icons.star_half, color: Colors.yellow, size: 20));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.grey.shade400, size: 20));
      }
    }
    return stars;
  }

  void _deleteReview(String id) async {
    CustomLoading.show();
    final success = await _apiService.deleteReview(id);
    CustomLoading.dismiss();

    if (success) {
      _loadReviews();
    } else {
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
      body: Stack(
        children: [
          if (_reviews.isEmpty && !_isLoading)
            const Center(
              child: Text('Belum ada review. Tambahkan sekarang!'),
            ),
          if (_reviews.isNotEmpty)
            ListView.builder(
              itemCount: _reviews.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(review['image']),
                                width: MediaQuery.of(context).size.width * 0.25,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.25,
                                    height: 120,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: _buildStarRating(
                                        review['rating']),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    review['comment'],
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleLike(review['_id'],review['username']),
                              child: Row(
                                children: [
                                  ScaleTransition(
                                    scale: Tween(begin: 1.0, end: 1.2)
                                        .animate(CurvedAnimation(
                                        parent: _likeAnimationController,
                                        curve: Curves.easeOut)),
                                    child: Icon(
                                      review['username'] == widget.username
                                          ? Icons.thumb_up
                                          : Icons.thumb_up_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddEditReviewScreen(
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
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
