import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:http/http.dart' as http; // For TMDB API
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ReviewsPage extends StatefulWidget {
  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _movieNameController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();

  bool _isAddingReview = false;
  bool _showUserReviews = true;
  List<Map<String, dynamic>> tmdbReviews = [];
  List<Map<String, dynamic>> userReviews = [];

  @override
  void initState() {
    super.initState();
    fetchUserReviews();
  }

  Future<void> fetchUserReviews() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        userReviews = snapshot.docs
            .map((doc) => doc.data())
            .toList();
      });
    } catch (e) {
      print("Error fetching user reviews: $e");
    }
  }

  Future<void> fetchTmdbReviews(String movieName) async {
     final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String searchUrl =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$movieName';

    try {
      final searchResponse = await http.get(Uri.parse(searchUrl));
      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);

        if (searchData['results'] == null || searchData['results'].isEmpty) {
          setState(() {
            tmdbReviews = [];
          });
          return;
        }

        final movieId = searchData['results'][0]['id'];

        final String reviewsUrl =
            'https://api.themoviedb.org/3/movie/$movieId/reviews?api_key=$apiKey';

        final reviewsResponse = await http.get(Uri.parse(reviewsUrl));
        if (reviewsResponse.statusCode == 200) {
          final reviewsData = jsonDecode(reviewsResponse.body);
          setState(() {
            tmdbReviews = (reviewsData['results'] as List<dynamic>)
                .map((review) => {
                      'author': review['author'] ?? 'Unknown',
                      'content': review['content'] ?? '',
                      'rating':
                          review['author_details']['rating']?.toString() ??
                              'N/A'
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching TMDB reviews: $e");
    }
  }

  Future<void> addReviewToFirebase(
      String userName, String movieName, String review, String rating) async {
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'userName': userName,
        'movieName': movieName,
        'review': review,
        'rating': rating,
        'timestamp': Timestamp.now(),
      });
      fetchUserReviews(); // Refresh user reviews dynamically
    } catch (e) {
      print("Error adding review to Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews & Ratings'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAddingReview = !_isAddingReview;
                });
              },
              child: Text(
                _isAddingReview ? 'Cancel' : 'Add Review',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            if (_isAddingReview) _buildReviewForm(),
            SizedBox(height: 20),
            TextField(
              controller: _movieNameController,
              decoration: InputDecoration(
                labelText: 'Search Movie for TMDB Reviews',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (movieName) {
                fetchTmdbReviews(movieName);
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showUserReviews = !_showUserReviews;
                });
              },
              child: Text(
                _showUserReviews ? 'Hide User Reviews' : 'Show User Reviews',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_showUserReviews) ...[
                    _buildSectionTitle('User Reviews'),
                    ...userReviews.map((review) => _buildReviewCard(review)),
                  ],
                  _buildSectionTitle('IMDB Reviews'),
                  ...tmdbReviews.map((review) => _buildTmdbReviewCard(review)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userNameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _movieNameController,
              decoration: InputDecoration(
                labelText: 'Movie Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: 'Write your review',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _ratingController,
              decoration: InputDecoration(
                labelText: 'Rating (out of 10)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final userName = _userNameController.text;
                final movieName = _movieNameController.text;
                final review = _reviewController.text;
                final rating = _ratingController.text;

                if (userName.isNotEmpty &&
                    movieName.isNotEmpty &&
                    review.isNotEmpty &&
                    rating.isNotEmpty) {
                  addReviewToFirebase(userName, movieName, review, rating);
                  setState(() {
                    _isAddingReview = false;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              child: Text(
                'Submit Review',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          '${review['userName']} reviewed ${review['movieName']}',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review: ${review['review']}'),
            Text('Rating: ${review['rating']} / 10'),
          ],
        ),
      ),
    );
  }

  Widget _buildTmdbReviewCard(Map<String, dynamic> review) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          review['author'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(review['content']),
            Text('Rating: ${review['rating']} / 10'),
          ],
        ),
      ),
    );
  }
}
