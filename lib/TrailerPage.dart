import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TrailerPage extends StatefulWidget {
  final int movieId;
  final String movieTitle;

  const TrailerPage({required this.movieId, required this.movieTitle});

  @override
  _TrailerPageState createState() => _TrailerPageState();
}

class _TrailerPageState extends State<TrailerPage> {
  String? trailerKey;
  List<dynamic> similarMovies = [];
  bool isLoadingTrailer = true;
  bool isLoadingSimilar = true;
  final TextEditingController searchController = TextEditingController();
  YoutubePlayerController? youtubeController;

  @override
  void initState() {
    super.initState();
    fetchTrailer(widget.movieId);
    fetchSimilarMovies(widget.movieId);
  }

  Future<void> fetchTrailer(int movieId) async {
   final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/movie/$movieId/videos?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final trailer = results.firstWhere(
            (video) => video['type'] == 'Trailer' && video['site'] == 'YouTube',
            orElse: () => null,
          );
          setState(() {
            trailerKey = trailer != null ? trailer['key'] : null;
            isLoadingTrailer = false;
            if (trailerKey != null) {
              youtubeController = YoutubePlayerController(
                initialVideoId: trailerKey!,
                flags: const YoutubePlayerFlags(
                  autoPlay: true,
                  mute: false,
                ),
              );
            }
          });
        } else {
          setState(() {
            trailerKey = null;
            isLoadingTrailer = false;
          });
        }
      } else {
        throw Exception('Failed to fetch trailer');
      }
    } catch (e) {
      setState(() {
        trailerKey = null;
        isLoadingTrailer = false;
      });
      print('Error: $e');
    }
  }

  Future<void> fetchSimilarMovies(int movieId) async {
   final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/movie/$movieId/similar?api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          similarMovies = data['results']
              .where((movie) => movie['poster_path'] != null)
              .toList(); // Filter movies with valid poster
          isLoadingSimilar = false;
        });
      } else {
        throw Exception('Failed to fetch similar movies');
      }
    } catch (e) {
      setState(() {
        isLoadingSimilar = false;
      });
      print('Error: $e');
    }
  }

  Future<void> searchTrailer(String movieName) async {
    final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$movieName';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final movie = data['results'][0];
          await fetchTrailer(movie['id']);
          await fetchSimilarMovies(movie['id']);
        } else {
          setState(() {
            trailerKey = null;
            similarMovies = [];
            youtubeController = null;
          });
          print('No movies found for query: $movieName');
        }
      } else {
        throw Exception('Failed to search movie');
      }
    } catch (e) {
      print('Error during search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.movieTitle),
        backgroundColor: Colors.purple.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.purple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 80),
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    hintText: 'Search for a movie...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      searchTrailer(value);
                    }
                  },
                ),
              ),
              // Trailer Section
              isLoadingTrailer
                  ? CircularProgressIndicator(color: Colors.white)
                  : trailerKey == null
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Trailer not found!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: YoutubePlayer(
                            controller: youtubeController!,
                            showVideoProgressIndicator: true,
                            progressColors: ProgressBarColors(
                              playedColor: Colors.purple,
                              handleColor: Colors.white,
                            ),
                          ),
                        ),
              SizedBox(height: 20),
              // Similar Movies Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Similar Movies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.movie, color: Colors.white),
                  ],
                ),
              ),
              isLoadingSimilar
                  ? CircularProgressIndicator(color: Colors.white)
                  : similarMovies.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No similar movies found!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: similarMovies.length,
                            itemBuilder: (context, index) {
                              final movie = similarMovies[index];
                              return Container(
                                width: 150,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      Colors.purple.shade200.withOpacity(0.3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                                        height: 120,
                                        width: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        movie['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
