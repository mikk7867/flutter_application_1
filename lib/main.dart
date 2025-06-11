import 'package:flutter/material.dart';
import 'db/movie_database.dart'; // Our database logic
import 'sensors/shake_detector.dart'; // Our shake detection logic
import 'api/api_movie_service.dart'; // Our API logic
import 'dart:math'; // Add this import at the top

void main() {
  runApp(FilmApp()); // App entry point
}

class FilmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Film Liste', // App title (used by OS)
      home: FilmListeSide(), // Home screen of the app
    );
  }
}

class FilmListeSide extends StatefulWidget {
  @override
  _FilmListeSideState createState() => _FilmListeSideState();
}

class _FilmListeSideState extends State<FilmListeSide> {
  List<Map<String, dynamic>> filmListe = []; // Stores the user's movie list
  List<Map<String, dynamic>> filteredFilmListe = [];
  Set<String> selectedGenres = {};

  late ShakeDetector _shakeDetector; // ShakeDetector instance

  @override
  void initState() {
    super.initState();
    _loadMovies(); // Load movies from DB when app starts
    _shakeDetector = ShakeDetector(
      onShake: () {
        _pauseShakeDetector();
        _visTilfaeldigFilm();
      }
    ); // Set up shake detection
    _shakeDetector.startListening(); // Start listening for shakes
  }

  void _pauseShakeDetector() {
    _shakeDetector.stopListening();
  }

  void _resumeShakeDetector() {
    _shakeDetector.startListening();
  }

  @override
  void dispose() {
    _shakeDetector.stopListening(); // Stop shake listener
    // MovieDatabase.instance.close(); // Close DB connection, obsolete
    super.dispose();
  }

  // Loads movie list from SQLite database
  Future<void> _loadMovies() async {
    final movies = await MovieDatabase.loadMovies();
    setState(() {
      filmListe = movies; // Update UI with new movie list
      filteredFilmListe = movies; // Initialize filtered list
    });
  }

  void _applyGenreFilter(Set<String> genres) {
    setState(() {
      if (genres.isEmpty) {
        filteredFilmListe = filmListe;
      } else {
        filteredFilmListe = filmListe.where((movie) {
          final movieGenres = (movie['Genre'] ?? '')
              .split(',')
              .map((g) => g.trim())
              .toSet();
          return movieGenres.intersection(genres).isNotEmpty;
        }).toList();
      }
      selectedGenres = genres;
    });
  }

  // Picks a random movie and shows it in a dialog
  void _visTilfaeldigFilm() {
    if (filteredFilmListe.isEmpty) return;
    final randomIndex = Random().nextInt(filteredFilmListe.length);
    final randomMovie = filteredFilmListe[randomIndex];
    showMovieDetailDialog(randomMovie, resumeShakeOnClose: true);
  }

