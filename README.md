# APISwitcher

<div align="center">

一个用于快速切换 Claude Code 配置文件的 Windows 桌面应用程序

[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D6?logo=windows)](https://www.microsoft.com/windows)

[功能特性](#功能特性) • [快速开始](#快速开始) • [使用方法](#使用方法) • [开发指南](#开发指南) • [贡献](#贡献)

</div>

---

## 📖 简介

APISwitcher 是一个轻量级的桌面工具，专为 [Claude Code CLI](https://www.code-cli.com/) 用户设计。它允许你在多个 API 配置之间快速切换，无需手动编辑配置文件。无论你是在官方 API 和第三方 API 之间切换，还是管理多个账号，APISwitcher 都能让这个过程变得简单高效。

## ✨ 功能特性

- 📋 **多配置管理** - 在一个界面中管理所有 Claude Code 配置
- 🔄 **一键切换** - 点击即可切换到不同的 API 配置
- 🎯 **智能识别** - 自动识别并高亮显示当前激活的配置
- 💾 **自动同步** - 配置更改立即写入 Claude Code 设置文件
- 🎨 **现代界面** - 简洁直观的 WPF 界面设计
- ⚡ **轻量快速** - 启动迅速，资源占用低

## 🚀 快速开始

### 系统要求

- Windows 10/11
- [.NET 8.0 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)

### 安装

#### 方式一：下载预编译版本（推荐）

1. 前往 [Releases](../../releases) 页面下载最新版本
2. 解压到任意目录
3. 双击运行 `APISwitcher.exe`

#### 方式二：从源码构建

```bash
# 克隆仓库
git clone https://github.com/yourusername/APISwitcher.git
cd APISwitcher

# 构建项目
dotnet build APISwitcher/APISwitcher.csproj -c Release

# 运行应用
dotnet run --project APISwitcher/APISwitcher.csproj
```

## 📚 使用方法

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

## 🔧 工作原理

APISwitcher 通过以下方式实现配置切换：

1. 📂 读取应用程序目录下的 `app_profiles.json` 文件
2. 📄 读取用户目录下的 `~/.claude/settings.json` 文件
3. 🔍 智能比对配置内容，自动识别当前激活的配置
4. ✍️ 切换时将选中的配置写入 `~/.claude/settings.json`

> **注意**：切换配置后需要重启 Claude Code 才能使新配置生效。

## 🛠️ 开发指南

### 技术栈

- **框架**: .NET 8.0 + WPF
- **架构模式**: MVVM (使用 CommunityToolkit.Mvvm)
- **依赖注入**: Microsoft.Extensions.DependencyInjection
- **数据绑定**: 双向绑定 + 命令模式

### 项目结构

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

### 本地开发

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

### 调试

- **Visual Studio**: 打开 `APISwitcher.slnx`，按 F5 开始调试
- **VS Code**: 使用 C# Dev Kit 扩展打开项目文件夹

## 🤝 贡献

欢迎各种形式的贡献！

### 如何贡献

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

### 贡献指南

- 遵循现有的代码风格和架构模式
- 为新功能添加适当的注释
- 确保代码能够正常构建和运行
- 在 PR 中清晰描述你的更改

## ❓ 常见问题

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

## 🔒 安全提示

- ⚠️ **不要**将包含 API 密钥的 `app_profiles.json` 提交到公共仓库
- 📝 建议将 `app_profiles.json` 添加到 `.gitignore`
- 🔐 妥善保管你的 API 密钥和认证令牌
- 💾 定期备份你的配置文件

## 📮 联系方式

如有问题或建议，欢迎：
- 提交 [Issue](../../issues)
- 发起 [Discussion](../../discussions)
- 提交 Pull Request

---

<div align="center">

**如果这个项目对你有帮助，请给它一个 ⭐️**

Made with ❤️ for Claude Code users

</div>
