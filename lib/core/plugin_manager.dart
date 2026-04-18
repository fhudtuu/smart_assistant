import '../plugins/base_plugin.dart';
import 'plugin_market/plugin_store.dart';

/// 插件管理器 — 委托给 PluginStore，保留向后兼容的静态代理接口
class PluginManager {
  /// 异步初始化所有插件（委托给 PluginStore）
  static Future<void> loadPlugins() async {
    await PluginStore().initialize();
  }

  /// 根据 ID 查找插件（委托给 PluginStore）
  static BasePlugin? getPluginById(String id) {
    final manifest = PluginStore().getById(id);
    if (manifest == null) return null;
    return BasePlugin.fromPluginManifest(manifest);
  }

  /// 获取所有已启用的插件
  static List<BasePlugin> get enabledPlugins {
    return PluginStore()
        .enabledPlugins
        .map((m) => BasePlugin.fromPluginManifest(m))
        .toList();
  }

  /// 获取所有插件
  static List<BasePlugin> get allPlugins {
    return PluginStore()
        .allPlugins
        .map((m) => BasePlugin.fromPluginManifest(m))
        .toList();
  }
}
