//
//  AppDelegate.swift
//  APISwitcher
//
//  菜单栏管理
//

import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var viewModel: MainViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "arrow.triangle.swap",
                accessibilityDescription: "API Switcher"
            )
        }

        // 创建 ViewModel
        viewModel = MainViewModel()

        // 异步初始化并更新菜单
        Task {
            await viewModel.initialize()
            await MainActor.run {
                updateMenu()
            }
        }
    }

    /// 更新菜单栏菜单
    @MainActor
    private func updateMenu() {
        let menu = NSMenu()

        // 添加标题
        let titleItem = NSMenuItem(title: "API Switcher", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // 添加配置选项
        if viewModel.profiles.isEmpty {
            let emptyItem = NSMenuItem(title: "暂无配置", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for profile in viewModel.profiles {
                let item = NSMenuItem(
                    title: profile.name,
                    action: #selector(switchProfile(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = profile.id
                item.state = profile.isActive ? .on : .off

                // 如果有余额信息，显示在子菜单
                if let balance = profile.balanceInfo {
                    item.toolTip = "余额: \(balance.formattedBalance)"
                }

                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // 刷新余额
        let refreshBalanceItem = NSMenuItem(
            title: "刷新所有余额",
            action: #selector(refreshAllBalances),
            keyEquivalent: "b"
        )
        refreshBalanceItem.target = self
        menu.addItem(refreshBalanceItem)

        // 刷新配置
        let refreshItem = NSMenuItem(
            title: "刷新配置",
            action: #selector(refresh),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // 打开主窗口
        let openWindowItem = NSMenuItem(
            title: "打开主窗口",
            action: #selector(openMainWindow),
            keyEquivalent: "o"
        )
        openWindowItem.target = self
        menu.addItem(openWindowItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// 切换配置
    @objc private func switchProfile(_ sender: NSMenuItem) {
        guard let profileId = sender.representedObject as? String,
              let profile = viewModel.profiles.first(where: { $0.id == profileId }),
              !profile.isActive else {
            return
        }

        let profileName = profile.name
        Task { @MainActor in
            await viewModel.switchProfile(profile)
            updateMenu()
            showNotification(
                title: "配置已切换",
                message: "已切换到: \(profileName)"
            )
        }
    }

    /// 刷新所有余额
    @objc private func refreshAllBalances() {
        Task { @MainActor in
            await viewModel.refreshAllBalances()
            updateMenu()
            showNotification(
                title: "余额已刷新",
                message: "所有配置的余额已更新"
            )
        }
    }

    /// 刷新配置
    @objc private func refresh() {
        Task { @MainActor in
            await viewModel.refresh()
            updateMenu()
        }
    }

    /// 打开主窗口
    @objc private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        // 如果没有窗口，创建一个新窗口
        if NSApplication.shared.windows.isEmpty {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "API Switcher"
            window.contentView = NSHostingView(rootView: MainView())
            window.makeKeyAndOrderFront(nil)
        } else {
            // 激活现有窗口
            NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    /// 显示通知
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 关闭窗口后不退出应用（菜单栏应用常驻）
        return false
    }
}
