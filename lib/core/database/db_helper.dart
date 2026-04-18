import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'smart_assistant.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await _createAllTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await _createPluginTables(db);
          debugPrint('[DBHelper] 从 v$oldVersion 升级到 v$newVersion，插件表创建成功');
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE chat_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT,
        answer TEXT,
        source TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    debugPrint('数据库表 chat_history 创建成功！');
    await _createPluginTables(db);
  }

  Future<void> _createPluginTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plugins (
        id               TEXT PRIMARY KEY,
        manifest         TEXT NOT NULL,
        manifest_version TEXT NOT NULL DEFAULT '1.0',
        source           TEXT NOT NULL DEFAULT 'builtin',
        status           TEXT NOT NULL DEFAULT 'enabled',
        is_builtin       INTEGER NOT NULL DEFAULT 0,
        install_time     TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        updated_time     TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');
    debugPrint('数据库表 plugins 创建成功！');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS plugin_versions (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        plugin_id    TEXT NOT NULL,
        version      TEXT NOT NULL,
        manifest     TEXT NOT NULL,
        install_time TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY(plugin_id) REFERENCES plugins(id) ON DELETE CASCADE
      )
    ''');
    debugPrint('数据库表 plugin_versions 创建成功！');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS plugin_usage_stats (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        plugin_id  TEXT NOT NULL UNIQUE,
        use_count  INTEGER NOT NULL DEFAULT 0,
        last_used  TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY(plugin_id) REFERENCES plugins(id) ON DELETE CASCADE
      )
    ''');
    debugPrint('数据库表 plugin_usage_stats 创建成功！');
  }

  Future<int> saveMessage(String question, String answer, String source) async {
    var dbClient = await db;
    return await dbClient.insert('chat_history', {
      'question': question,
      'answer': answer,
      'source': source,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    var dbClient = await db;
    return await dbClient.query('chat_history', orderBy: 'timestamp DESC');
  }

  Future<void> clearHistory() async {
    var dbClient = await db;
    await dbClient.delete('chat_history');
  }
}
