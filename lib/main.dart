import 'package:flutter/material.dart';
import 'core/ai_gateway.dart';      
import 'plugins/base_plugin.dart';
import 'chat_bubble.dart'; 
import 'core/plugin_manager.dart';
import 'core/database/db_helper.dart'; 
import 'pages/plugin_market_page.dart';

void main() => runApp(const MaterialApp(
  home: ChatScreen(),
  debugShowCheckedModeBanner: false, 
));

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
  BasePlugin? _currentPlugin; 
  bool _isLoading = false; 
  bool _isPanelOpen = false; // 控制面板开关

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // --- 核心逻辑：安全跳转插件市场 ---
  void _goToMarket() async {
    final selected = await Navigator.push<BasePlugin>(
      context,
      MaterialPageRoute(builder: (context) => const PluginMarketPage()),
    );
    
    // 异步 gap 后必须检查 mounted
    if (!mounted) return;

    if (selected != null) {
      setState(() { _currentPlugin = selected; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("已为您切换至：${selected.name}"), 
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadChatHistory() async {
    final history = await _db.getHistory();
    if (!mounted) return;
    setState(() {
      for (var row in history.reversed) {
        _messages.add({"role": "user", "content": row['question']});
        _messages.add({"role": "assistant", "content": "[来自 ${row['source']}] ${row['answer']}"});
      }
    });
    _scrollToBottom();
  }

  Future<void> askAI(String question) async {
    if (question.isEmpty) return;
    setState(() {
      _messages.add({"role": "user", "content": question});
      _isLoading = true; 
      _isPanelOpen = false; // 发送时自动关闭面板
    });
    _controller.clear();
    _scrollToBottom(); 
    try {
      final result = await _gateway.dispatchTask(
        question, 
        _currentPlugin?.systemPrompt ?? "你是一个全能的智能助理。"
      );
      if (!mounted) return;
      setState(() {
        _messages.add({"role": "assistant", "content": "[来自 ${result['source']}] ${result['content']}"});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _messages.add({"role": "assistant", "content": "调度中心异常: $e"}); });
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; }); 
        _scrollToBottom(); 
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOut
          );
        }
      });
    }
  }

  // 构建功能扩展面板
  Widget _buildActionPanel() {
    final List<Map<String, dynamic>> actions = [
      {"name": "相机", "icon": Icons.camera_alt_rounded, "color": Colors.orange},
      {"name": "相册", "icon": Icons.image_rounded, "color": Colors.green},
      {"name": "文件", "icon": Icons.attach_file_rounded, "color": Colors.blue},
      {"name": "打电话", "icon": Icons.phone_rounded, "color": Colors.red},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(item["icon"], color: item["color"], size: 28),
            ),
            const SizedBox(height: 8),
            Text(item["name"], style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                    SizedBox(height: 10),
                    Text("圆圆的智能助手", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.apps_rounded, color: Colors.blueAccent),
              title: const Text("前往插件市场", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { Navigator.pop(context); _goToMarket(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.stars, color: Colors.orange),
              title: const Text("全能助理（默认）"),
              selected: _currentPlugin == null,
              onTap: () { setState(() => _currentPlugin = null); Navigator.pop(context); },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: PluginManager.allPlugins.map((plugin) => ListTile(
                  leading: Icon(plugin.icon, color: Colors.blue[300]),
                  title: Text(plugin.name),
                  selected: _currentPlugin == plugin,
                  onTap: () { setState(() => _currentPlugin = plugin); Navigator.pop(context); },
                )).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              title: const Text("清空本地记忆", style: TextStyle(color: Colors.red)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context); 
                
                await _db.clearHistory(); 
                
                if (!mounted) return; 

                setState(() { _messages.clear(); });
                
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("本地对话记忆已清除"), 
                    behavior: SnackBarBehavior.floating
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentPlugin == null ? "智能内核" : _currentPlugin!.name, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("当前引擎：DeepSeek-V3", style: TextStyle(color: Colors.green, fontSize: 10)),
          ],
        ),
        backgroundColor: Colors.white, 
        elevation: 0.5, 
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [IconButton(icon: const Icon(Icons.grid_view_rounded), onPressed: _goToMarket)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, 
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return ChatBubble(content: m["content"]!, isUser: m["role"] == "user");
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: LinearProgressIndicator(minHeight: 2, color: Colors.blueAccent)), 
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(
                  // 修复：使用新的 withValues 代替弃用的 withOpacity
                  color: Colors.black.withValues(alpha: 0.05), 
                  blurRadius: 10
                )
              ],
              border: Border(top: BorderSide(color: Colors.grey[200]!))
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isPanelOpen ? Icons.cancel_outlined : Icons.add_circle_outline, color: Colors.blueAccent),
                      onPressed: () {
                        setState(() { _isPanelOpen = !_isPanelOpen; });
                      },
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _controller, 
                          onSubmitted: (value) => askAI(value),
                          decoration: const InputDecoration(hintText: "发消息或按住说话...", border: InputBorder.none)
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.blueAccent), 
                      onPressed: () => askAI(_controller.text)
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  height: _isPanelOpen ? 160 : 0, 
                  child: _isPanelOpen ? _buildActionPanel() : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10), 
        ],
      ),
    );
  }
}
