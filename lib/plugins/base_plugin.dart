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
      case 'code':
        return Icons.code;
      case 'calculate':
        return Icons.calculate;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'music_note':
        return Icons.music_note;
      case 'travel_explore':
        return Icons.travel_explore;
      case 'psychology':
        return Icons.psychology;
      case 'brush':
        return Icons.brush;
      case 'science':
        return Icons.science;
      case 'menu_book':
        return Icons.menu_book;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'medical_services':
        return Icons.medical_services;
      case 'work':
        return Icons.work;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'pets':
        return Icons.pets;
      case 'home':
        return Icons.home;
      default:
        return Icons.extension; // 默认显示插件图标
    }
  }

  /// 从 PluginManifest 转换为 BasePlugin（兼容旧代码）
  static BasePlugin fromPluginManifest(dynamic manifest) {
    return BasePlugin(
      id: manifest.id,
      name: manifest.name,
      version: manifest.version,
      icon: _mapIconData(manifest.icon),
      description: manifest.description,
      targetModel: manifest.targetModel ?? '',
      systemPrompt: manifest.systemPrompt,
    );
  }
}