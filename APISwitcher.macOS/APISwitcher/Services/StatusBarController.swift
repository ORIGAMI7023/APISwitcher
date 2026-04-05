//
//  StatusBarController.swift
//  APISwitcher
//
//  菜单栏控制器
//

import AppKit
import SwiftUI

@MainActor
class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var viewModel: MainViewModel

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        print("🎯 StatusBarController init")
    }

    func setupStatusBar() {
        print("🔧 Setting up status bar")

        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("📍 StatusItem created: \(statusItem != nil)")

        if let button = statusItem?.button {
            button.title = "🔄"
            print("✅ StatusItem button title set to 🔄")
        } else {
            print("❌ StatusItem button is nil")
        }

        // 初始化菜单
        updateMenu()
    }

    func updateMenu() {
        print("📋 Updating menu, profiles count: \(viewModel.profiles.count)")

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

                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // 刷新配置
        let refreshItem = NSMenuItem(
            title: "刷新配置",
            action: #selector(refresh),
            keyEquivalent: ""
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: ""
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
        print("✅ Menu set with \(menu.items.count) items")
    }

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

    @objc private func refresh() {
        Task { @MainActor in
            await viewModel.refresh()
            updateMenu()
        }
    }

    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }
}
