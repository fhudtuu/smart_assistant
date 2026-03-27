// base_plugin.dart
abstract class BasePlugin {
  String get name;         // 插件名（如：通勤助手）
  String get iconName;     // 插件图标名
  String get systemPrompt; // 核心：传给 AI 的身份设定
}