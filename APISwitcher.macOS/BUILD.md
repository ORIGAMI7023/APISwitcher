# APISwitcher macOS - 构建指南

## 快速开始

### 使用 Xcode 构建

1. **打开项目**
   ```bash
   cd APISwitcher.macOS
   open APISwitcher.xcodeproj
   ```

2. **选择 scheme**
   - 在 Xcode 顶部选择 `APISwitcher` scheme
   - 选择 `My Mac` 作为目标设备

3. **运行**
   - 点击 ▶️ 运行按钮
   - 或按 `Cmd + R`

### 使用命令行构建

#### Debug 构建
```bash
cd APISwitcher.macOS

xcodebuild \
  -project APISwitcher.xcodeproj \
  -scheme APISwitcher \
  -configuration Debug \
  build
```

#### Release 构建
```bash
xcodebuild \
  -project APISwitcher.xcodeproj \
  -scheme APISwitcher \
  -configuration Release \
  clean build
```

编译后的应用位于：
```
build/Release/APISwitcher.app
```

### 创建可分发的应用

#### 方式一：Archive（推荐）

```bash
xcodebuild \
  -project APISwitcher.xcodeproj \
  -scheme APISwitcher \
  -configuration Release \
  -archivePath ./build/APISwitcher.xcarchive \
  archive

xcodebuild \
  -exportArchive \
  -archivePath ./build/APISwitcher.xcarchive \
  -exportPath ./build/Release \
  -exportOptionsPlist ExportOptions.plist
```

需要先创建 `ExportOptions.plist`：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

#### 方式二：直接复制 .app

```bash
# 构建后复制到 Applications
cp -R build/Release/APISwitcher.app /Applications/

# 或创建 DMG（需要安装 create-dmg）
brew install create-dmg

create-dmg \
  --volname "APISwitcher" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "APISwitcher.app" 175 120 \
  --hide-extension "APISwitcher.app" \
  --app-drop-link 425 120 \
  "APISwitcher-1.0.dmg" \
  "build/Release/APISwitcher.app"
```

## 开发环境配置

### 必需工具

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 6.0+

### 可选工具

- `xcpretty` - 美化 xcodebuild 输出
  ```bash
  gem install xcpretty

  # 使用示例
  xcodebuild ... | xcpretty
  ```

- `xcode-install` - 管理 Xcode 版本
  ```bash
  gem install xcode-install
  ```

## 常见问题

### Q: 编译错误 "No such module 'SwiftUI'"

A: 确保 macOS 部署目标设置为 14.0 或更高版本。

### Q: 代码签名错误

A: 在项目设置中：
1. 选择 APISwitcher target
2. Signing & Capabilities 标签
3. 取消勾选 "Automatically manage signing"
4. Code Signing Identity 选择 "-" (不签名)

### Q: 编译警告 "is only available in macOS 14.0 or newer"

A: 检查 `MACOSX_DEPLOYMENT_TARGET` 设置是否为 14.0：
```bash
xcodebuild -showBuildSettings | grep MACOSX_DEPLOYMENT_TARGET
```

## 项目文件结构

```
APISwitcher.macOS/
├── APISwitcher.xcodeproj/
│   └── project.pbxproj         # Xcode 项目配置
├── APISwitcher/
│   ├── App/                    # 应用入口
│   ├── Models/                 # 数据模型
│   ├── Services/               # 业务服务
│   ├── ViewModels/             # MVVM ViewModels
│   ├── Views/                  # SwiftUI 视图
│   ├── Utilities/              # 工具类
│   ├── Resources/              # 资源文件
│   └── Info.plist              # 应用配置
├── .gitignore
├── README.md
└── BUILD.md                    # 本文件
```

## 清理构建产物

```bash
# 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/APISwitcher-*

# 清理项目构建目录
rm -rf build/

# 使用 xcodebuild 清理
xcodebuild clean \
  -project APISwitcher.xcodeproj \
  -scheme APISwitcher
```

## CI/CD 示例

### GitHub Actions

创建 `.github/workflows/build.yml`：

```yaml
name: Build macOS App

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-14

    steps:
    - uses: actions/checkout@v4

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app

    - name: Build
      run: |
        cd APISwitcher.macOS
        xcodebuild \
          -project APISwitcher.xcodeproj \
          -scheme APISwitcher \
          -configuration Release \
          build

    - name: Upload App
      uses: actions/upload-artifact@v4
      with:
        name: APISwitcher-macOS
        path: APISwitcher.macOS/build/Release/APISwitcher.app
```

## 性能优化

### 编译速度优化

1. **启用并行构建**
   - Xcode → Preferences → Behaviors → Build
   - 勾选 "Parallelize Build"

2. **使用编译缓存**
   ```bash
   # 启用 ccache
   brew install ccache

   # 在 Build Settings 中添加：
   CC = "ccache clang"
   CXX = "ccache clang++"
   ```

### 应用体积优化

1. **启用优化选项**
   - Build Settings → Optimization Level → `-Os` (Optimize for Size)

2. **去除符号表**
   - Build Settings → Strip Debug Symbols During Copy → Yes
   - Build Settings → Strip Linked Product → Yes

## 调试技巧

### 查看构建日志
```bash
xcodebuild ... 2>&1 | tee build.log
```

### 检查代码签名
```bash
codesign -vvv build/Release/APISwitcher.app
```

### 查看依赖
```bash
otool -L build/Release/APISwitcher.app/Contents/MacOS/APISwitcher
```

---

**祝构建顺利！** 🎉
