# 插件示例模板

本目录包含插件 manifest.json 的示例文件，可供参考或直接导入使用。

## 文件说明

| 文件 | 插件名称 | 分类 | 用途 |
|------|----------|------|------|
| `recipe_assistant_manifest.json` | 食谱助手 | 生活 | 展示生活类插件的编写方式 |
| `academic_writer_manifest.json` | 学术写作助手 | 学术 | 展示学术类插件的编写方式 |
| `developer_helper_manifest.json` | 开发助手 | 开发 | 展示开发类插件的编写方式 |

## 使用方法

1. 打开智能助理 App
2. 进入「插件市场」
3. 点击右上角「导入」按钮
4. 选择本目录下的 JSON 文件导入

## 快速创建自己的插件

1. 复制一个示例文件
2. 修改以下必填字段：
   - `id`: 唯一标识，如 `my-awesome-plugin`
   - `name`: 插件显示名称
   - `version`: 版本号，如 `1.0.0`
   - `description`: 简短描述（50字以内）
3. 修改 `system_prompt` 定义插件能力
4. 在插件市场中导入

## 字段参考

### 必填字段
- `id`: 唯一标识符，建议使用 kebab-case
- `name`: 插件显示名称
- `version`: 版本号，遵循 semver 规范
- `description`: 简短描述

### 重要字段
- `system_prompt`: **最关键**，定义 AI 的角色和能力
- `category`: 分类，影响展示位置
- `tags`: 标签数组，用于搜索

### 可选字段
- `author`: 作者名称
- `detailed_description`: 详细说明
- `icon`: 图标名称
- `content.welcome_message`: 欢迎语

### 图标名称对照
- `extension`: 通用插件
- `directions_car`: 交通/出行
- `school`: 学术/教育
- `description`: 文档/写作
- `code`: 开发/编程
- `restaurant`: 美食/餐饮
- `travel_explore`: 旅行
- `psychology`: 心理/咨询
- `science`: 科学
- `calculate`: 计算/财务

### 分类对照
- `productivity`: 效率
- `academic`: 学术
- `life`: 生活
- `creative`: 创意
- `development`: 开发
- `health`: 健康
- `travel`: 旅行
- `other`: 其他
