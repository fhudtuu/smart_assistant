// lib/core/ai_gateway.dart
import 'package:dio/dio.dart';
import 'tool_box.dart'; 

class AiGateway {
  static const String _deepSeekKey = "sk-d744e85e0ca74175bdc094b8abc6996a";
  final Dio _dio = Dio();

  Future<Map<String, String>> dispatchTask(String question, String systemPrompt) async {
    // 逻辑 A：判断是否需要激活“真·通勤助手”工具调用
    if (systemPrompt.contains("交通") || question.contains("去") || question.contains("路况")) {
      
      // 1. 自动提取目的地
      String destination = question.replaceAll(RegExp(r'去|路况|查一下|怎么样|到'), '').trim();
      if (destination.isEmpty) destination = "目的地";

      // 2. 调用高德 API 获取真实数据
      String trafficData = await ToolBox.getRealTimeTraffic(destination);

      // 3. 【核心优化】：构建强约束的 Prompt（提示词）
      // 我们用明确的分隔符和指令，强制 AI 必须处理 trafficData
      String enhancedPrompt = """
        # 角色设定
        $systemPrompt
        
        # 实时外部数据（高德地图提供）
        $trafficData
        
        # 强制性回答规则
        1. 严禁编造路况！你必须且只能基于上面的【实时外部数据】来回答。
        2. 你的回答中必须包含以下要素：目的地名称、具体的距离（公里）、预计耗时（分钟）。
        3. 请根据数据中的路径标签（如：避堵、畅通）给用户一个具体的建议。
        4. 语气要像专业的私人管家，简明扼要。
        
        # 当前用户问题
        $question
      """;
      
      return await _callAI(question, enhancedPrompt, "真·通勤助手");
    }

    // 逻辑 B：普通对话模式
    return await _callAI(question, systemPrompt, "全能内核");
  }

  Future<Map<String, String>> _callAI(String question, String prompt, String source) async {
    try {
      final response = await _dio.post(
        'https://api.deepseek.com/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_deepSeekKey',
          'Content-Type': 'application/json',
        }),
        data: {
          "model": "deepseek-chat",
          "messages": [
            {"role": "system", "content": prompt}, // 这里的 prompt 已经包含了实时数据
            {"role": "user", "content": question}
          ],
          "temperature": 0.3, // 调低随机性，让它更听话、不乱发挥
        },
      );
      return {
        "content": response.data['choices'][0]['message']['content'],
        "source": source
      };
    } catch (e) {
      throw Exception("AI 调度中心请求失败: $e");
    }
  }
}