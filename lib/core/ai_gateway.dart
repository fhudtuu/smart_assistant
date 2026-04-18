import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_assistant/core/database/db_helper.dart';

class AiGateway {
  final Dio _dio = Dio();
  final DBHelper _db = DBHelper();

  final String _backendUrl = "http://192.168.2.6:5000/api/chat";

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  AiGateway() {
    debugPrint(">>> backend URL: $_backendUrl");
  }

  /// Smart dispatch: use AI to recognize intent, then dispatch
  Future<Map<String, String>> smartDispatchTask(String question, {String? filePath}) async {
    final intentResult = await _intentRecognize(question, filePath: filePath);
    final String target = intentResult['target'] ?? '';
    final String finalPrompt = intentResult['final_prompt'] ?? question;
    debugPrint('dispatch decision: $target, prompt: $finalPrompt');

    if (target == 'doubao') {
      return dispatchTask(finalPrompt, "you are a multimodal vision expert", filePath: filePath, model: 'doubao');
    } else if (target == '') {
      return dispatchTask(finalPrompt, "you are a document expert", filePath: filePath, model: '');
    } else {
      return dispatchTask(finalPrompt, "you are a general AI assistant", filePath: filePath, model: '');
    }
  }

  /// Intent recognition - returns {target, reason, final_prompt}
  Future<Map<String, dynamic>> _intentRecognize(String question, {String? filePath}) async {
    // 注意：这里只做简单图片检测，不调用后端意图识别，避免 model 选择错误
    // 后端的 paper/datasheet 路由完全由后端根据 originalQuestion 关键词决定
    if (filePath != null && filePath.isNotEmpty) {
      final ext = filePath.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        return {"target": "doubao", "reason": "image file", "final_prompt": question};
      }
      if (['doc', 'docx'].contains(ext)) {
        return {"target": "", "reason": "document file", "final_prompt": question};
      }
    }
    return {"target": "", "reason": "default", "final_prompt": question};
  }

  /// Dispatch task to backend
  /// [model] values: / kimi / doubao
  /// [filePath] auto-detects: images -> doubao, docs -> 
  /// [skipPlugin] true: skip plugin routing (for intent recognition phase)
  Future<Map<String, String>> dispatchTask(
    String question,
    String systemPrompt, {
    String? filePath,
    String model = '',
    bool skipPlugin = false,
    String? originalQuestion,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint(">>> attempt $attempt...");
        String useModel = model;
        String? base64Image;
        bool isDocument = false;

        if (filePath != null && filePath.isNotEmpty) {
          final File file = File(filePath);
          if (await file.exists()) {
            final extension = filePath.split('.').last.toLowerCase();
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
              useModel = "doubao";
              final bytes = await file.readAsBytes();
              base64Image = base64Encode(bytes);
            } else if (['doc', 'docx'].contains(extension)) {
              isDocument = true;
              useModel = "";
            }
          }
        }

        Response response;
        final String baseUrl = skipPlugin ? '$_backendUrl?skip_plugin=1' : _backendUrl;

        if (isDocument) {
          FormData formData = FormData.fromMap({
            "question": question,
            "system_prompt": systemPrompt,
            "model": useModel,
            "document": await MultipartFile.fromFile(
              filePath!,
              filename: filePath.split('/').last,
            ),
          });
          debugPrint(">>> uploading doc to: $baseUrl");
          response = await _dio.post(
            baseUrl,
            data: formData,
            options: Options(
              connectTimeout: const Duration(seconds: 600),
              receiveTimeout: const Duration(seconds: 1800),
            ),
          );
        } else {
          debugPrint(">>> posting to: $baseUrl");
          final Map<String, dynamic> body = {
            "question": question,
            "system_prompt": systemPrompt,
            "image_data": base64Image,
            "model": useModel,
          };
          if (originalQuestion != null && originalQuestion.isNotEmpty) {
            body["original_question"] = originalQuestion;
          }
          response = await _dio.post(
            baseUrl,
            data: body,
            options: Options(
              contentType: Headers.jsonContentType,
              connectTimeout: const Duration(seconds: 300),
              receiveTimeout: const Duration(seconds: 900),
            ),
          );
        }

        if (response.statusCode == 200 && response.data != null) {
          final String content = response.data['content'] ?? "no response";
          final String source = response.data['source'] ?? "cloud";
          // 支持 file_path（本地路径）和 file_url（HTTP URL）
          final String returnFilePath = response.data['file_path'] ?? "";
          final String fileUrl = response.data['file_url'] ?? "";
          // 优先使用 file_url（HTTP 下载链接），如果没有则使用 file_path
          final String finalFile = fileUrl.isNotEmpty ? fileUrl : returnFilePath;
          await _db.saveMessage(question, content, source);
          debugPrint(">>> success!");
          return {"content": content, "source": source, "file_path": finalFile};
        } else {
          return {"content": "request failed", "source": "error"};
        }
      } on DioException catch (e) {
        debugPrint(">>> attempt $attempt failed: ${e.message}");
        if (attempt == _maxRetries) {
          String err = "backend connection failed after $_maxRetries retries\n\n";
          if (e.type == DioExceptionType.connectionTimeout) {
            err = "${err}connection timeout\n";
          } else if (e.type == DioExceptionType.receiveTimeout) {
            err = "${err}receive timeout\n";
          } else if (e.type == DioExceptionType.connectionError) {
            err = "${err}connection error\n";
          }
          err = "$err\ncheck:\n1. python backend/index.py\n2. IP: $_backendUrl\n3. same network\n4. firewall port 5000\n\nerror: ${e.message}";
          return {"content": err, "source": "gateway"};
        }
        await Future.delayed(_retryDelay);
      } catch (e) {
        debugPrint(">>> dispatch error: $e");
        return {"content": "error: $e", "source": "gateway"};
      }
    }
    return {"content": "request failed", "source": "gateway"};
  }
}
