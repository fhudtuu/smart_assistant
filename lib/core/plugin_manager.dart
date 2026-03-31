import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // 核心修复：引入 debugPrint 所需的库
import '../plugins/base_plugin.dart';

class PluginManager {
  /// 内存中的插件列表，初始为空
  static List<BasePlugin> allPlugins = [];

  /// 核心改进：异步加载所有插件配置
  /// 这符合毕设中关于“动态化”与“预编译集成+配置动态化”的策略
  static Future<void> loadPlugins() async {
    // 清空旧数据防止重复加载
    allPlugins.clear();
    
    // 待加载的插件配置路径列表
    // 以后每增加一个插件，只需在此列表添加路径并在 pubspec.yaml 注册，无需修改此文件
    final List<String> manifests = [
      'lib/plugins/commute/manifest.json',
      // 'lib/plugins/academic/manifest.json', // 预留后续学术插件路径
      'lib/plugins/document_assistant/manifest.json', // 新增这一行
    ];

    for (String path in manifests) {
      try {
        // 1. 从资源包中读取 JSON 字符串
        final String response = await rootBundle.loadString(path);
        // 2. 解析为 Map
        final Map<String, dynamic> data = json.decode(response);
        // 3. 通过工厂构造函数转化为插件对象并存入列表
        allPlugins.add(BasePlugin.fromJson(data));
        
        debugPrint("系统：插件 [${data['name']}] 加载成功");
      } catch (e) {
        debugPrint("系统错误：无法从 $path 加载插件内容 - $e");
      }
    }
  }

  /// 根据 ID 查找插件（用于模型路由和 UI 切换）
  static BasePlugin? getPluginById(String id) {
    try {
      return allPlugins.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}