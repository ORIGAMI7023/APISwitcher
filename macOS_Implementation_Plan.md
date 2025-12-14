# APISwitcher macOS Swift 版本实现计划

## 一、项目概述

### 目标
在 `APISwitcher.macOS` 目录中创建 Swift 原生应用，实现与 Windows WPF 版本相同的功能。

### 技术栈
- **语言**: Swift 6.0+
- **UI框架**: SwiftUI
- **最低系统要求**: macOS 14.0 (Sonoma)
- **架构模式**: MVVM + Observable
- **网络**: URLSession
- **文件操作**: FileManager
- **构建工具**: Xcode 15+

### 核心功能
1. 配置文件管理（增删改查）
2. 一键切换 Claude Code 配置
3. API 余额查询（支持三种认证方式）
4. 订阅信息查询
5. 菜单栏快速切换（Menu Bar App）
6. 主窗口完整管理界面

---

## 二、项目结构

```
APISwitcher.macOS/
├── APISwitcher.xcodeproj/          # Xcode 项目文件
├── APISwitcher/
│   ├── App/
│   │   ├── APISwitcherApp.swift   # App入口
│   │   └── AppDelegate.swift      # 菜单栏管理
│   ├── Models/
│   │   ├── Profile.swift          # 配置模型
│   │   ├── ClaudeSettings.swift   # Claude设置模型
│   │   ├── BalanceInfo.swift      # 余额信息
│   │   └── SubscriptionInfo.swift # 订阅信息
│   ├── Services/
│   │   ├── ConfigService.swift    # 配置文件服务
│   │   ├── BalanceService.swift   # 余额查询服务
│   │   └── SubscriptionService.swift # 订阅查询服务
│   ├── ViewModels/
│   │   ├── MainViewModel.swift    # 主窗口ViewModel
│   │   └── ProfileFormViewModel.swift # 表单ViewModel
│   ├── Views/
│   │   ├── MainView.swift         # 主窗口
│   │   ├── ProfileCardView.swift  # 配置卡片
│   │   ├── ProfileFormView.swift  # 添加/编辑表单
│   │   ├── BalanceView.swift      # 余额显示
│   │   └── SubscriptionView.swift # 订阅信息面板
│   ├── Utilities/
│   │   ├── JSONSubsetMatcher.swift # JSON子集匹配
│   │   └── PathHelper.swift       # 路径处理
│   ├── Resources/
│   │   ├── Assets.xcassets/       # 图标资源
│   │   └── app_profiles.example.json
│   └── Info.plist
├── app_profiles.json              # 实际配置文件（.gitignore）
├── .gitignore
└── README.md
```

---

## 三、核心技术方案

### 3.1 动态 JSON 处理

**问题**: C# 使用 `[JsonExtensionData]` 动态存储任意 JSON 属性，Swift 需要类似机制。

**解决方案**: 自定义 `Codable` 实现

```swift
struct ClaudeSettings: Codable {
    var claude: ClaudeConfig?
    var mcpServers: [String: MCPServer]?

    // 动态存储其他属性
    private var additionalProperties: [String: AnyCodableValue] = [:]

    // 自定义编解码
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        // 解析已知属性 + 动态属性
    }

    func encode(to encoder: Encoder) throws {
        // 编码已知属性 + 动态属性
    }
}

// 类型擦除容器
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null
}
```

### 3.2 JSON 子集匹配算法

**目标**: 递归比较两个 JSON，判断 profile 是否为 settings 的子集。

**实现**: `JSONSubsetMatcher.swift`

```swift
class JSONSubsetMatcher {
    static func isSubset(_ subset: [String: Any], of superset: [String: Any]) -> Bool {
        for (key, subValue) in subset {
            guard let superValue = superset[key] else { return false }

            if !valuesMatch(subValue, superValue) {
                return false
            }
        }
        return true
    }

    private static func valuesMatch(_ v1: Any, _ v2: Any) -> Bool {
        switch (v1, v2) {
        case let (d1 as [String: Any], d2 as [String: Any]):
            return isSubset(d1, of: d2)
        case let (a1 as [Any], a2 as [Any]):
            return arraysEqual(a1, a2)
        case let (s1 as String, s2 as String):
            return s1 == s2
        // ... 其他类型
        }
    }
}
```

