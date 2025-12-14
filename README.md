# APISwitcher

<div align="center">

一个用于快速切换 Claude Code 配置文件的跨平台桌面应用程序

[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS-0078D6)](https://github.com)

[功能特性](#功能特性) • [快速开始](#快速开始) • [使用方法](#使用方法) • [开发指南](#开发指南)

</div>

---

## 简介

APISwitcher 是一个轻量级的桌面工具，专为 [Claude Code CLI](https://www.code-cli.com/) 用户设计。它允许你在多个 API 配置之间快速切换，无需手动编辑配置文件。无论你是在官方 API 和第三方 API 之间切换，还是管理多个账号，APISwitcher 都能让这个过程变得简单高效。

> **平台支持说明**
> - **Windows 版本**：已完成开发，功能完善，推荐使用
> - **macOS 版本**：正在积极开发中，基础功能已实现，部分高级特性仍在完善

## 功能特性

- **多配置管理** - 在一个界面中管理所有 Claude Code 配置
- **一键切换** - 点击即可切换到不同的 API 配置
- **智能识别** - 自动识别并高亮显示当前激活的配置
- **余额查询** - 支持查询和显示 API 账户余额信息（可选）
- **自动同步** - 配置更改立即写入 Claude Code 设置文件
- **现代界面** - 简洁直观的 WPF 界面设计
- **轻量快速** - 启动迅速，资源占用低

## 快速开始

### 系统要求

#### Windows 版本
- Windows 10/11
- [.NET 8.0 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)

#### macOS 版本（开发中）
- macOS 14.0 (Sonoma) 或更高版本
- 不需要额外的运行时依赖

### 安装

#### Windows 版本

**方式一：下载预编译版本（推荐）**

1. 前往 [Releases](../../releases) 页面下载最新版本
2. 解压到任意目录
3. 双击运行 `APISwitcher.exe`

**方式二：从源码构建**

```bash
# 克隆仓库
git clone https://github.com/yourusername/APISwitcher.git
cd APISwitcher

# 构建项目
dotnet build APISwitcher/APISwitcher.csproj -c Release

# 运行应用
dotnet run --project APISwitcher/APISwitcher.csproj
```

#### macOS 版本（开发中）

**从源码构建**

```bash
# 克隆仓库
git clone https://github.com/yourusername/APISwitcher.git
cd APISwitcher/APISwitcher.macOS

# 构建应用
./build-app.sh

# 运行应用
open .build/APISwitcher.app
```

> **注意**：macOS 版本当前仍在开发中，可能存在未完成的功能或 Bug。

## 使用方法

### 首次配置

1. **创建配置文件（以GLM模型API为例）**

   在应用程序根目录下创建或编辑 `app_profiles.json` 文件：

   ```json
   [
     {
       "name": "Claude官方",
       "isActive": false,
       "settings": {
         "alwaysThinkingEnabled": true
       }
     },
     {
       "name": "GLM API",
       "isActive": false,
       "settings": {
         "env": {
           "ANTHROPIC_AUTH_TOKEN": "your-api-key",
           "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
           "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.6",
           "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.6",
           "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
           "API_TIMEOUT_MS": "3000000",
           "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
         },
         "alwaysThinkingEnabled": false
       }
     }
   ]
   ```

2. **启动应用**

   运行 `APISwitcher.exe`，应用会自动加载配置文件。

3. **切换配置**

   点击任意配置卡片即可切换到该配置。当前激活的配置会以绿色边框和背景显示。

### 配置项说明

#### 基础配置

- `name`: 配置文件的显示名称
- `isActive`: 是否为当前激活的配置（由程序自动管理）
- `settings`: Claude Code 的配置内容
  - `env`: 环境变量配置
    - `ANTHROPIC_AUTH_TOKEN`: API 认证令牌
    - `ANTHROPIC_BASE_URL`: API 基础 URL
    - `ANTHROPIC_DEFAULT_OPUS_MODEL`: Opus 模型名称
    - `ANTHROPIC_DEFAULT_SONNET_MODEL`: Sonnet 模型名称
    - `ANTHROPIC_DEFAULT_HAIKU_MODEL`: Haiku 模型名称
    - `API_TIMEOUT_MS`: API 超时时间（毫秒）
    - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`: 禁用非必要流量
  - `alwaysThinkingEnabled`: 是否启用持续思考模式

#### 余额查询配置（可选）

`balanceApi` 对象用于配置余额查询功能。**注意：这些配置需要通过浏览器开发者工具抓包获取。**

**如何获取 balanceApi 配置：**
1. 打开 API 提供商的网页控制台
2. 按 F12 打开浏览器开发者工具
3. 切换到 Network（网络）标签
4. 在网页上查看余额信息
5. 在 Network 标签中找到对应的 API 请求
6. 查看请求的 URL、Method、Headers 和 Response 数据结构
7. 根据抓包信息填写以下配置

**配置项说明：**

- `endpoint`: API 端点路径（例如：`/api/user/self`）
- `method`: HTTP 请求方法（`GET` 或 `POST`）
- `authType`: 认证方式
  - `body`: 使用 API Token 在请求体中认证
  - `cookie`: 使用 Cookie 认证
- `timeout`: 请求超时时间（毫秒），默认 5000
- `displayUnit`: 余额显示单位
  - `usd`: 美元
  - `times`: 次数
  - `cny`: 人民币

**字段映射配置（根据 API 响应结构选择）：**

- `balanceField`: 余额字段路径（用于直接返回余额的 API）
  - 例如：`data.quota` 表示从响应的 `data.quota` 字段读取余额
- `limitField`: 总额度字段路径（用于返回已用/总额的 API）
- `usedField`: 已使用字段路径（用于返回已用/总额的 API）
- `divisor`: 除数，用于单位转换（例如：API 返回的是分，设置为 100 转换为元）

**Body 认证示例：**

```json
{
  "name": "示例配置",
  "settings": { ... },
  "balanceApi": {
    "endpoint": "/api/token/query",
    "method": "POST",
    "authType": "body",
    "limitField": "data.total_usage_limit",
    "usedField": "data.total_usage_count",
    "displayUnit": "times",
    "timeout": 5000
  }
}
```

**Cookie 认证示例：**

```json
{
  "name": "示例配置",
  "settings": { ... },
  "balanceApi": {
    "endpoint": "/api/user/self",
    "method": "GET",
    "authType": "cookie",
    "balanceField": "data.quota",
    "displayUnit": "usd",
    "divisor": 500000,
    "timeout": 5000,
    "sessionCookie": "session=your-session-cookie-value",
    "extraHeaders": {
      "accept": "application/json, text/plain, */*",
      "origin": "https://example.com",
      "referer": "https://example.com/console",
      "user-agent": "Mozilla/5.0"
    }
  }
}
```

**特殊说明：**
- Cookie 认证需要提供 `sessionCookie` 和 `extraHeaders`
- `sessionCookie` 可以从浏览器开发者工具的 Application → Cookies 中获取
- `extraHeaders` 需要从抓包的请求头中复制，确保包含必要的认证信息
- 字段路径使用点号分隔，例如 `data.user.balance` 表示访问 `response.data.user.balance`

## 工作原理

APISwitcher 通过以下方式实现配置切换：

1. 读取应用程序目录下的 `app_profiles.json` 文件
2. 读取用户目录下的 `~/.claude/settings.json` 文件
3. 智能比对配置内容，自动识别当前激活的配置
4. 切换时将选中的配置写入 `~/.claude/settings.json`

> **注意**：切换配置后需要重启 Claude Code 才能使新配置生效。

## 开发指南

### 技术栈

#### Windows 版本
- **框架**: .NET 8.0 + WPF
- **架构模式**: MVVM (使用 CommunityToolkit.Mvvm)
- **依赖注入**: Microsoft.Extensions.DependencyInjection
- **数据绑定**: 双向绑定 + 命令模式

#### macOS 版本
- **语言**: Swift 6.0
- **框架**: SwiftUI
- **架构模式**: MVVM (使用 @Observable)
- **构建系统**: Swift Package Manager

### 项目结构

#### Windows 版本 (APISwitcher/)
```
APISwitcher/
├── Models/              # 数据模型
│   ├── Profile.cs       # 配置文件模型
│   └── ClaudeSettings.cs # Claude 设置模型
├── ViewModels/          # 视图模型
│   └── MainViewModel.cs # 主窗口视图模型
├── Services/            # 服务层
│   └── ConfigService.cs # 配置管理服务
├── Converters/          # 值转换器
├── MainWindow.xaml      # 主窗口界面
├── App.xaml             # 应用程序入口
└── app_profiles.json    # 配置文件存储
```

#### macOS 版本 (APISwitcher.macOS/)
```
APISwitcher.macOS/
├── APISwitcher/
│   ├── App/             # 应用入口
│   │   └── APISwitcherApp.swift
│   ├── Models/          # 数据模型
│   │   ├── Profile.swift
│   │   └── ClaudeSettings.swift
│   ├── ViewModels/      # 视图模型
│   │   └── MainViewModel.swift
│   ├── Views/           # 视图
│   │   ├── MainView.swift
│   │   └── ProfileCardView.swift
│   ├── Services/        # 服务层
│   │   └── ConfigService.swift
│   └── Resources/       # 资源文件
│       └── AppIcon.icns
└── build-app.sh         # 构建脚本
```

### 本地开发

#### Windows 版本

```bash
# 克隆仓库
git clone https://github.com/yourusername/APISwitcher.git
cd APISwitcher

# 还原依赖
dotnet restore APISwitcher/APISwitcher.csproj

# 构建项目
dotnet build APISwitcher/APISwitcher.csproj

# 运行应用
dotnet run --project APISwitcher/APISwitcher.csproj

# 发布应用
dotnet publish APISwitcher/APISwitcher.csproj -c Release
```

#### macOS 版本

```bash
# 克隆仓库
git clone https://github.com/yourusername/APISwitcher.git
cd APISwitcher/APISwitcher.macOS

# 构建项目（Release 模式）
swift build -c release

# 或使用构建脚本生成 .app 包
./build-app.sh

# 运行应用
open .build/APISwitcher.app
```

### 调试

#### Windows
- **Visual Studio**: 打开 `APISwitcher.slnx`，按 F5 开始调试
- **VS Code**: 使用 C# Dev Kit 扩展打开项目文件夹

#### macOS
- **Xcode**: 使用 `swift package generate-xcodeproj` 生成项目文件
- **VS Code**: 使用 Swift 扩展打开 `APISwitcher.macOS` 文件夹

## 常见问题

<details>
<summary><b>Q: macOS 版本开发进度如何？</b></summary>

A: macOS 版本当前正在开发中，已实现的功能包括：
- 配置文件加载和切换
- 主窗口 UI 和菜单栏集成
- 配置激活状态检测
- 与 Windows 版本一致的 UI 布局
- 余额查询功能（部分完成）
- 订阅信息显示（部分完成）
- 配置增删改功能（开发中）
</details>

<details>
<summary><b>Q: 切换配置后没有生效？</b></summary>

A: 请确保已重启 Claude Code 应用程序。配置更改需要重启才能生效。
</details>

<details>
<summary><b>Q: 找不到配置文件？</b></summary>

A: 确保 `app_profiles.json` 文件位于应用程序根目录下。首次运行时可能需要手动创建此文件。
</details>

<details>
<summary><b>Q: 配置切换失败？</b></summary>

A: 检查以下几点：
- 是否有足够的权限写入 `~/.claude/settings.json` 文件
- `app_profiles.json` 格式是否正确
- Claude Code 是否已正确安装
</details>

<details>
<summary><b>Q: 支持哪些配置项？</b></summary>

A: APISwitcher 支持 Claude Code 的所有配置项。你可以在 `settings` 对象中添加任何 Claude Code 支持的配置。
</details>

<details>
<summary><b>Q: 如何配置余额查询功能？</b></summary>

A: 余额查询功能是可选的，需要通过浏览器抓包获取 API 配置信息：
1. 打开 API 提供商的网页控制台
2. 按 F12 打开开发者工具，切换到 Network 标签
3. 在网页上查看余额，找到对应的 API 请求
4. 根据请求信息配置 `balanceApi` 对象（详见配置项说明）
</details>

<details>
<summary><b>Q: 余额查询显示错误或无限额度？</b></summary>

A: 可能的原因：
- Cookie 认证的 `sessionCookie` 已过期，需要重新抓包获取
- API 端点或字段路径配置错误，检查抓包信息
- API 返回 -1 或特殊值表示无限额度（这是正常的）
- 网络连接问题或 API 服务不可用
</details>

## 安全提示

- 不要将包含 API 密钥的 `app_profiles.json` 提交到公共仓库
- 建议将 `app_profiles.json` 添加到 `.gitignore`
- 妥善保管你的 API 密钥和认证令牌
- 定期备份你的配置文件

## License

MIT
