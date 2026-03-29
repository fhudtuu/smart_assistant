// lib/core/ai_gateway.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // 导入以使用 debugPrint
import 'package:smart_assistant/core/database/db_helper.dart';

class AiGateway {
  final Dio _dio = Dio();
  final DBHelper _db = DBHelper();

  // 【检查点】：确保这里的 IP 依然是你电脑的 IPv4 地址
  final String _backendUrl = "http://192.168.81.221:5000/api/chat";

  Future<Map<String, String>> dispatchTask(String question, String systemPrompt) async {
    try {
      // 发送请求给 Python 后端
      final response = await _dio.post(
        _backendUrl,
        data: {
          "question": question,
          "system_prompt": systemPrompt,
        },
        options: Options(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // 成功获取 Python 返回的数据
      if (response.statusCode == 200 && response.data != null) {
        final String content = response.data['content'] ?? "后端未返回内容";
        final String source = response.data['source'] ?? "云端调度";

        // --- 核心逻辑：将对话持久化存入本地数据库 ---
        // 这一步体现了你论文中“内核管理数据”的严谨性 [cite: 23]
        await _db.saveMessage(question, content, source);
        
        // 修正点：使用 debugPrint 消除 avoid_print 警告
        debugPrint(">>> 存档成功：已记录一条来自 [$source] 的对话");

        return {
          "content": content,
          "source": source
        };
      } else {
        return {"content": "服务器忙，请稍后再试", "source": "网络拦截"};
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg = "连接超时：请确认电脑防火墙已关闭，且手机和电脑在同一 Wi-Fi。";
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = "连接被拒绝：请确认 Python 后端已启动（python index.py）。";
        }
      }
      return {
        "content": "无法连接云端大脑\n地址：$_backendUrl\n详情：$errorMsg",
        "source": "调度中心报错"
      };
    }
  }
}