# APISwitcher for macOS

<div align="center">

**一键切换 Claude Code 配置的原生 macOS 应用**

支持余额查询 · 订阅管理 · 菜单栏快速切换

[功能特性](#功能特性) • [安装使用](#安装使用) • [配置说明](#配置说明) • [开发指南](#开发指南)

</div>

---

## 功能特性

- ✅ **配置管理** - 添加、编辑、删除多个 Claude Code 配置
- ✅ **一键切换** - 快速切换不同的 API 配置
- ✅ **余额查询** - 支持三种认证方式（Header、Body、Cookie）
- ✅ **订阅信息** - 查看订阅类型、到期时间、自动续费状态
- ✅ **菜单栏常驻** - 无需打开窗口即可快速切换
- ✅ **主窗口管理** - 完整的配置 CRUD 界面
- ✅ **动态 JSON** - 支持任意 Claude Code 设置属性
- ✅ **智能匹配** - 自动识别当前激活的配置

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Xcode 15.0+ (开发)
- Swift 6.0+

## 安装使用

### 方式一：源码编译（推荐）

```bash
# 克隆仓库
git clone https://github.com/yourusername/APISwitcher.git
cd APISwitcher/APISwitcher.macOS

# 使用 Xcode 打开项目
open APISwitcher.xcodeproj

# 或使用 xcodebuild 编译
xcodebuild -project APISwitcher.xcodeproj -scheme APISwitcher -configuration Release build
```

### 方式二：下载预编译版本

前往 [Releases](https://github.com/yourusername/APISwitcher/releases) 页面下载最新的 `.dmg` 安装包。

## 配置说明

### 配置文件位置

- **配置定义**: `~/Library/Application Support/APISwitcher/app_profiles.json`
- **Claude 设置**: `~/.claude/settings.json`

### 配置文件格式

```json
[
  {
    "id": "唯一ID",
    "name": "配置名称",
    "balanceApi": "https://api.example.com/balance",
    "authMode": "header",  // 认证方式: header | body | cookie
    "authKey": "Authorization",  // 认证键名
    "apiKey": "Bearer YOUR_API_KEY",  // API 密钥
    "balanceJsonPath": "$.data.balance",  // 余额 JSON 路径
    "subscriptionApi": "https://api.example.com/subscription",
    "subscriptionJsonPath": "$.data",
    "settings": {
      "claude": {
        "apiKey": "sk-ant-xxx",
        "model": "claude-sonnet-4.5",
        "baseURL": "https://custom-api.example.com/v1"  // 可选
      },
      "mcpServers": {  // 可选
        "filesystem": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
        }
      }
    }
  }
]
```

### 认证方式说明

#### Header 认证
```json
{
  "authMode": "header",
  "authKey": "Authorization",
  "apiKey": "Bearer YOUR_API_KEY"
}
```

#### Body 认证
```json
{
  "authMode": "body",
  "authKey": "api_key",
  "apiKey": "YOUR_API_KEY"
}
```

#### Cookie 认证
```json
{
  "authMode": "cookie",
  "authKey": "session",
  "apiKey": "YOUR_SESSION_ID"
}
```

### JSON Path 语法

支持简化的 JSON Path 语法，用于从 API 响应中提取数据：

- `$.balance` - 根级别的 balance 字段
- `$.data.balance` - 嵌套对象
- `$.data[0].balance` - 数组元素

## 使用指南

### 1. 添加配置

1. 点击主窗口的"添加配置"按钮
2. 填写配置名称和 Claude API Key
3. （可选）填写余额 API 和订阅 API 信息
4. 点击"保存"

### 2. 切换配置

**方式一：主窗口**
- 在配置卡片上点击"切换"按钮

**方式二：菜单栏**
- 点击菜单栏图标
- 选择要切换的配置

### 3. 查询余额

- 在配置卡片上点击"查询余额"按钮
- 或在菜单栏选择"刷新所有余额"

### 4. 编辑/删除配置

- 在配置卡片上点击"编辑"或"删除"按钮

## 开发指南

### 项目结构

```
APISwitcher/
├── App/
│   ├── APISwitcherApp.swift      # 应用入口
│   └── AppDelegate.swift         # 菜单栏管理
├── Models/
│   ├── Profile.swift             # 配置模型
│   ├── ClaudeSettings.swift      # Claude 设置模型
│   ├── BalanceInfo.swift         # 余额信息
│   └── SubscriptionInfo.swift    # 订阅信息
├── Services/
│   ├── ConfigService.swift       # 配置文件服务
│   ├── BalanceService.swift      # 余额查询服务
│   └── SubscriptionService.swift # 订阅查询服务
├── ViewModels/
│   ├── MainViewModel.swift       # 主窗口 ViewModel
│   └── ProfileFormViewModel.swift # 表单 ViewModel
├── Views/
│   ├── MainView.swift            # 主窗口
│   ├── ProfileCardView.swift     # 配置卡片
│   ├── ProfileFormView.swift     # 添加/编辑表单
│   ├── BalanceView.swift         # 余额显示
│   └── SubscriptionView.swift    # 订阅信息
└── Utilities/
    ├── AnyCodableValue.swift     # 类型擦除容器
    ├── JSONSubsetMatcher.swift   # JSON 子集匹配
    ├── PathHelper.swift          # 路径处理
    └── JSONPathExtractor.swift   # JSON Path 解析
```

### 技术架构

- **UI 框架**: SwiftUI
- **架构模式**: MVVM + Observable
- **网络请求**: URLSession
- **JSON 处理**: Codable + 自定义动态编解码
- **文件操作**: FileManager

### 核心技术点

#### 1. 动态 JSON 处理

使用 `AnyCodableValue` 枚举实现类型擦除，支持存储任意 JSON 属性：

```swift
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case dictionary([String: AnyCodableValue])
    // ...
}
```

#### 2. JSON 子集匹配

实现递归比较算法，判断配置是否为当前设置的子集：

```swift
class JSONSubsetMatcher {
    static func isSubset(_ subset: [String: Any], of superset: [String: Any]) -> Bool
}
```

#### 3. 三种认证方式

统一处理 Header、Body、Cookie 三种 API 认证方式。

### 构建与运行

```bash
# 开发模式运行
xcodebuild -project APISwitcher.xcodeproj -scheme APISwitcher -configuration Debug

# Release 构建
xcodebuild -project APISwitcher.xcodeproj -scheme APISwitcher -configuration Release clean build

# 运行单元测试
xcodebuild test -project APISwitcher.xcodeproj -scheme APISwitcher
```

## 常见问题

### Q: 为什么无法读取 ~/.claude/settings.json？

A: 确保 Claude Code 已经创建了该文件。可以先运行一次 Claude Code 来初始化配置文件。

### Q: 余额查询失败怎么办？

A: 检查以下几点：
1. API 地址是否正确
2. 认证方式和密钥是否匹配
3. JSON Path 是否正确
4. 网络连接是否正常

### Q: 如何备份配置？

A: 复制 `~/Library/Application Support/APISwitcher/app_profiles.json` 文件即可。

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 致谢

- [Claude Code](https://claude.ai/code) - Anthropic 官方 CLI 工具
- SwiftUI - Apple 的声明式 UI 框架

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️ Star 支持一下！**

</div>
