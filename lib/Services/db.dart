import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Database? _database;

Future<void> initDatabase() async {
  final dbPath = await getDatabasesPath();

  _database = await openDatabase(
    join(dbPath, 'app.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE chat (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          isAI INTEGER,
          chat_id INTEGER,
          chat TEXT NOT NULL
        )
      ''');
    },
  );
}
