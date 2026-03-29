// lib/chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; 

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const ChatBubble({super.key, required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // 1. 定义对齐方式
    final Alignment alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    
    // 2. 颜色方案
    final Color color = isUser ? Colors.blue[600]! : Colors.grey[100]!;
    
    // 3. 气泡圆角设计：根据发送者身份调整缺角位置
    final BorderRadius borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          // 仅给 AI 气泡添加极浅边框
          border: isUser ? null : Border.all(color: Colors.grey[300]!, width: 0.5),
          boxShadow: [
            BoxShadow(
              // 关键修正：使用 withValues 替代过时的 withOpacity，适配最新 Flutter 版本
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        // 限制气泡最大宽度
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        
        // 4. 内容展示逻辑
        child: isUser
            ? Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : MarkdownBody(
                data: content,
                selectable: true, // 允许长按复制
                shrinkWrap: true, // 确保列表能正常展示
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.5),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  listBullet: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  code: TextStyle(
                    backgroundColor: Colors.grey[300],
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
      ),
    );
  }
}