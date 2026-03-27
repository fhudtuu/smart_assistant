import 'package:flutter/material.dart';
import 'core/ai_gateway.dart';      
import 'plugins/base_plugin.dart';
import 'chat_bubble.dart'; 
import 'core/plugin_manager.dart'; // 引入管理器

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
  BasePlugin? _currentPlugin; // 当前选中的插件
  bool _isLoading = false; 

  Future<void> askAI(String question) async {
    if (question.isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "content": question});
      _isLoading = true; 
    });
    _controller.clear();
    _scrollToBottom(); 

    try {
      final result = await _gateway.dispatchTask(
        question, 
        _currentPlugin?.systemPrompt ?? "你是一个全能的智能助理。"
      );

      setState(() {
        _messages.add({
          "role": "assistant", 
          "content": "[来自 ${result['source']}] ${result['content']}" 
        });
      });
    } catch (e) {
      setState(() { 
        _messages.add({"role": "assistant", "content": "调度中心异常: $e"}); 
      });
    } finally {
      setState(() { _isLoading = false; }); 
      _scrollToBottom(); 
    }
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      // --- 新增：侧边栏抽屉 ---
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
            // 动态显示 PluginManager 里的所有插件
            ...PluginManager.allPlugins.map((plugin) => ListTile(
              leading: const Icon(Icons.extension, color: Colors.blue),
              title: Text(plugin.name),
              onTap: () {
                setState(() => _currentPlugin = plugin);
                Navigator.pop(context); 
              },
            )),
          ],
        ),
      ),
      // --- AppBar 调整 ---
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
