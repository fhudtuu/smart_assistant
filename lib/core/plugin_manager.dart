// lib/core/plugin_manager.dart
import '../plugins/base_plugin.dart';
import '../plugins/commute_plugin.dart';
import '../plugins/academic_plugin.dart'; // 1. 引入刚才新建的学术助理

class PluginManager {
  /// 注册所有可用的插件专家库
  /// 以后每增加一个功能模块，只需在此列表添加实例即可
  static List<BasePlugin> allPlugins = [
    CommutePlugin(),   // 真·通勤助手
    AcademicPlugin(),  // 学术助理（新加入）
    // 未来可扩展：WeatherPlugin(), HealthPlugin() 等
  ];

  /// 根据名称查找插件的工具方法（备用，方便后续逻辑调用）
  static BasePlugin? getPluginByName(String name) {
    try {
      return allPlugins.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }
}