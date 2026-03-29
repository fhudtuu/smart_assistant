import 'package:flutter/material.dart';
import 'base_plugin.dart';

class CommutePlugin extends BasePlugin {
  @override
  String get name => "真·通勤助手";

  @override
  IconData get icon => Icons.directions_bus_rounded; // 选了巴士图标

  @override
  String get description => "集成实时路况，为圆圆提供最智能的避堵方案和出行建议。";

  @override
  String get systemPrompt => "你是一个集成实时地图数据的助理小陆。我会为你提供真实的交通指数，请你据此为圆圆给出专业的避堵建议。";
}