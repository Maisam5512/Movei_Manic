import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'TrailerPage.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class GenreMoviesPage extends StatefulWidget {
  final int genreId;
  final String genreName;

  const GenreMoviesPage({required this.genreId, required this.genreName});

  @override
  _GenreMoviesPageState createState() => _GenreMoviesPageState();
}

class _GenreMoviesPageState extends State<GenreMoviesPage> {
  List<dynamic> movies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGenreMovies();
  }

  Future<void> fetchGenreMovies() async {
   
    final String apiKey = dotenv.env['IMDB_API_KEY']!;
    final String url =
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=${widget.genreId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          movies = data['results'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.genreName} Movies'),
        backgroundColor: Colors.purple,
        elevation: 5,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.purple,
              ),
            )
          : movies.isEmpty
              ? Center(
                  child: Text(
                    'No movies available for ${widget.genreName}.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: ListView.builder(
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      // final List<int> genreIds =
                      List<int>.from(movie['genre_ids']);
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.1),
                                Colors.white
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: movie['poster_path'] != null
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                                      fit: BoxFit.cover,
                                      width: 60,
                                      height: 90,
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      width: 60,
                                      height: 90,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                            title: Text(
                              movie['title'] ?? 'No Title',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.star,
                                          size: 18, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text(
                                        movie['vote_average']
                                                ?.toStringAsFixed(1) ??
                                            'N/A',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    movie['overview'] ??
                                        'No description available.',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios,
                                size: 18, color: Colors.grey),
                            onTap: () {
                              // Navigate directly to TrailerPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrailerPage(
                                    movieId: movie['id'], // Pass movie ID
                                    movieTitle:
                                        movie['title'], // Pass movie title
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

