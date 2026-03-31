import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DBHelper {
  // ✅ 已经修好的可空类型
  static Database? _db;

  // 获取数据库实例
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  // 初始化数据库
  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'smart_assistant.db');
    
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE chat_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question TEXT,
            answer TEXT,
            source TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        debugPrint("数据库表 chat_history 创建成功！");
      },
    );
  }

  // 保存记录
  Future<int> saveMessage(String question, String answer, String source) async {
    var dbClient = await db;
    return await dbClient.insert('chat_history', {
      'question': question,
      'answer': answer,
      'source': source,
    });
  }

  // 获取记录
  Future<List<Map<String, dynamic>>> getHistory() async {
    var dbClient = await db;
    return await dbClient.query('chat_history', orderBy: 'timestamp DESC');
  }

  // 清空记录
  Future<void> clearHistory() async {
    var dbClient = await db;
    await dbClient.delete('chat_history');
  }
}