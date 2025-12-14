//
//  MainView.swift
//  APISwitcher
//
//  主窗口视图（匹配 WPF 版本布局）
//

import SwiftUI

struct MainView: View {
    @Bindable var viewModel: MainViewModel
    @State private var refreshTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            VStack(spacing: 0) {
                Text("Claude Code 账号配置切换")
                    .font(.system(size: 24, weight: .bold))
                    .frame(height: 60)
            }
            .padding(.bottom, 20)

            // 配置卡片区域（固定高度）
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 200, maximum: 200), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.profiles.indices, id: \.self) { index in
                        ProfileCardView(profileIndex: index, viewModel: viewModel)
                            .id("\(viewModel.profiles[index].id)-\(viewModel.profiles[index].isActive)-\(refreshTrigger)")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
            .frame(height: 250)

            // 订阅信息面板
            if let activeProfile = viewModel.profiles.first(where: { $0.isActive }),
               let subscription = activeProfile.subscriptionInfo {
                SubscriptionPanelView(subscription: subscription)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // 操作按钮
            HStack(spacing: 10) {
                Button("刷新配置") {
                    Task {
                        await viewModel.refresh()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 120, height: 38)

                Button("添加配置") {
                    viewModel.showAddForm()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 120, height: 38)
            }
            .padding(.top, 20)

            // 状态栏
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 10)
                }

                Text(viewModel.statusMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#666666"))

                Spacer()
            }
            .padding()
            .background(Color(hex: "#F5F5F5"))
            .cornerRadius(5)
            .padding(.top, 10)
        }
        .padding(20)
        .sheet(isPresented: $viewModel.showingForm) {
            if let formViewModel = viewModel.formViewModel {
                ProfileFormView(viewModel: formViewModel)
            }
        }
        .task {
            print("🎬 MainView task started")
            await viewModel.initialize()
            viewModel.refreshUI = {
                refreshTrigger.toggle()
            }
        }
        .frame(width: 780, height: 460)
    }
}

#Preview {
    MainView(viewModel: MainViewModel())
}
