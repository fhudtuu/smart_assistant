import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final String? imagePath;
  final String? source;

  const ChatBubble({super.key, required this.content, required this.isUser, this.imagePath, this.source});

  bool _isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  /// 跳���到地图：优先高德 App，其次百度 App，最后才降级到网页版
  Future<void> _openMap() async {
    // 高德 App 路径规划页（带参数更容易唤起）
    const String amapUrl = 'iosamap://path?sourceApplication=smart_assistant&dname=我的目的地';
    const String amapAndroidUrl = 'amapuri://route/plan/?sourceApplication=smart_assistant&dname=我的目的地';

    // 百度 App 路径规划页（带参数更容易唤起）
    const String bdmapUrl = 'baidumap://map/direction?origin=&destination=我的目的地&mode=driving&src=smart_assistant';

    const String gaoDeWeb = 'https://www.amap.com';
    const String bdmapWeb = 'https://map.baidu.com';

    // 1. 尝试高德 App（Android 和 iOS 用不同 scheme）
    try {
      final uri = Uri.parse(amapAndroidUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    try {
      final uri = Uri.parse(amapUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    // 2. 尝试百度 App
    try {
      final bdmapUri = Uri.parse(bdmapUrl);
      final launched = await launchUrl(bdmapUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    // 3. 都没有 App 才降级到网页版，优先高德网页
    try {
      final webUri = Uri.parse(gaoDeWeb);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // 4. 高德网页也不行，再用百度网页
    try {
      final bdwebUri = Uri.parse(bdmapWeb);
      if (await canLaunchUrl(bdwebUri)) {
        await launchUrl(bdwebUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// 安全的 URI 解码函数：处理可能无效的百分比编码
  String _safeUriDecode(String encoded) {
    try {
      return Uri.decodeComponent(encoded);
    } catch (e) {
      // 如果解码失败，直接返回原始字符串
      return encoded;
    }
  }

  // 🚨 终极改造：先从电脑端下载文件到手机，然后再分享
  void _saveFileToDevice(BuildContext context, String fileUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ 正在从服务器拉取文件...'), duration: Duration(seconds: 1)),
      );

      // 1. 获取手机的系统临时文件夹
      final tempDir = Directory.systemTemp;
      
      // 2. 从 URL 中解析出中文文件名并安全解码
      final rawFileName = fileUrl.split('/').last;
      final fileName = _safeUriDecode(rawFileName);
      final savePath = '${tempDir.path}/$fileName';

      // 3. 下载文件到手机本地
      await Dio().download(fileUrl, savePath);

      // 4. 调用原生面板分享刚刚下载到手机上的文件
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(savePath)], 
          text: '这是为您排版与润色好的文档。', 
        )
      );

      if (result.status == ShareResultStatus.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 文件导出成功！', style: TextStyle(color: Colors.white)), 
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 下载或处理失败: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, 
        children: [
          if (!isUser) _buildAvatar(false),
          if (!isUser) const SizedBox(width: 10),

          Flexible(
            child: isUser ? _buildUserBubble(context) : _buildAIBubble(context),
          ),

          if (isUser) const SizedBox(width: 10),
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF28C4A6), Color(0xFF0D92BA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFF0D92BA).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4)),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildAIBubble(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), 
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65), 
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
            ),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isUserRole) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUserRole ? const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)]) : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Center(
        child: Icon(isUserRole ? Icons.person_rounded : Icons.auto_awesome_rounded, size: 20, color: isUserRole ? const Color(0xFF475569) : Colors.tealAccent),
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) return const SizedBox.shrink();

    final bool isImg = _isImage(imagePath!);

    return GestureDetector(
      // 点击下载并呼出面板
      onTap: (!isUser && !isImg) ? () => _saveFileToDevice(context, imagePath!) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isImg 
              ? Image.file(File(imagePath!), width: 220, fit: BoxFit.cover)
              : Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  color: Colors.white, 
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.description_rounded, color: Colors.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          // 即使是 URL，也能正确显示出中文文件名（安全解码）
                          _safeUriDecode(imagePath!.split('/').last),
                          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      ),
                      if (!isUser)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.ios_share_rounded, color: Colors.teal, size: 22),
                        )
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 统一的复制回调
    void copyText() {
      Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已复制到剪贴板', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }

    if (isUser) {
      return GestureDetector(
        onLongPress: copyText,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMediaCard(context),
            Text(content, style: const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.5, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onLongPress: copyText,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaCard(context),
            MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Color(0xFF1E293B), fontSize: 15.5, height: 1.6),
                strong: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                code: TextStyle(backgroundColor: Colors.black.withValues(alpha: 0.05), color: const Color(0xFFE11D48), fontSize: 14, fontFamily: 'monospace'),
                codeblockDecoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                listBullet: const TextStyle(color: Color(0xFF28C4A6), fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            // 只有 source 为"通勤助手"时才显示跳转按钮
            if (source == '通勤助手') ...[
              GestureDetector(
                onTap: _openMap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, color: Colors.teal, size: 16),
                      SizedBox(width: 4),
                      Text('通勤助手', style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
}