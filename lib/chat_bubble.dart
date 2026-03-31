import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final String? imagePath;

  const ChatBubble({super.key, required this.content, required this.isUser, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 头像在左
          if (!isUser) _buildAvatar(false),
          
          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // 豆包深炭色：0xFF1E293B, 豆包浅灰色：0xFFF2F3F5
                color: isUser ? const Color(0xFF1E293B) : const Color(0xFFF2F3F5),
                borderRadius: _getBorderRadius(),
                border: isUser 
                    ? null 
                    : Border.all(color: const Color(0xFFE5E6EB), width: 0.5),
              ),
              child: _buildContent(),
            ),
          ),

          const SizedBox(width: 8),

          // 用户头像在右
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  // 核心：复刻豆包的不对称圆角（带指向性的小尾巴）
  BorderRadius _getBorderRadius() {
    const Radius standardRadius = Radius.circular(18);
    const Radius sharpRadius = Radius.circular(4); // 尖角

    if (isUser) {
      return const BorderRadius.only(
        topLeft: standardRadius,
        topRight: standardRadius,
        bottomLeft: standardRadius,
        bottomRight: sharpRadius, // 指向用户头像
      );
    } else {
      return const BorderRadius.only(
        topLeft: standardRadius,
        topRight: standardRadius,
        bottomLeft: sharpRadius, // 指向 AI 头像
        bottomRight: standardRadius,
      );
    }
  }

  Widget _buildAvatar(bool isUserRole) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUserRole ? Colors.blueGrey[100] : const Color(0xFF1E293B),
      ),
      child: Center(
        child: Icon(
          isUserRole ? Icons.person : Icons.auto_awesome,
          size: 18,
          color: isUserRole ? Colors.blueGrey[700] : Colors.tealAccent,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (imagePath != null && imagePath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(imagePath!), width: 200, fit: BoxFit.cover),
            ),
          if (imagePath != null && imagePath!.isNotEmpty) const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              height: 1.4,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null && imagePath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(imagePath!), width: 200, fit: BoxFit.cover),
            ),
          if (imagePath != null && imagePath!.isNotEmpty) const SizedBox(height: 8),
          MarkdownBody(
            data: content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Color(0xFF1D2129), fontSize: 15.5, height: 1.6),
              strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
              code: TextStyle(
                backgroundColor: const Color(0xFFE5E6EB),
                color: const Color(0xFFD91D39),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF272A31),
                borderRadius: BorderRadius.circular(8),
              ),
              listBullet: const TextStyle(color: Color(0xFF0052CC), fontSize: 16),
            ),
          ),
        ],
      );
    }
  }
}