import 'package:flutter/material.dart';
import 'core/ai_gateway.dart';      
import 'plugins/base_plugin.dart';
import 'chat_bubble.dart'; 
import 'core/plugin_manager.dart';
import 'core/database/db_helper.dart'; 

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

  @override
  void initState() {
    super.initState();
    // 启动时自动从本地数据库恢复“记忆”，实现数据持久化 [cite: 74]
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final history = await _db.getHistory();
    if (!mounted) return;
    
    setState(() {
      // 反转列表，确保旧消息在上，新消息在下
      for (var row in history.reversed) {
        _messages.add({"role": "user", "content": row['question']});
        _messages.add({
          "role": "assistant", 
          "content": "[来自 ${row['source']}] ${row['answer']}"
        });
      }
    });
    _scrollToBottom();
  }

  Future<void> askAI(String question) async {
    if (question.isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "content": question});
      _isLoading = true; 
    });
    _controller.clear();
    _scrollToBottom(); 

    try {
      // 调用统一AI网关分发任务 [cite: 34, 50]
      final result = await _gateway.dispatchTask(
        question, 
        _currentPlugin?.systemPrompt ?? "你是一个全能的智能助理。"
      );

      if (!mounted) return;
      setState(() {
        _messages.add({
          "role": "assistant", 
          "content": "[来自 ${result['source']}] ${result['content']}" 
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { 
        _messages.add({"role": "assistant", "content": "调度中心异常: $e"}); 
      });
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text("圆圆的插件中心", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.stars, color: Colors.orange),
              title: const Text("全能助理（默认）"),
              onTap: () {
                setState(() => _currentPlugin = null);
                Navigator.pop(context); 
              },
            ),
            const Divider(),
            // 动态展示插件列表，体现“内核-插件”架构 [cite: 9, 23]
            ...PluginManager.allPlugins.map((plugin) => ListTile(
              leading: const Icon(Icons.extension, color: Colors.blue),
              title: Text(plugin.name),
              onTap: () {
                setState(() => _currentPlugin = plugin);
                Navigator.pop(context); 
              },
            )),
            const Spacer(), 
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text("清空本地记忆", style: TextStyle(color: Colors.red)),
              onTap: () async {
                // 先获取 Navigator 实例，解决异步 Context 安全警告
                final navigator = Navigator.of(context);
                
                await _db.clearHistory();
                
                if (!mounted) return;
                setState(() { _messages.clear(); });
                navigator.pop(); // 退出侧边栏
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          _currentPlugin == null ? "智能内核" : _currentPlugin!.name, 
          style: const TextStyle(color: Colors.black, fontSize: 18)
        ),
        backgroundColor: Colors.white, 
        elevation: 0.5, 
        iconTheme: const IconThemeData(color: Colors.black),
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
          if (_isLoading) 
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
              child: LinearProgressIndicator(minHeight: 2)
            ), 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white, 
              border: Border(top: BorderSide(color: Colors.grey[200]!))
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _controller, 
                      decoration: const InputDecoration(
                        hintText: "问问你的移动助理...", 
                        border: InputBorder.none
                      )
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20), 
                    onPressed: () => askAI(_controller.text)
                  ),
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
