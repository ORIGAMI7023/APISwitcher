//
//  APISwitcherApp.swift
//  APISwitcher
//
//  应用入口
//

import SwiftUI

@main
struct APISwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .commands {
            // 移除新建窗口命令
            CommandGroup(replacing: .newItem) {}
        }
    }
}