### 3.3 HTTP 请求（三种认证方式）

**需求**: 支持 Header、Body、Cookie 三种认证方式。

**实现**: `BalanceService.swift` 和 `SubscriptionService.swift`

```swift
func queryBalance(config: Profile) async throws -> BalanceInfo {
    var request = URLRequest(url: URL(string: config.balanceApi)!)
    request.httpMethod = "GET"

    switch config.authMode {
    case "header":
        request.setValue(config.apiKey, forHTTPHeaderField: config.authKey)
    case "body":
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([config.authKey: config.apiKey])
    case "cookie":
        let cookie = HTTPCookie(properties: [
            .domain: extractDomain(from: config.balanceApi),
            .path: "/",
            .name: config.authKey,
            .value: config.apiKey
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
    default:
        break
    }

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(BalanceInfo.self, from: data)
}
```

### 3.4 配置文件管理

**文件位置**:
- Profile 定义: `app_profiles.json` (bundle 或应用目录)
- Claude 设置: `~/.claude/settings.json`

**服务**: `ConfigService.swift`

```swift
class ConfigService {
    private let profilesPath: URL
    private let claudeSettingsPath: URL

    init() {
        // 优先使用应用目录的 app_profiles.json
        if let appDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            profilesPath = appDir.appendingPathComponent("app_profiles.json")
        }

        claudeSettingsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    func loadProfiles() throws -> [Profile] {
        let data = try Data(contentsOf: profilesPath)
        return try JSONDecoder().decode([Profile].self, from: data)
    }

    func saveProfiles(_ profiles: [Profile]) throws {
        let data = try JSONEncoder().encode(profiles)
        try data.write(to: profilesPath)
    }

    func switchProfile(_ profile: Profile) throws {
        let data = try JSONEncoder().encode(profile.settings)
        try data.write(to: claudeSettingsPath)
    }

    func markActiveProfile(_ profiles: [Profile]) -> [Profile] {
        guard let currentSettings = try? loadClaudeSettings() else {
            return profiles
        }

        return profiles.map { profile in
            var updatedProfile = profile
            updatedProfile.isActive = JSONSubsetMatcher.isSubset(
                profile.settings.toDictionary(),
                of: currentSettings.toDictionary()
            )
            return updatedProfile
        }
    }
}
```

---

## 四、UI 实现

### 4.1 双界面模式

**菜单栏模式**:
- 常驻菜单栏图标
- 下拉菜单显示配置列表
- 点击直接切换（无需打开窗口）

**主窗口模式**:
- 完整的 CRUD 界面
- 余额/订阅信息查询
- 配置编辑表单

### 4.2 主窗口布局 (MainView.swift)

```swift
struct MainView: View {
    @State private var viewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Text("API Switcher")
                    .font(.title2.bold())
                Spacer()
                Button("刷新", action: viewModel.refresh)
                Button("添加配置", action: viewModel.showAddForm)
            }
            .padding()

            Divider()

            // 配置卡片列表
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                    ForEach(viewModel.profiles) { profile in
                        ProfileCardView(profile: profile, viewModel: viewModel)
                    }
                }
                .padding()
            }

            Divider()

            // 状态栏
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Text(viewModel.statusMessage)
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal)
            .frame(height: 30)
        }
        .sheet(isPresented: $viewModel.showingForm) {
            ProfileFormView(viewModel: viewModel.formViewModel)
        }
        .task {
            await viewModel.initialize()
        }
    }
}
```

### 4.3 配置卡片 (ProfileCardView.swift)

