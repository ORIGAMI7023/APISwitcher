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
    @State private var viewModel = MainViewModel()

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        // 菜单栏
        MenuBarExtra("API Switcher", systemImage: "server.rack") {
            MenuBarContentView(viewModel: viewModel)
        }
    }
}

/// 菜单栏内容视图
struct MenuBarContentView: View {
    @Bindable var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("API Switcher")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            if viewModel.isLoading {
                Text("加载中...")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else if viewModel.profiles.isEmpty {
                Text("暂无配置")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.profiles.indices, id: \.self) { index in
                    let profile = viewModel.profiles[index]
                    Button {
                        Task {
                            await viewModel.switchProfile(profile)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: profile.isActive ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(profile.isActive ? .green : .secondary)
                            Text(profile.name)
                        }
                    }
                    .buttonStyle(.plain)
                    .id("\(profile.id)-\(profile.isActive)")
                }
            }

            Divider()

            Button("刷新配置") {
                Task {
                    await viewModel.refresh()
                }
            }

            Divider()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(minWidth: 200)
        .task {
            await viewModel.initialize()
        }
    }
}
