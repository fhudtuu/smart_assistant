import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // 导入 foundation 以使用 debugPrint

class DBHelper {
  static Database? _db;

  // 获取数据库实例（单例模式，确保全局只有一个管理器）
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  // 初始化数据库：在手机内存中开辟“档案室”
  // 修正点：明确增加 Future<Database> 返回值类型，消除 Lint 警告 [cite: 89]
  Future<Database> initDb() async {
    // 获取手机内部存储路径
    String path = join(await getDatabasesPath(), 'smart_assistant.db');
    
    // 打开数据库，如果是第一次运行则创建表
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: (Database db, int version) async {
        // 创建聊天记录表：符合你论文中“内核管理数据”的设计 [cite: 23, 49]
        await db.execute('''
          CREATE TABLE chat_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question TEXT,
            answer TEXT,
            source TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        // 修正点：使用 debugPrint 替代 print，符合生产代码规范 [cite: 89]
        debugPrint("数据库表 chat_history 创建成功！");
      },
    );
  }

  // 【增】：保存每一条对话，实现“记忆”功能
  Future<int> saveMessage(String question, String answer, String source) async {
    var dbClient = await db;
    return await dbClient.insert('chat_history', {
      'question': question,
      'answer': answer,
      'source': source,
    });
  }

  // 【查】：获取所有历史记录，按时间倒序排列（最新的在最上面）
  Future<List<Map<String, dynamic>>> getHistory() async {
    var dbClient = await db;
    // 查询结果直接对应你 UI 需要显示的列表数据
    return await dbClient.query('chat_history', orderBy: 'timestamp DESC');
  }

  // 【删】：清空记录（调试或用户重置时使用）
  Future<void> clearHistory() async {
    var dbClient = await db;
    await dbClient.delete('chat_history');
  }
}