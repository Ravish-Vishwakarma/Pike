import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Database? _database;
final ValueNotifier<int> chatListChangesNotifier = ValueNotifier(0);
final ValueNotifier<int> chatHistoryClearedNotifier = ValueNotifier(0);

Future<Database> get database async {
  final existingDatabase = _database;
  if (existingDatabase != null) return existingDatabase;

  final dbPath = await getDatabasesPath();
  _database = await openDatabase(
    join(dbPath, 'app.db'),
    version: 3,
    onCreate: (db, version) async {
      await _createChatTables(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await _createConversationsTable(db);
        await db.execute('''
          INSERT OR IGNORE INTO conversations (id, title, created_at, updated_at)
          SELECT DISTINCT chat_id, 'Chat ' || chat_id, datetime('now'), datetime('now')
          FROM chat
          WHERE chat_id IS NOT NULL
        ''');
      }
      if (oldVersion < 3) {
        await db.execute('ALTER TABLE chat ADD COLUMN image_data BLOB');
      }
    },
  );
  return _database!;
}

Future<void> initDatabase() async {
  await database;
}

Future<int> createChat({String? modelName}) async {
  final db = await database;
  final now = DateTime.now().toIso8601String();
  final id = await db.transaction((transaction) async {
    final id = await transaction.insert('conversations', {
      'title': '',
      'created_at': now,
      'updated_at': now,
      'model_name': modelName,
    });
    await transaction.update(
      'conversations',
      {'title': 'Chat $id'},
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  });
  chatListChangesNotifier.value++;
  return id;
}

Future<List<ChatSession>> getAllChats() async {
  final db = await database;
  final rows = await db.query(
    'conversations',
    orderBy: 'updated_at DESC, id DESC',
  );
  return rows.map(ChatSession.fromMap).toList(growable: false);
}

Future<ChatSession?> getChat(int id) async {
  final db = await database;
  final rows = await db.query(
    'conversations',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  if (rows.isEmpty) return null;
  return ChatSession.fromMap(rows.first);
}

Future<List<ChatMessage>> getChatMessages(int chatId) async {
  final db = await database;
  final rows = await db.query(
    'chat',
    where: 'chat_id = ?',
    whereArgs: [chatId],
    orderBy: 'id ASC',
  );
  return rows.map(ChatMessage.fromMap).toList(growable: false);
}

Future<int> addChatMessage({
  required int chatId,
  required bool isAI,
  required String text,
  Uint8List? imageBytes,
}) async {
  final db = await database;
  return db.transaction((transaction) async {
    final id = await transaction.insert('chat', {
      'chat_id': chatId,
      'isAI': isAI ? 1 : 0,
      'chat': text,
      'image_data': imageBytes,
    });
    final changedRows = await transaction.update(
      'conversations',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [chatId],
    );
    if (changedRows == 0) {
      throw StateError('Chat $chatId no longer exists.');
    }
    return id;
  });
}

Future<void> renameChat(int id, String title) async {
  final db = await database;
  final trimmedTitle = title.trim();
  if (trimmedTitle.isEmpty) {
    throw ArgumentError.value(title, 'title', 'Chat name cannot be empty.');
  }
  final changedRows = await db.update(
    'conversations',
    {'title': trimmedTitle},
    where: 'id = ?',
    whereArgs: [id],
  );
  if (changedRows == 0) {
    throw StateError('Chat $id no longer exists.');
  }
}

Future<void> deleteChat(int id) async {
  final db = await database;
  await db.transaction((transaction) async {
    await transaction.delete('chat', where: 'chat_id = ?', whereArgs: [id]);
    await transaction.delete('conversations', where: 'id = ?', whereArgs: [id]);
  });
  chatListChangesNotifier.value++;
}

Future<void> deleteAllChats() async {
  final db = await database;
  await db.transaction((transaction) async {
    await transaction.delete('chat');
    await transaction.delete('conversations');
  });
  chatListChangesNotifier.value++;
  chatHistoryClearedNotifier.value++;
}

Future<void> _createChatTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE conversations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      model_name TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE chat (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      isAI INTEGER NOT NULL,
      chat_id INTEGER NOT NULL,
      chat TEXT NOT NULL,
      image_data BLOB
    )
  ''');
}

Future<void> _createConversationsTable(DatabaseExecutor db) {
  return db.execute('''
    CREATE TABLE conversations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      model_name TEXT
    )
  ''');
}

class ChatSession {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modelName;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.modelName,
  });

  factory ChatSession.fromMap(Map<String, Object?> map) {
    return ChatSession(
      id: map['id'] as int,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      modelName: map['model_name'] as String?,
    );
  }
}

class ChatMessage {
  final int id;
  final int chatId;
  final bool isAI;
  final String text;
  final Uint8List? imageBytes;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.isAI,
    required this.text,
    this.imageBytes,
  });

  factory ChatMessage.fromMap(Map<String, Object?> map) {
    return ChatMessage(
      id: map['id'] as int,
      chatId: map['chat_id'] as int,
      isAI: map['isAI'] == 1,
      text: map['chat'] as String,
      imageBytes: map['image_data'] as Uint8List?,
    );
  }
}
