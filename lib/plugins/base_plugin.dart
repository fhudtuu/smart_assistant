// lib/plugins/base_plugin.dart
import 'package:flutter/material.dart';

abstract class BasePlugin {
  /// 插件名称（如：通勤助手）
  String get name; 
  
  /// 插件显示的图标（使用 Flutter 原生 IconData）
  IconData get icon; 
  
  /// 插件的功能简述（用于在插件市场展示）
  String get description; 
  
  /// 核心设定：传给 AI 后端的 System Prompt
  String get systemPrompt; 
}