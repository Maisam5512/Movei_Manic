import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WatchlistPage extends StatefulWidget {
  final Set<int> watchlist;
  final List<dynamic> movies;

  const WatchlistPage({
    required this.watchlist,
    required this.movies,
  });

  @override
  _WatchlistPageState createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  List<dynamic> watchlistMovies = [];

  @override
  void initState() {
    super.initState();
    fetchWatchlistMovies();
  }

  Future<void> fetchWatchlistMovies() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnapshot = await userDoc.get();
      List<dynamic> storedWatchlist = docSnapshot['watchlist'] ?? [];

      setState(() {
        watchlistMovies = widget.movies
            .where((movie) => storedWatchlist.contains(movie['id']))
            .toList();
      });
    } catch (e) {
      print("Error fetching watchlist: $e");
    }
  }

  Future<void> removeFromWatchlist(int movieId) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Get current watchlist from Firestore
      final docSnapshot = await userDoc.get();
      List<dynamic> currentWatchlist = docSnapshot['watchlist'] ?? [];

      currentWatchlist.remove(movieId);

      // Update Firestore
      await userDoc.update({'watchlist': currentWatchlist});

      // Update UI
      setState(() {
        watchlistMovies.removeWhere((movie) => movie['id'] == movieId);
      });
    } catch (e) {
      print("Error removing from watchlist: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Watchlist',
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
        child: watchlistMovies.isEmpty
            ? Center(
                child: Text(
                  'Your watchlist is empty!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: watchlistMovies.length,
                itemBuilder: (context, index) {
                  final movie = watchlistMovies[index];
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
                                      '🎬 Watchlist Item',
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
                                        removeFromWatchlist(movie['id']);
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
