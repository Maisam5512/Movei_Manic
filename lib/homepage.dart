import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'LoginPage.dart';
import 'GenreMoviesPage.dart';
import 'MovieDetailPage.dart';
import 'reviews_page.dart';
import 'contact_us_page.dart';
import 'watchlist_page.dart';
import 'wishlist_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> popularMovies = [];
  Set<int> wishlist = {};
  Set<int> watchlist = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchPopularMovies();
  }

  Future<void> fetchPopularMovies() async {
     final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/movie/popular?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          popularMovies = data['results'] as List<dynamic>;
        });
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> searchMovie(String query) async {
     final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          final movie = data['results'][0];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailPage(movie: movie),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No movies found')),
          );
        }
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> updateWishlistInFirestore(int movieId) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Get current wishlist from Firestore
      final docSnapshot = await userDoc.get();
      List<dynamic> currentWishlist = docSnapshot['wishlist'] ?? [];

      if (wishlist.contains(movieId)) {
        currentWishlist.add(movieId);
      } else {
        currentWishlist.remove(movieId);
      }

      // Update Firestore with the new wishlist
      await userDoc.update({'wishlist': currentWishlist});
    } catch (e) {
      print("Error updating wishlist: $e");
    }
  }

  Future<void> updateWatchlistInFirestore(int movieId) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Get current watchlist from Firestore
      final docSnapshot = await userDoc.get();
      List<dynamic> currentWatchlist = docSnapshot['watchlist'] ?? [];

      if (watchlist.contains(movieId)) {
        currentWatchlist.add(movieId);
      } else {
        currentWatchlist.remove(movieId);
      }

      // Update Firestore with the new watchlist
      await userDoc.update({'watchlist': currentWatchlist});
    } catch (e) {
      print("Error updating watchlist: $e");
    }
  }

  void toggleWishlist(int movieId) {
    setState(() {
      if (wishlist.contains(movieId)) {
        wishlist.remove(movieId);
      } else {
        wishlist.add(movieId);
      }
    });
    updateWishlistInFirestore(
        movieId); // Update Firestore when wishlist changes
  }

  void toggleWatchlist(int movieId) {
    setState(() {
      if (watchlist.contains(movieId)) {
        watchlist.remove(movieId);
      } else {
        watchlist.add(movieId);
      }
    });
    updateWatchlistInFirestore(
        movieId); // Update Firestore when watchlist changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MovieManiac',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, color: Colors.purple),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      drawer: AppDrawer(
        wishlist: wishlist,
        watchlist: watchlist,
        popularMovies: popularMovies,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselBanner(),
            PositionedSearchBar(
              onSearch: (query) {
                searchMovie(query);
              },
            ),
            SectionTitle(title: 'Popular Genres'),
            CategoryList(),
            SectionTitle(title: 'Recommended Movies'),
            MovieRecommendationList(
              movies: popularMovies,
              wishlist: wishlist,
              watchlist: watchlist,
              onToggleWishlist: toggleWishlist,
              onToggleWatchlist: toggleWatchlist,
            ),
          ],
        ),
      ),
    );
  }
}

// Drawer Class Implementation
class AppDrawer extends StatelessWidget {
  final Set<int> wishlist;
  final Set<int> watchlist;
  final List<dynamic> popularMovies;

  const AppDrawer({
    required this.wishlist,
    required this.watchlist,
    required this.popularMovies,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.red],
                ),
              ),
              child: Text(
                'MovieManiac Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            drawerListItem(Icons.star, 'Reviews & Ratings', context, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReviewsPage()),
              );
            }),
            drawerListItem(Icons.contact_support, 'Contact Us', context, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactUsPage()),
              );
            }),
            drawerListItem(Icons.movie, 'Thriller Genre', context, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GenreMoviesPage(
                    genreId: 53,
                    genreName: 'Thriller',
                  ),
                ),
              );
            }),
            drawerListItem(Icons.list, 'Watchlist', context, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WatchlistPage(
                    watchlist: watchlist,
                    movies: popularMovies,
                  ),
                ),
              );
            }),
            drawerListItem(Icons.favorite, 'Wishlist', context, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WishlistPage(
                    wishlist: wishlist,
                    movies: popularMovies,
                  ),
                ),
              );
            }),
            drawerListItem(Icons.logout, 'Log out', context, () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  ListTile drawerListItem(
      IconData icon, String title, BuildContext context, Function() onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }
}

// Add any additional helper classes if needed like CarouselBanner, SectionTitle, etc.
class CarouselBanner extends StatelessWidget {
  final List<String> images = [
    'assets/banner1.jpg',
    'assets/banner2.jpg',
    'assets/banner3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 250.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: images.map((imagePath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            );
          },
        );
      }).toList(),
    );
  }
}

// Add other widgets like SectionTitle, CategoryList, MovieRecommendationList as required.

class PositionedSearchBar extends StatelessWidget {
  final Function(String) onSearch;

  const PositionedSearchBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: TextField(
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Search for movies...',
          hintStyle: TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.black54),
        ),
        onSubmitted: (query) {
          onSearch(query);
        },
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

class CategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'name': 'Action', 'id': 28},
    {'name': 'Comedy', 'id': 35},
    {'name': 'Drama', 'id': 18},
    {'name': 'Fantasy', 'id': 14},
    {'name': 'Horror', 'id': 27},
    {'name': 'Romance', 'id': 10749},
    {'name': 'Sci-Fi', 'id': 878},
    {'name': 'Thriller', 'id': 53},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GenreMoviesPage(
                    genreId: category['id'],
                    genreName: category['name'],
                  ),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                category['name'],
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MovieRecommendationList extends StatelessWidget {
  final List<dynamic> movies;
  final Set<int> wishlist;
  final Set<int> watchlist;
  final Function(int) onToggleWishlist;
  final Function(int) onToggleWatchlist;

  const MovieRecommendationList({
    required this.movies,
    required this.wishlist,
    required this.watchlist,
    required this.onToggleWishlist,
    required this.onToggleWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    return movies.isEmpty
        ? Center(
            child: Text(
              'No movies available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : GridView.builder(
            padding: EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7,
            ),
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final movieId = movie['id'];
              final isWishlist = wishlist.contains(movieId);
              final isWatchlist = watchlist.contains(movieId);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailPage(movie: movie),
                    ),
                  );
                },
                child: MovieCard(
                  movie: movie,
                  isWishlist: isWishlist,
                  isWatchlist: isWatchlist,
                  onToggleWishlist: () => onToggleWishlist(movieId),
                  onToggleWatchlist: () => onToggleWatchlist(movieId),
                ),
              );
            },
          );
  }
}

class MovieCard extends StatelessWidget {
  final dynamic movie;
  final bool isWishlist;
  final bool isWatchlist;
  final VoidCallback onToggleWishlist;
  final VoidCallback onToggleWatchlist;

  const MovieCard({
    required this.movie,
    required this.isWishlist,
    required this.isWatchlist,
    required this.onToggleWishlist,
    required this.onToggleWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    final String posterPath = movie['poster_path'] ?? '';
    final String imageUrl = 'https://image.tmdb.org/t/p/w500$posterPath';
    final String title = movie['title'] ?? 'Unknown';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    isWishlist ? Icons.favorite : Icons.favorite_border,
                    color: Colors.purple,
                  ),
                  onPressed: onToggleWishlist,
                ),
                IconButton(
                  icon: Icon(
                    isWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.red,
                  ),
                  onPressed: onToggleWatchlist,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
