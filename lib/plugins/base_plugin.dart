import 'package:flutter/material.dart';

class BasePlugin {
  final String id;
  final String name;
  final String version;
  final IconData icon;
  final String description;
  final String targetModel;
  final String systemPrompt;

  BasePlugin({
    required this.id,
    required this.name,
    required this.version,
    required this.icon,
    required this.description,
    required this.targetModel,
    required this.systemPrompt,
  });

  /// 核心改进：从 manifest.json 转换的工厂方法
  /// 这符合毕设中关于“插件协议”与“动态化”的设计要求
  factory BasePlugin.fromJson(Map<String, dynamic> json) {
    return BasePlugin(
      id: json['id'] ?? '',
      name: json['name'] ?? '未知插件',
      version: json['version'] ?? '1.0.0',
      // 根据 JSON 中的字符串映射 Flutter 原生图标
      icon: _mapIconData(json['icon']),
      description: json['description'] ?? '',
      targetModel: json['target_model'] ?? 'default',
      systemPrompt: json['system_prompt'] ?? '你是一个通用的 AI 助手。',
    );
  }

  /// 图标映射逻辑：将字符串转为 Flutter IconData
  static IconData _mapIconData(String? iconName) {
    switch (iconName) {
      case 'directions_car':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      case 'description':
        return Icons.description;
      case 'smart_toy':
        return Icons.smart_toy;
      default:
        return Icons.extension; // 默认显示插件图标
    }
  }
}