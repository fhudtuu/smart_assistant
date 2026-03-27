import 'base_plugin.dart';

class CommutePlugin extends BasePlugin {
  @override
  String get name => "真·通勤助手";

  // 补上这一行，报错就消失了
  @override
  String get iconName => "directions_bus";

  @override
  String get systemPrompt => "你是一个集成实时地图数据的助理。我会为你提供真实的交通指数，请你据此给出专业的避堵建议。";
}