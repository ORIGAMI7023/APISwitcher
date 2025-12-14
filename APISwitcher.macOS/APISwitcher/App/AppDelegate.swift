//
//  AppDelegate.swift
//  APISwitcher
//
//  应用委托（窗口管理）
//

import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 关闭窗口后不退出应用（菜单栏应用常驻）
        return false
    }
}
