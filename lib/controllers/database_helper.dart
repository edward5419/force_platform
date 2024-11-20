import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // init database
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'data_repository.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE data_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        dataStream1 TEXT,
        dataStream2 TEXT
      )
    ''');
  }

  Future<int> insertDataRecord(String timestamp, List<double> dataStream1,
      List<double> dataStream2) async {
    final db = await database;
    return await db.insert(
      'data_records',
      {
        'timestamp': timestamp,
        'dataStream1': jsonEncode(dataStream1),
        'dataStream2': jsonEncode(dataStream2),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllDataRecords() async {
    final db = await database;
    return await db.query('data_records', orderBy: 'id DESC');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}


