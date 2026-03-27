// lib/core/plugin_manager.dart
import '../plugins/base_plugin.dart';
import '../plugins/commute_plugin.dart';

class PluginManager {
  // 1. 注册所有可用的插件（以后加新插件，只需要在这里加一行）
  static final List<BasePlugin> allPlugins = [
    CommutePlugin(),
    // 未来可以加：StudyPlugin(), WeatherPlugin()...
  ];
}