import 'package:flutter/material.dart';
import '../core/plugin_market/plugin_store.dart';
import '../core/plugin_market/plugin_protocol.dart';
import '../core/plugin_market/plugin_import_service.dart';
import 'plugin_editor_page.dart';
import 'plugin_management_page.dart';
import 'plugin_help_page.dart';

class PluginMarketPage extends StatefulWidget {
  const PluginMarketPage({super.key});

  @override
  State<PluginMarketPage> createState() => _PluginMarketPageState();
}

class _PluginMarketPageState extends State<PluginMarketPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final store = PluginStore();
    switch (_tabController.index) {
      case 0:
        store.clearFilters();
        break;
      case 1:
        store.setFilter(source: PluginSource.builtin);
        break;
      case 2:
        store.setFilter(source: PluginSource.imported);
        break;
      case 3:
        store.setFilter(source: PluginSource.created);
        break;
    }
  }

  Future<void> _importPlugin() async {
    await PluginImportService().importAndInstall(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '插件市场',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '内置'),
            Tab(text: '导入'),
            Tab(text: '我的'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使用指南',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PluginHelpPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: '创建插件',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PluginEditorPage(),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导入插件',
            onPressed: _importPlugin,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '管理插件',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PluginManagementPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 使用提示横幅
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PluginHelpPage()),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[400]!, Colors.teal[600]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '不知道插件怎么用？点击查看使用指南',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),

          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索插件名称、描述或标签...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          PluginStore().setFilter(query: '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => PluginStore().setFilter(query: v),
            ),
          ),

          // 分类横向滚动标签
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, '全部'),
                _buildCategoryChip('productivity', '效率'),
                _buildCategoryChip('academic', '学术'),
                _buildCategoryChip('life', '生活'),
                _buildCategoryChip('creative', '创意'),
                _buildCategoryChip('development', '开发'),
                _buildCategoryChip('health', '健康'),
                _buildCategoryChip('travel', '旅行'),
                _buildCategoryChip('other', '其他'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 插件网格
          Expanded(
            child: ListenableBuilder(
              listenable: PluginStore(),
              builder: (context, _) {
                final store = PluginStore();
                final plugins = store.filteredPlugins;

                if (plugins.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.extension_off,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            '暂无插件',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 16),
                          ),
                          const SizedBox(height: 24),

                          // 快速入门卡片
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.teal[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🎉 欢迎使用插件市场！',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '插件可以扩展智能助理的能力，让 AI 更懂你的需求。',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _QuickAction(
                                      icon: Icons.add_box_outlined,
                                      label: '创建插件',
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const PluginEditorPage(),
                                          ),
                                        );
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                    _QuickAction(
                                      icon: Icons.file_download_outlined,
                                      label: '导入插件',
                                      onTap: _importPlugin,
                                    ),
                                    _QuickAction(
                                      icon: Icons.help_outline,
                                      label: '查看指南',
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PluginHelpPage(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 内置插件提示
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      '内置插件',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '通勤助手和文档助手已内置可用，无需额外安装。切换到「内置」标签页即可看到。',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: plugins.length,
                  itemBuilder: (context, index) {
                    return _PluginCard(
                      plugin: plugins[index],
                      onTap: () => Navigator.pop(context, plugins[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? value, String label) {
    final store = PluginStore();
    final isSelected = store.filterCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          if (isSelected) {
            store.setFilter(category: null);
          } else {
            store.setFilter(
              category: value,
              source: _getCurrentTabSource(),
            );
          }
        },
        selectedColor: Colors.teal.withValues(alpha: 0.2),
        checkmarkColor: Colors.teal,
      ),
    );
  }

  PluginSource? _getCurrentTabSource() {
    switch (_tabController.index) {
      case 1:
        return PluginSource.builtin;
      case 2:
        return PluginSource.imported;
      case 3:
        return PluginSource.created;
      default:
        return null;
    }
  }
}

// 快速操作按钮组件
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal[600], size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PluginCard extends StatelessWidget {
  final PluginManifest plugin;
  final VoidCallback onTap;

  const _PluginCard({required this.plugin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 来源标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getSourceColor(plugin.source).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                plugin.sourceLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: _getSourceColor(plugin.source),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCategoryColor(plugin.category).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                plugin.iconData,
                size: 36,
                color: _getCategoryColor(plugin.category),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                plugin.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                plugin.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'v${plugin.version}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    const map = {
      'productivity':  Colors.blue,
      'academic':      Colors.purple,
      'life':          Colors.green,
      'creative':      Colors.orange,
      'development':   Colors.indigo,
      'entertainment': Colors.pink,
      'health':        Colors.red,
      'travel':        Colors.cyan,
      'other':         Colors.grey,
    };
    return map[category] ?? Colors.grey;
  }

  Color _getSourceColor(PluginSource source) {
    const map = {
      PluginSource.builtin:  Colors.teal,
      PluginSource.imported: Colors.blue,
      PluginSource.created:  Colors.purple,
    };
    return map[source] ?? Colors.grey;
  }
}