```swift
struct ProfileCardView: View {
    let profile: Profile
    @Bindable var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部：名称 + 切换按钮
            HStack {
                Text(profile.name)
                    .font(.headline)
                Spacer()
                if profile.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                Button("切换") {
                    Task { await viewModel.switchProfile(profile) }
                }
                .disabled(profile.isActive)
            }

            // 余额显示
            if let balance = profile.balanceInfo {
                BalanceView(balance: balance)
            } else if !profile.balanceApi.isEmpty {
                Button("查询余额") {
                    Task { await viewModel.queryBalance(for: profile) }
                }
            }

            // 订阅信息（可折叠）
            if let subscription = profile.subscriptionInfo {
                DisclosureGroup("订阅信息") {
                    SubscriptionView(subscription: subscription)
                }
            }

            // 操作按钮
            HStack {
                Button("编辑") {
                    viewModel.editProfile(profile)
                }
                Button("删除", role: .destructive) {
                    viewModel.deleteProfile(profile)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(profile.isActive ? Color.green.opacity(0.1) : Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(profile.isActive ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}
```

### 4.4 菜单栏集成 (AppDelegate.swift)

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var viewModel: MainViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.triangle.swap", accessibilityDescription: "API Switcher")
        }

        viewModel = MainViewModel()
        Task {
            await viewModel.initialize()
            updateMenu()
        }
    }

    private func updateMenu() {
        let menu = NSMenu()

        // 添加配置选项
        for profile in viewModel.profiles {
            let item = NSMenuItem(
                title: profile.name,
                action: #selector(switchProfile(_:)),
                keyEquivalent: ""
            )
            item.representedObject = profile
            item.state = profile.isActive ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "打开主窗口", action: #selector(openMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "刷新", action: #selector(refresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func switchProfile(_ sender: NSMenuItem) {
        guard let profile = sender.representedObject as? Profile else { return }
        Task {
            await viewModel.switchProfile(profile)
            updateMenu()
        }
    }

    @objc func openMainWindow() {
        // 显示主窗口
    }

    @objc func refresh() {
        Task {
            await viewModel.refresh()
            updateMenu()
        }
    }
}
```

### 4.5 动画效果

**订阅面板展开/折叠**:
```swift
DisclosureGroup {
    SubscriptionView(subscription: subscription)
        .transition(.scale.combined(with: .opacity))
} label: {
    Text("订阅信息")
}
.animation(.easeInOut(duration: 0.3), value: isExpanded)
```

**卡片切换效果**:
```swift
.scaleEffect(profile.isActive ? 1.02 : 1.0)
.animation(.spring(response: 0.3), value: profile.isActive)
```

---

## 五、数据模型定义

### Profile.swift
```swift
struct Profile: Identifiable, Codable {
    let id: UUID
    var name: String
    var balanceApi: String
    var authMode: String        // "header" | "body" | "cookie"
    var authKey: String
    var apiKey: String
    var balanceJsonPath: String
    var subscriptionApi: String
    var subscriptionJsonPath: String
    var settings: ClaudeSettings

    // 运行时状态（不编码）
    var isActive: Bool = false
    var balanceInfo: BalanceInfo?
    var subscriptionInfo: SubscriptionInfo?

    enum CodingKeys: String, CodingKey {
        case id, name, balanceApi, authMode, authKey, apiKey
        case balanceJsonPath, subscriptionApi, subscriptionJsonPath, settings
    }
}
```

### ClaudeSettings.swift
```swift
struct ClaudeSettings: Codable {
    var claude: ClaudeConfig?
    var mcpServers: [String: MCPServer]?

    struct ClaudeConfig: Codable {
        var apiKey: String?
        var model: String?
        // ... 其他属性
    }

    struct MCPServer: Codable {
        var command: String
        var args: [String]?
        var env: [String: String]?
    }

    // 动态属性容器
    private var extraData: [String: AnyCodableValue] = [:]

    // 转换为字典（用于 JSON 比较）
    func toDictionary() -> [String: Any] {
        // 实现序列化逻辑
    }
}
```

### BalanceInfo.swift
```swift
struct BalanceInfo: Codable {
    let balance: Double
    let currency: String?
    let lastUpdated: Date

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: NSNumber(value: balance)) ?? "\(balance)"
    }
}
```

### SubscriptionInfo.swift
```swift
struct SubscriptionInfo: Codable {
    let planType: String
    let startDate: Date?
    let endDate: Date?
    let autoRenew: Bool?

