import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_assistant/core/database/db_helper.dart';

class AiGateway {
  final Dio _dio = Dio();
  final DBHelper _db = DBHelper();
  
  // 🚨 导师提醒：如果一会运行还是报超时，请务必在电脑的 cmd 里输入 ipconfig 检查 IPv4 地址
  // 如果你的电脑 IP 变了，一定要把下面这行的 192.168.81.221 换成最新的 IP！
  final String _backendUrl = "http://192.168.2.6:5000/api/chat";
  
  // 重试配置
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  AiGateway() {
    // 调试：打印后端 URL
    debugPrint(">>> 🔗 后端 URL: $_backendUrl");
    debugPrint(">>> 💡 如果连接超时，请检查：");
    debugPrint("    1️⃣  后端是否启动：python backend/index.py");
    debugPrint("    2️⃣  电脑 IP 是否正确：在 cmd 中运行 ipconfig，查看 IPv4 地址");
    debugPrint("    3️⃣  手机/模拟器是否与电脑在同一网络");
  }

  /// 智能分发：DeepSeek为总指挥官，先识别意图再分发
  Future<Map<String, String>> smartDispatchTask(String question, {String? filePath}) async {
    // 1. 先让 DeepSeek 识别意图
    final intentResult = await _intentRecognize(question, filePath: filePath);
    final String target = intentResult['target'] ?? 'deepseek';
    final String finalPrompt = intentResult['final_prompt'] ?? question;
    debugPrint('DeepSeek分发决策: $target, prompt: $finalPrompt');

    // 2. 根据 target 决定分发
    if (target == 'doubao') {
      return await dispatchTask(finalPrompt, "你是多模态视觉专家，擅长图片理解。", filePath: filePath, model: 'doubao');
    } else if (target == 'kimi') {
      return await dispatchTask(finalPrompt, "你是文档处理专家，擅长长文档分析与润色。", filePath: filePath, model: 'kimi');
    } else {
      return await dispatchTask(finalPrompt, "你是通用AI助手。", filePath: filePath, model: 'deepseek');
    }
  }

