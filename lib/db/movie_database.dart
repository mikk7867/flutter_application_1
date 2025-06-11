import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MovieDatabase {
  static Database? _db;

  /// Open or create the database
  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'movies.db');

    _db = await openDatabase(
      path,
      version: 2, // ⬅️ bumped version to trigger migration
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE movies (
        imdbID TEXT PRIMARY KEY,
        title TEXT,
        year TEXT,
        genre TEXT,
        director TEXT,
        actors TEXT,
        plot TEXT,
        poster TEXT,
        imdbRating TEXT
      )
    ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS movies');
        await db.execute('''
      CREATE TABLE movies (
        imdbID TEXT PRIMARY KEY,
        title TEXT,
        year TEXT,
        genre TEXT,
        director TEXT,
        actors TEXT,
        plot TEXT,
        poster TEXT,
        imdbRating TEXT
      )
    ''');
      },
    );

    return _db!;
  }

  /// Insert a movie
  static Future<void> insertMovie(Map<String, dynamic> movie) async {
    final db = await getDatabase();
    await db.insert('movies', {
      'imdbID': movie['imdbID'],
      'title': movie['Title'],
      'year': movie['Year'],
      'genre': movie['Genre'],
      'director': movie['Director'],
      'actors': movie['Actors'],
      'plot': movie['Plot'],
      'poster': movie['Poster'],
      'imdbRating': movie['imdbRating'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Load all saved movies
  static Future<List<Map<String, dynamic>>> loadMovies() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('movies');

    return maps.map((map) {
      return {
        'imdbID': map['imdbID'],
        'Title': map['title'],
        'Year': map['year'],
        'Genre': map['genre'],
        'Director': map['director'],
        'Actors': map['actors'],
        'Plot': map['plot'],
        'Poster': map['poster'],
        'imdbRating': map['imdbRating'],
      };
    }).toList();
  }

  /// Delete a single movie by its imdbID
  static Future<void> deleteMovie(String imdbID) async {
    final db = await getDatabase();
    await db.delete('movies', where: 'imdbID = ?', whereArgs: [imdbID]);
  }

  /// Optional: Clear the movies table
  static Future<void> clearMovies() async {
    final db = await getDatabase();
    await db.delete('movies');
  }
}
