import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MovieDetailPage extends StatefulWidget {
  final Map<String, dynamic> movie;

  MovieDetailPage({required this.movie});

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late int movieId;
  List<dynamic> cast = [];
  List<dynamic> similarMovies = [];
  Set<int> watchlist = {};
  Set<int> wishlist = {};
  List<dynamic> platforms = [];

  @override
  void initState() {
    super.initState();
    movieId = widget.movie['id'] is int
        ? widget.movie['id']
        : int.parse(widget.movie['id'].toString());
    fetchUserLists();
    fetchCast();
    fetchSimilarMovies();
    fetchWatchProviders();
  }

  Future<void> fetchUserLists() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          wishlist = Set<int>.from(userDoc['wishlist'] ?? []);
          watchlist = Set<int>.from(userDoc['watchlist'] ?? []);
        });
      }
    } catch (e) {
      print("Error fetching user lists: $e");
    }
  }

  Future<void> fetchCast() async {
     final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/movie/${widget.movie['id']}/credits?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cast = (data['cast'] as List)
              .where((actor) => actor['profile_path'] != null)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching cast: $e');
    }
  }

  Future<void> fetchSimilarMovies() async {
     final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/movie/${widget.movie['id']}/similar?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          similarMovies = (data['results'] as List)
              .where((movie) => movie['poster_path'] != null)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching similar movies: $e');
    }
  }

  Future<void> fetchWatchProviders() async {
  final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/movie/${widget.movie['id']}/watch/providers?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          platforms = data['results']?['US']?['flatrate'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching watch providers: $e');
    }
  }

  Future<void> updateFirestoreList(
      String listName, int movieId, bool addToList) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      final docSnapshot = await userDoc.get();
      List<dynamic> currentList = docSnapshot[listName] ?? [];

      if (addToList) {
        currentList.add(movieId);
      } else {
        currentList.remove(movieId);
      }

      await userDoc.update({listName: currentList});
    } catch (e) {
      print("Error updating $listName: $e");
    }
  }

  void toggleWishlist(int movieId) {
    setState(() {
      if (wishlist.contains(movieId)) {
        wishlist.remove(movieId);
        updateFirestoreList('wishlist', movieId, false);
      } else {
        wishlist.add(movieId);
        updateFirestoreList('wishlist', movieId, true);
      }
    });
  }

  void toggleWatchlist(int movieId) {
    setState(() {
      if (watchlist.contains(movieId)) {
        watchlist.remove(movieId);
        updateFirestoreList('watchlist', movieId, false);
      } else {
        watchlist.add(movieId);
        updateFirestoreList('watchlist', movieId, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.movie['title'] ?? 'Movie Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.movie['poster_path'] != null)
              Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://image.tmdb.org/t/p/w500${widget.movie['poster_path']}',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.movie['title'] ?? 'No Title',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            watchlist.contains(widget.movie['id'])
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.purple,
                          ),
                          onPressed: () => toggleWatchlist(widget.movie['id']),
                        ),
                        IconButton(
                          icon: Icon(
                            wishlist.contains(widget.movie['id'])
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () => toggleWishlist(widget.movie['id']),
                        ),
                      ],
                    ),
                  ),
                  // Other UI sections remain unchanged

                  SizedBox(height: 12),

                  // Streaming Platforms Section
                  if (platforms.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available On',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: platforms.map((platform) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    'https://image.tmdb.org/t/p/w200${platform['logo_path']}',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  platform['provider_name'],
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  SizedBox(height: 16),

                  // Rating and Release Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Release Date: ${widget.movie['release_date'] ?? 'Unknown'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '${widget.movie['vote_average'] ?? 'N/A'} / 10',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Cast Section
                  if (cast.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cast',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: cast.length,
                            itemBuilder: (context, index) {
                              final actor = cast[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    ClipOval(
                                      child: Image.network(
                                        'https://image.tmdb.org/t/p/w200${actor['profile_path']}',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      actor['name'] ?? 'Unknown',
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 16),

                  // Similar Movies Section
                  if (similarMovies.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Similar Movies',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: similarMovies.length,
                            itemBuilder: (context, index) {
                              final movie = similarMovies[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(8),
                                            ),
                                            child: Image.network(
                                              'https://image.tmdb.org/t/p/w200${movie['poster_path'] ?? ''}',
                                              width: 120,
                                              height: 180,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Column(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    watchlist.contains(
                                                            movie['id'])
                                                        ? Icons.bookmark
                                                        : Icons.bookmark_border,
                                                    color: Colors.purple,
                                                  ),
                                                  onPressed: () =>
                                                      toggleWatchlist(
                                                          movie['id']),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    wishlist.contains(
                                                            movie['id'])
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      toggleWishlist(
                                                          movie['id']),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Text(
                                          movie['title'] ?? 'No Title',
                                          style: TextStyle(fontSize: 14),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