    var isActive: Bool {
        guard let endDate = endDate else { return true }
        return endDate > Date()
    }
}
```

---

## 六、ViewModel 实现

### MainViewModel.swift
```swift
@Observable
class MainViewModel {
    var profiles: [Profile] = []
    var isLoading = false
    var statusMessage = "就绪"
    var showingForm = false
    var formViewModel: ProfileFormViewModel?

    private let configService = ConfigService()
    private let balanceService = BalanceService()
    private let subscriptionService = SubscriptionService()

    func initialize() async {
        await loadProfiles()
    }

    func loadProfiles() async {
        isLoading = true
        statusMessage = "加载配置..."

        do {
            var loadedProfiles = try configService.loadProfiles()
            loadedProfiles = configService.markActiveProfile(loadedProfiles)

            await MainActor.run {
                profiles = loadedProfiles
                statusMessage = "加载完成"
                isLoading = false
            }
        } catch {
            await MainActor.run {
                statusMessage = "加载失败: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func switchProfile(_ profile: Profile) async {
        guard !profile.isActive else { return }

        statusMessage = "正在切换到 \(profile.name)..."

        do {
            try configService.switchProfile(profile)
            await loadProfiles()
            statusMessage = "已切换到 \(profile.name)"
        } catch {
            statusMessage = "切换失败: \(error.localizedDescription)"
        }
    }

    func queryBalance(for profile: Profile) async {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        do {
            let balance = try await balanceService.queryBalance(config: profile)
            await MainActor.run {
                profiles[index].balanceInfo = balance
                statusMessage = "余额查询成功"
            }
        } catch {
            statusMessage = "余额查询失败: \(error.localizedDescription)"
        }
    }

    func addProfile(_ profile: Profile) {
        profiles.append(profile)
        saveProfiles()
    }

    func deleteProfile(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()
    }

    func editProfile(_ profile: Profile) {
        formViewModel = ProfileFormViewModel(profile: profile, delegate: self)
        showingForm = true
    }

    func showAddForm() {
        formViewModel = ProfileFormViewModel(delegate: self)
        showingForm = true
    }

    private func saveProfiles() {
        do {
            try configService.saveProfiles(profiles)
            statusMessage = "保存成功"
        } catch {
            statusMessage = "保存失败: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        await loadProfiles()
    }
}
```

---

## 七、配置文件处理

### .gitignore
```
# Xcode
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
DerivedData/
build/

# Swift Package Manager
.swiftpm/
Packages/
*.xcodeproj

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Configuration files
app_profiles.json
```

### app_profiles.example.json
```json
[
  {
    "id": "00000000-0000-0000-0000-000000000001",
    "name": "示例配置",
    "balanceApi": "https://api.example.com/balance",
    "authMode": "header",
    "authKey": "Authorization",
    "apiKey": "Bearer YOUR_API_KEY",
    "balanceJsonPath": "$.data.balance",
    "subscriptionApi": "https://api.example.com/subscription",
    "subscriptionJsonPath": "$.data",
    "settings": {
      "claude": {
        "apiKey": "sk-ant-xxx",
        "model": "claude-sonnet-4.5"
      }
    }
  }
]
```

---

## 八、实施步骤

### 阶段 1: 基础架构 (1-2天)
1. ✅ 创建 Xcode 项目
2. ✅ 建立目录结构
3. ✅ 实现数据模型 (Profile, ClaudeSettings, etc.)
4. ✅ 实现 `AnyCodableValue` 类型擦除容器
5. ✅ 实现 `JSONSubsetMatcher` 工具类

### 阶段 2: 核心服务 (2-3天)
1. ✅ 实现 `ConfigService`
   - 读写 app_profiles.json
   - 读写 ~/.claude/settings.json
   - 激活配置标记逻辑
2. ✅ 实现 `BalanceService`
   - 支持三种认证方式
   - JSON Path 解析
3. ✅ 实现 `SubscriptionService`

### 阶段 3: UI 实现 (3-4天)
1. ✅ 实现 `MainViewModel`
2. ✅ 实现主窗口 `MainView`
3. ✅ 实现配置卡片 `ProfileCardView`
4. ✅ 实现表单视图 `ProfileFormView`
5. ✅ 实现余额/订阅视图

### 阶段 4: 菜单栏集成 (1-2天)
1. ✅ 实现 `AppDelegate` 菜单栏逻辑
2. ✅ 实现快速切换功能
3. ✅ 实现菜单与主窗口联动

### 阶段 5: 打磨与测试 (2-3天)
1. ✅ 添加动画效果
2. ✅ 错误处理优化
3. ✅ 边缘情况测试（~/.claude 不存在等）
4. ✅ 性能优化
5. ✅ 编写 README 文档

---

## 九、技术难点与解决方案

### 难点 1: 动态 JSON 属性
**问题**: Swift 类型系统严格，难以像 C# 那样动态存储任意 JSON。

**方案**:
- 使用 `AnyCodableValue` 枚举实现类型擦除
- 自定义 `Codable` 的 `init(from:)` 和 `encode(to:)` 方法
- 使用 `DynamicCodingKeys` 处理未知键

### 难点 2: JSON 子集匹配
**问题**: 递归比较复杂嵌套 JSON 结构。

**方案**:
- 实现 `JSONSubsetMatcher` 工具类
- 递归处理字典、数组、基本类型
- 考虑类型转换（Int ↔ Double）

### 难点 3: 菜单栏与主窗口同步
**问题**: 两个界面共享同一状态。

**方案**:
- 使用单例 `MainViewModel`
- `@Observable` 自动同步状态
- 菜单栏操作后通知主窗口刷新

### 难点 4: 文件权限
**问题**: macOS 沙盒可能限制文件访问。

**方案**:
- 开源项目可不启用沙盒
- 添加 Info.plist 权限声明
- 提供手动选择文件的备用方案

---

## 十、开源发布检查清单

- [ ] 完善 README（安装、使用、配置说明）
- [ ] 添加 LICENSE 文件（建议 MIT）
- [ ] 编写 CONTRIBUTING.md
- [ ] 提供 app_profiles.example.json 模板
- [ ] 添加 GitHub Actions CI（可选）
- [ ] 录制使用演示视频/GIF
- [ ] 多语言支持（中英文）
- [ ] 应用图标设计

---

## 附录：关键代码示例

### A. JSON Path 解析
```swift
import Foundation

func extractValue(from json: [String: Any], path: String) -> Any? {
    // 简化实现，支持 "$.data.balance" 格式
    let components = path.replacingOccurrences(of: "$.", with: "").split(separator: ".")
    var current: Any = json

    for key in components {
        if let dict = current as? [String: Any] {
            current = dict[String(key)] ?? NSNull()
        } else {
            return nil
        }
    }
    return current
}
```

### B. 并发任务管理
```swift
// 同时查询所有配置的余额
func refreshAllBalances() async {
    await withTaskGroup(of: (UUID, Result<BalanceInfo, Error>).self) { group in
        for profile in profiles where !profile.balanceApi.isEmpty {
            group.addTask {
                let result = await Result {
                    try await self.balanceService.queryBalance(config: profile)
                }
                return (profile.id, result)
            }
        }

        for await (id, result) in group {
            if let index = profiles.firstIndex(where: { $0.id == id }) {
                switch result {
                case .success(let balance):
                    profiles[index].balanceInfo = balance
                case .failure:
                    break
                }
            }
        }
    }
}
```

---

## 总结

本计划详细描述了 macOS Swift 版本的 APISwitcher 实现方案，涵盖了：

1. **完整的技术栈选择**（Swift 6.0, SwiftUI, macOS 14+）
2. **清晰的项目结构**（MVVM 架构）
3. **关键技术难点的解决方案**（动态 JSON、子集匹配、HTTP 认证）
4. **详细的 UI 实现方案**（菜单栏 + 主窗口双模式）
5. **分阶段的实施步骤**（估计 9-14 天完成）

下一步可以按照阶段 1 开始创建 Xcode 项目并实现基础架构。