  /// DeepSeek意图识别，返回 {target, reason, final_prompt}
  Future<Map<String, dynamic>> _intentRecognize(String question, {String? filePath}) async {
    String systemPrompt = '''你是一个智能助手的总指挥官。请根据用户输入内容和文件类型，判断应该由哪个AI负责处理，并返回如下JSON：\n{\n  "target": "deepseek|doubao|kimi",\n  "reason": "分发理由",\n  "final_prompt": "给下属AI的最终prompt"\n}\n规则：\n- 如果是图片/多模态任务，target填doubao\n- 如果是文档处理/润色/排版，target填kimi\n- 其他通用对话、知识问答、推理等，target填deepseek\n- 只返回JSON，不要多余解释。''';
    String userInput = question;
    if (filePath != null && filePath.isNotEmpty) {
      final ext = filePath.split('.').last.toLowerCase();
      userInput += "\n(文件类型: .$ext)";
    }
    try {
      final resp = await dispatchTask(userInput, systemPrompt, model: 'deepseek');
      final content = resp['content'] ?? '';
      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final jsonStr = content.substring(start, end + 1);
        return json.decode(jsonStr);
      }
    } catch (e) {
      debugPrint('意图识别异常: $e');
    }
    // 兜底
    return {"target": "deepseek", "reason": "兜底", "final_prompt": question};
  }

  /// 调度任务
  /// [model] 可选值：deepseek / kimi / doubao
  /// 传 [filePath] 时，根据文件后缀自动判断：
  /// - 图片：自动强制使用 doubao 视觉模型，转 Base64
  /// - 文档(Word)：自动强制使用 kimi 模型，通过 FormData 上传
  Future<Map<String, String>> dispatchTask(
    String question,
    String systemPrompt, {
    String? filePath, 
    String model = "deepseek", 
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint(">>> 📡 第 $attempt 次请求尝试...");
        String useModel = model;
        String? base64Image;
        bool isDocument = false;

        // ==================== 文件处理与模型选择 ====================
        if (filePath != null && filePath.isNotEmpty) {
          final File file = File(filePath);
          if (await file.exists()) {
            final extension = filePath.split('.').last.toLowerCase();
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
              useModel = "doubao";
              debugPrint(">>> 🖼️ 检测到图片，自动切换为豆包视觉");
              // 转 Base64 处理
              final bytes = await file.readAsBytes();
              base64Image = base64Encode(bytes);
            } else if (['doc', 'docx'].contains(extension)) {
              isDocument = true;
              useModel = "kimi";
              debugPrint(">>> 📄 检测到文档，自动切换为 Kimi，准备表单上传");
            }
          }
        }

        // ==================== 请求后端 ====================
        Response response;

        if (isDocument) {
          // 模式 1：【文档模式】使用 FormData 上传真实文件
          FormData formData = FormData.fromMap({
            "question": question,
            "system_prompt": systemPrompt,
            "model": useModel,
            "document": await MultipartFile.fromFile(
              filePath!,
              filename: filePath.split('/').last,
            ),
          });

          debugPrint(">>> 🚀 发送文件上传请求到: $_backendUrl");
          response = await _dio.post(
            _backendUrl,
            data: formData,
            options: Options(
              // 🚨 超级加强版超时：连接 10 分钟，接收 30 分钟（大文件 + 大模型处理）
              connectTimeout: const Duration(seconds: 600),
              receiveTimeout: const Duration(seconds: 1800),
            ),
          );
        } else {
          // 模式 2：【普通文本/图片模式】
          debugPrint(">>> 🚀 发送文本/图片请求到: $_backendUrl");
          response = await _dio.post(
            _backendUrl,
            data: {
              "question": question,
              "system_prompt": systemPrompt,
              "image_data": base64Image,
              "model": useModel,
            },
            options: Options(
              contentType: Headers.jsonContentType,
              // 文本和图片：连接 5 分钟，接收 15 分钟
              connectTimeout: const Duration(seconds: 300),
              receiveTimeout: const Duration(seconds: 900),
            ),
          );
        }

        // ==================== 处理返回 ====================
        if (response.statusCode == 200 && response.data != null) {
          final String content = response.data['content'] ?? "无返回内容";
          final String source = response.data['source'] ?? "云端";
          
          // 提取后端传来的生成文件路径 URL
          final String returnFilePath = response.data['file_path'] ?? ""; 
          
          // 存入本地数据库
          await _db.saveMessage(question, content, source);
          
          debugPrint(">>> ✅ 请求成功！");
          // 把 file_path 一起 return 给 main.dart 里的界面
          return {
            "content": content, 
            "source": source,
            "file_path": returnFilePath
          };
        } else {
          return {"content": "请求失败（状态码异常）", "source": "错误"};
        }
      } on DioException catch (e) {
        debugPrint(">>> ⚠️ 第 $attempt 次请求失败: ${e.message}");
        debugPrint(">>> 🔍 错误详情：${e.type}");
        
        // 如果是最后一次尝试，返回错误
        if (attempt == _maxRetries) {
          debugPrint(">>> ❌ 已达到重试次数上限 ($_maxRetries)，放弃");
          String errorMsg = "【后端连接失败】已重试 $_maxRetries 次\n\n";
          
          // 根据不同的错误类型给出具体建议
          if (e.type == DioExceptionType.connectionTimeout) {
            errorMsg += "⏱️ 连接超时 - 后端可能未响应\n";
          } else if (e.type == DioExceptionType.receiveTimeout) {
            errorMsg += "⏱️ 接收超时 - 后端处理耗时过长\n";
          } else if (e.type == DioExceptionType.connectionError) {
            errorMsg += "🔗 网络连接错误 - 可能无法访问后端\n";
          }
          
          errorMsg += "\n🔧 请检查：\n";
          errorMsg += "1. 后端是否启动：python backend/index.py\n";
          errorMsg += "2. IP是否正确：$_backendUrl\n";
          errorMsg += "3. cmd中运行 ipconfig 查看IPv4地址\n";
          errorMsg += "4. 手机/模拟器与电脑是否在同一网络\n";
          errorMsg += "5. 防火墙是否允许5000端口\n\n";
          errorMsg += "原始错误：${e.message}";
          
          return {
            "content": errorMsg,
            "source": "网关"
          };
        }
        
        // 等待后再重试
        debugPrint(">>> ⏳ 等待 ${_retryDelay.inSeconds} 秒后重试...");
        await Future.delayed(_retryDelay);
      } catch (e) {
        debugPrint(">>> ❌ 调度异常: $e");
        return {"content": "网络或服务异常: $e", "source": "网关"};
      }
    }
    
    // 兜底（理论上不会执行到这里）
    return {"content": "请求失败，请检查网络连接", "source": "网关"};
  }
}