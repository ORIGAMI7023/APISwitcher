# CLAUDE.md

本项目包含两个平台的实现，共享相同的配置文件结构。

## 构建命令

### Windows (WPF / .NET)
```bash
dotnet restore APISwitcher/APISwitcher.csproj
dotnet build APISwitcher/APISwitcher.csproj          # Debug
dotnet build APISwitcher/APISwitcher.csproj -c Release  # Release
dotnet run --project APISwitcher/APISwitcher.csproj
```

### macOS (Swift / SwiftUI)
```bash
cd APISwitcher.macOS
swift build          # Debug
swift build -c release  # Release
```
**注意**：修改 macOS 版本代码后，需要重新构建并将产物部署到 app 包：
```bash
swift build -c release
cp .build/release/APISwitcher .build/APISwitcher.app/Contents/MacOS/APISwitcher
```

## 项目结构

```
APISwitcher/                    # Windows WPF 版本
├── Models/                     # 数据模型
│   ├── Profile.cs              # 配置档案
│   ├── ClaudeSettings.cs       # Claude 设置（使用 JsonExtensionData 动态属性）
│   ├── BalanceInfo.cs          # 余额信息
│   └── SubscriptionInfo.cs     # 订阅信息
├── ViewModels/
│   └── MainViewModel.cs        # 主 ViewModel（CommunityToolkit.Mvvm）
├── Services/
│   ├── ConfigService.cs        # 配置读写、激活状态判断
│   ├── BalanceService.cs       # 余额查询
│   └── SubscriptionService.cs  # 订阅查询
├── Converters/                 # WPF 值转换器
├── MainWindow.xaml             # 主窗口 UI
└── app_profiles.json           # 配置定义文件

APISwitcher.macOS/              # macOS SwiftUI 版本
├── APISwitcher/
│   ├── Models/                 # 数据模型
│   ├── ViewModels/             # MainViewModel + ProfileFormViewModel
│   ├── Views/                  # MainView, ProfileCardView, ProfileFormView
│   ├── Services/
│   │   ├── ConfigService.swift     # 配置读写
│   │   └── StatusBarController.swift # 菜单栏控制器
│   ├── Utilities/              # JSON 工具类
│   └── App/                    # AppDelegate + 入口
└── Package.swift
```

## 架构要点

两个版本都采用 MVVM 模式，核心逻辑一致：

- **配置管理**：`ConfigService` 读写两个 JSON 文件
  - `app_profiles.json`（应用目录）：所有配置档案
  - `~/.claude/settings.json`（用户目录）：Claude Code 当前激活配置
- **激活检测**：通过 `IsJsonSubset` 递归比较，判断哪个配置是当前生效的
- **动态属性**：`ClaudeSettings` 使用 `[JsonExtensionData]` / `AnyCodableValue` 捕获任意 JSON 属性
- **macOS 菜单栏**：`StatusBarController` 提供菜单栏快捷切换，与主窗口共享同一个 `MainViewModel`

## 功能一览

- 配置切换（点击卡片 / 菜单栏选择）
- 添加、编辑、删除配置
- 打开配置文件（`app_profiles.json`）/ 打开设置文件（`settings.json`）
- 余额查询（部分配置支持）
- 订阅信息展示（月卡配额、到期时间）

## 修改 UI 的指引

- **Windows**：编辑 `MainWindow.xaml`，绑定到 MainViewModel 的属性和命令
- **macOS**：编辑 `Views/` 下的 SwiftUI 视图，MainViewModel 使用 `@Observable` 宏
- 添加新命令时：Windows 用 `[RelayCommand]` 自动生成；macOS 直接在 ViewModel 添加方法即可
