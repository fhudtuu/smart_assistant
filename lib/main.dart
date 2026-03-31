import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'core/ai_gateway.dart';      
import 'plugins/base_plugin.dart';
import 'chat_bubble.dart'; 
import 'core/plugin_manager.dart'; 
import 'core/database/db_helper.dart'; 
import 'pages/plugin_market_page.dart';
import 'core/media_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PluginManager.loadPlugins();
  runApp(const MaterialApp(
    home: ChatScreen(),
    debugShowCheckedModeBanner: false, 
  ));
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  
  final AiGateway _gateway = AiGateway(); 
  final DBHelper _db = DBHelper(); 
  final MediaHandler _mediaHandler = MediaHandler();
  
  BasePlugin? _currentPlugin; 
  bool _isLoading = false; 
  bool _isPanelOpen = false; 

  // --- 多模态暂存状态 ---
  File? _selectedFile;
  String? _selectedFileType;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // 选取媒体（仅暂存预览，不立刻发送）
  Future<void> _onMediaTapped(String type) async {
    File? file;
    if (type == 'camera') file = await _mediaHandler.pickImage(ImageSource.camera);
    if (type == 'gallery') file = await _mediaHandler.pickImage(ImageSource.gallery);
    if (type == 'file') file = await _mediaHandler.pickFile();

    if (file != null) {
      setState(() {
        _selectedFile = file;
        _selectedFileType = type;
        _isPanelOpen = false; 
      });
      _scrollToBottom();
    }
  }

  // 核心：支持文本 + 图片混合发送
  Future<void> askAI(String question) async {
    if (question.isEmpty && _selectedFile == null) return;
    
    String displayContent = question;
    String? currentImagePath = _selectedFile?.path; // 获取本地路径

    // 如果只有图片没有文字，自动补全指令
    if (question.isEmpty && _selectedFile != null) {
      displayContent = _selectedFileType == 'file' ? "请分析这个文档。" : "请分析这张图片。";
    }

    setState(() {
      _messages.add({
        "role": "user", 
        "content": displayContent,
        "imagePath": currentImagePath ?? "" 
      });
      _isLoading = true; 
      _isPanelOpen = false;
      _selectedFile = null; // 发送后清除预览
    });
    
    _controller.clear();
    _scrollToBottom(); 

    try {
      // --- 发送给网关，触发 Base64 转码与后端路由 ---
      final result = await _gateway.dispatchTask(
        displayContent, 
        _currentPlugin?.systemPrompt ?? "你是一个助理。",
        imagePath: currentImagePath, 
      );
      
      if (!mounted) return;

      // --- 关键解析：确保提取 result 中的 content 字段 ---
      setState(() {
        _messages.add({
          "role": "assistant", 
          "content": result['content'] ?? "后端未返回有效识别结果",
          "imagePath": ""
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { 
        _messages.add({"role": "assistant", "content": "调度异常: $e", "imagePath": ""}); 
      });
    } finally {
      if (mounted) { 
        setState(() => _isLoading = false); 
        _scrollToBottom(); 
      }
    }
  }

  Future<void> _loadChatHistory() async {
    final history = await _db.getHistory();
    if (!mounted) return;
    setState(() {
      for (var row in history.reversed) {
        _messages.add({"role": "user", "content": row['question']?.toString() ?? "", "imagePath": ""});
        _messages.add({"role": "assistant", "content": row['answer']?.toString() ?? "", "imagePath": ""});
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      });
    }
  }

  void _goToMarket() async {
    final selected = await Navigator.push<BasePlugin>(
      context, 
      MaterialPageRoute(builder: (context) => const PluginMarketPage())
    );
    if (!mounted) return;
    if (selected != null) setState(() => _currentPlugin = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentPlugin == null ? "智能助理" : _currentPlugin!.name, 
                style: const TextStyle(color: Colors.black, fontSize: 16)),
            const Text("多模态视觉增强版", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.black87), 
            onPressed: _goToMarket
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, 
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  content: msg["content"]!, 
                  isUser: msg["role"] == "user",
                  imagePath: msg["imagePath"], 
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 1, color: Color(0xFF28C4A6)), 
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border(top: BorderSide(color: Colors.grey[200]!))
      ),
      child: SafeArea(
        child: Column(
          children: [
            // --- 选图后的预览小窗 ---
            if (_selectedFile != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100], 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedFile!, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("待发送图片已就绪...", style: TextStyle(fontSize: 13, color: Colors.teal)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Colors.grey), 
                      onPressed: () => setState(() => _selectedFile = null)
                    )
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (v) => askAI(v),
                      decoration: const InputDecoration(hintText: "发消息...", border: InputBorder.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isPanelOpen ? Icons.cancel : Icons.add_circle_outline, 
                       color: Colors.teal, size: 28),
                  onPressed: () => setState(() => _isPanelOpen = !_isPanelOpen),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.teal, size: 28), 
                  onPressed: () => askAI(_controller.text)
                ),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isPanelOpen ? 90 : 0,
              child: _isPanelOpen 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FeatureIcon(Icons.camera_alt, "拍照", () => _onMediaTapped('camera')),
                      _FeatureIcon(Icons.image, "相册", () => _onMediaTapped('gallery')),
                      _FeatureIcon(Icons.folder_shared, "文件", () => _onMediaTapped('file')),
                    ],
                  )
                : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeatureIcon(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[50], 
            child: Icon(icon, color: Colors.teal, size: 24)
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}