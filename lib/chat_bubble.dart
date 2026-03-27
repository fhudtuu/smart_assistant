// chat_bubble.dart
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const ChatBubble({super.key, required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // 根据是用户还是助理，决定气泡的对齐方式和颜色
    final Alignment alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final Color color = isUser ? Colors.blue[400]! : Colors.grey[200]!;
    final Color textColor = isUser ? Colors.white : Colors.black87;
    // 设置不同的圆角，让气泡更有设计感
    final BorderRadius borderRadius = isUser
        ? const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12))
        : const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12));

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: borderRadius),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7), // 限制气泡最大宽度
        child: Text(content, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }
}