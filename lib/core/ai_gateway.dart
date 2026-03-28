// lib/core/ai_gateway.dart
import 'package:dio/dio.dart';

class AiGateway {
  final Dio _dio = Dio();

  // 【检查点】：确保这里的 IP 依然是你电脑的 IPv4 地址
  // 端口 5000 对应 Python Flask 的默认端口
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
        // 这里的 options 放在 post 方法的参数里，修复了括号嵌套错误
        options: Options(
          connectTimeout: const Duration(seconds: 15), // 连接超时
          receiveTimeout: const Duration(seconds: 30), // 等待 AI 回复超时
        ),
      );

      // 成功获取 Python 返回的数据
      if (response.statusCode == 200 && response.data != null) {
        return {
          "content": response.data['content'] ?? "后端未返回内容",
          "source": response.data['source'] ?? "云端调度"
        };
      } else {
        return {"content": "服务器忙，请稍后再试", "source": "网络拦截"};
      }
    } catch (e) {
      // 这里的报错处理非常关键，真机连不上时会显示具体的 IP 情况
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