  // Opens a dialog to let the user type and add a new movie
  void showMovieDetailDialog(
    Map<String, dynamic> movie, {
    bool resumeShakeOnClose = true,
  }) async {
    final existingMovies = await MovieDatabase.loadMovies();
    final isInList = existingMovies.any((m) => m['imdbID'] == movie['imdbID']);

    _pauseShakeDetector();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(movie['Title'] ?? 'Ukendt titel'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Titel: ${movie['Title'] ?? 'Ukendt'}'),
                Text('📅 År: ${movie['Year'] ?? 'Ukendt'}'),
                Text('🏷️ Genre: ${movie['Genre'] ?? 'Ukendt'}'),
                Text('🎭 Instruktør: ${movie['Director'] ?? 'Ukendt'}'),
                Text('🎭 Skuespillere: ${movie['Actors'] ?? 'Ukendt'}'),
                Text('📝 Plot: ${movie['Plot'] ?? 'Ingen beskrivelse'}'),
                Text('⭐ IMDB Rating: ${movie['imdbRating']}'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (isInList) {
                      await MovieDatabase.deleteMovie(movie['imdbID']);
                      setState(() {
                        filmListe.removeWhere(
                          (m) => m['imdbID'] == movie['imdbID'],
                        );
                      });
                    } else {
                      await MovieDatabase.insertMovie(movie);
                      setState(() {
                        filmListe.add(movie);
                      });
                    }
                    Navigator.pop(context); // Close dialog
                  },
                  child: Text(isInList ? 'Fjern film' : 'Tilføj film'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (resumeShakeOnClose) {
      _resumeShakeDetector();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Min Film Liste'),
        /*actions: [
          IconButton(
            icon: Icon(Icons.shuffle),
            onPressed: //_visTilfaeldigFilm, // Shuffle button
          ),
        ],*/
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Collect all unique genres from the movie list
                      final allGenres = <String>{};
                      for (var movie in filmListe) {
                        final genres = (movie['Genre'] ?? '')
                            .split(',')
                            .map((g) => g.trim());
                        allGenres.addAll(genres.where((g) => g.isNotEmpty));
                      }
                      final tempSelected = Set<String>.from(selectedGenres);

                      _pauseShakeDetector();
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text('Filter Film efter Genre'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    children: allGenres.map((genre) {
                                      return CheckboxListTile(
                                        title: Text(genre),
                                        value: tempSelected.contains(genre),
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              tempSelected.add(genre);
                                            } else {
                                              tempSelected.remove(genre);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Annuller'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _applyGenreFilter(tempSelected);
                                    },
                                    child: Text('Bekræft'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                      _resumeShakeDetector();
                    },
                    child: Text(
                      'Filter Movies by Genre',
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton(
                    onPressed: _visTilfaeldigFilm,
                    child: Text(
                      'Random Movie (SHAKE!)',
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFilmListe.length,
              itemBuilder: (context, index) {
                final movie = filteredFilmListe[index];
                return buildMovieCard(
                  context,
                  movie,
                  () => showMovieDetailDialog(movie, resumeShakeOnClose: true),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            _pauseShakeDetector();
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                String searchQuery = '';
                List<Map<String, dynamic>> searchResults = [];
                final TextEditingController _controller =
                    TextEditingController();
                final FocusNode _focusNode = FocusNode();
                bool hasRequestedFocus = false;

                return StatefulBuilder(
                  builder: (context, setState) {
                    // Request focus when the dialog is built
                    if (!hasRequestedFocus) {
                      _focusNode.requestFocus();
                      hasRequestedFocus = true;
                    }
                    return AlertDialog(
                      title: Text('Søg efter film'),
                      content: SizedBox(
                        height: 0.9 * MediaQuery.of(context).size.height,
                        width: 0.9 * MediaQuery.of(context).size.width,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Indtast søgeord',
                                ),
                                onChanged: (value) {
                                  searchQuery = value;
                                },
                                onSubmitted: (value) async {
                                  final results =
                                      await MovieService.searchMovies(
                                        value.trim(),
                                      );
                                  setState(() {
                                    searchResults = results;
                                  });
                                },
                              ),
                              //SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  final results =
                                      await MovieService.searchMovies(
                                        searchQuery.trim(),
                                      );
                                  setState(() {
                                    searchResults = results;
                                  });
                                },
                                child: Text('Søg'),
                              ),
                              SizedBox(height: 10),
                              if (searchResults.isNotEmpty)
                                SizedBox(
                                  height:
                                      0.7 * MediaQuery.of(context).size.height,
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) {
                                      final movie = searchResults[index];
                                      return buildMovieCard(
                                        context,
                                        movie,
                                        () async {
                                          final fullMovie =
                                              await MovieService.fetchMovieByTitle(
                                                movie['Title'],
                                              );
                                          if (fullMovie != null) {
                                            showMovieDetailDialog(fullMovie,
                                              resumeShakeOnClose: false,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Kunne ikke hente detaljer.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Luk'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
            _resumeShakeDetector();
          },

          child: Text('Tilføj ny film'),
        ),
      ),
    );
  }

  Widget buildMovieCard(
    BuildContext context,
    Map<String, dynamic> movie,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              movie['Poster'] != null && movie['Poster'] != 'N/A'
                  ? Image.network(
                      movie['Poster'],
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 90,
                      color: Colors.grey,
                      child: Icon(Icons.movie, size: 40),
                    ),
              SizedBox(width: 12),
              // Title & Year
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie['Title'] ?? 'Ukendt titel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'År: ${movie['Year'] ?? 'Ukendt'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
