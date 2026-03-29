import 'package:flutter/material.dart';
import 'base_plugin.dart';

class AcademicPlugin extends BasePlugin {
  @override
  String get name => "学术助理";

  @override
  IconData get icon => Icons.auto_stories_rounded; // 选了一个漂亮的书本图标

  @override
  String get description => "专注论文润色与逻辑梳理，是圆圆完成大连大学毕业设计的得力帮手。";

  @override
  String get systemPrompt => "你是一个严谨的学术助理小陆。请用专业且富有逻辑的语言，协助圆圆完成学术研究和论文撰写任务。";
}