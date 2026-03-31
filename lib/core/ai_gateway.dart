import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_assistant/core/database/db_helper.dart';

class AiGateway {
  final Dio _dio = Dio();
  final DBHelper _db = DBHelper();
  final String _backendUrl = "http://192.168.81.221:5000/api/chat";

  /// 调度任务
  /// [model] 可选值：deepseek / kimi / doubao
  /// 传 [imagePath] 时，自动强制使用 doubao 视觉模型
  Future<Map<String, String>> dispatchTask(
    String question,
    String systemPrompt, {
    String? imagePath,
    String model = "deepseek", // 默认模型
  }) async {
    try {
      String? base64Image;

      // ==================== 图片转 Base64 ====================
      if (imagePath != null && imagePath.isNotEmpty) {
        final File file = File(imagePath);
        if (await file.exists()) {
          List<int> bytes = await file.readAsBytes();
          base64Image = base64Encode(bytes);
          debugPrint(">>> ✅ 图片转码完成");
        }
      }

      // ==================== 自动模型选择 ====================
      // 有图片 → 强制使用豆包视觉
      String useModel = model;
      if (base64Image != null) {
        useModel = "doubao";
        debugPrint(">>> 🖼️ 检测到图片，自动切换为豆包视觉");
      }

      // ==================== 请求后端 ====================
      final response = await _dio.post(
        _backendUrl,
        data: {
          "question": question,
          "system_prompt": systemPrompt,
          "image_data": base64Image,
          "model": useModel, // 传给后端：使用哪个模型
        },
        options: Options(
          contentType: Headers.jsonContentType,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      // ==================== 处理返回 ====================
      if (response.statusCode == 200 && response.data != null) {
        final String content = response.data['content'] ?? "无返回内容";
        final String source = response.data['source'] ?? "云端";
        await _db.saveMessage(question, content, source);
        return {"content": content, "source": source};
      } else {
        return {"content": "请求失败（状态码异常）", "source": "错误"};
      }
    } catch (e) {
      debugPrint(">>> ❌ 调度异常: $e");
      return {"content": "网络或服务异常: $e", "source": "网关"};
    }
  }
}