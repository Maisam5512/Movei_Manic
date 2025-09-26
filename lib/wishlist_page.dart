import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistPage extends StatefulWidget {
  final Set<int> wishlist;
  final List<dynamic> movies;

  const WishlistPage({
    required this.wishlist,
    required this.movies,
  });

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<dynamic> wishlistMovies = [];

  @override
  void initState() {
    super.initState();
    fetchWishlistMovies();
  }

  Future<void> fetchWishlistMovies() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnapshot = await userDoc.get();
      List<dynamic> storedWishlist = docSnapshot['wishlist'] ?? [];

      setState(() {
        wishlistMovies = widget.movies
            .where((movie) => storedWishlist.contains(movie['id']))
            .toList();
      });
    } catch (e) {
      print("Error fetching wishlist: $e");
    }
  }

  Future<void> removeFromWishlist(int movieId) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Get current wishlist from Firestore
      final docSnapshot = await userDoc.get();
      List<dynamic> currentWishlist = docSnapshot['wishlist'] ?? [];

      currentWishlist.remove(movieId);

      // Update Firestore
      await userDoc.update({'wishlist': currentWishlist});

      // Update UI
      setState(() {
        wishlistMovies.removeWhere((movie) => movie['id'] == movieId);
      });
    } catch (e) {
      print("Error removing from wishlist: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Wishlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.purple.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: wishlistMovies.isEmpty
            ? Center(
                child: Text(
                  'Your wishlist is empty!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: wishlistMovies.length,
                itemBuilder: (context, index) {
                  final movie = wishlistMovies[index];
                  final String posterPath = movie['poster_path'] ?? '';
                  final String imageUrl =
                      'https://image.tmdb.org/t/p/w500$posterPath';
                  final String title = movie['title'] ?? 'Unknown';
                  final String releaseDate =
                      movie['release_date'] ?? 'Release date unavailable';

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 150,
                                color: Colors.grey,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade800,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  releaseDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '❤️ Added to Wishlist',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.purple.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        removeFromWishlist(movie['id']);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
