import 'package:flutter/material.dart';
import '../core/plugin_manager.dart';
import '../plugins/base_plugin.dart';

class PluginMarketPage extends StatelessWidget {
  const PluginMarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // 浅灰色背景衬托白色卡片
      appBar: AppBar(
        title: const Text("插件市场", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "发现 AI 专家", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueAccent)
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 每行两列
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8, // 控制卡片的高矮
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final plugin = PluginManager.allPlugins[index];
                  return _buildPluginCard(context, plugin);
                },
                childCount: PluginManager.allPlugins.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginCard(BuildContext context, BasePlugin plugin) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, plugin), // 选中后带回数据并关闭市场
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              // 适配最新 Flutter 语法的颜色写法
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle, // 直接使用标准写法
              ),
              child: Icon(plugin.icon, size: 36, color: Colors.blueAccent),
            ),
            const SizedBox(height: 16),
            Text(
              plugin.name, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                plugin.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}