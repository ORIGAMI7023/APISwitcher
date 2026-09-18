//
//  ProfileCardView.swift
//  APISwitcher
//
//  配置卡片视图（匹配 WPF 版本简洁风格）
//

import SwiftUI

struct ProfileCardView: View {
    let profile: Profile
    @Bindable var viewModel: MainViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            // 主要内容（居中）
            VStack(alignment: .center, spacing: 6) {
                // 配置名称
                Text(profile.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                // 当前使用标识
                if profile.isActive {
                    Text("● 当前使用")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)

            // 右上角操作按钮
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Spacer()

                    // 编辑按钮
                    Button {
                        viewModel.editProfile(profile)
                    } label: {
                        Text("✏️")
                            .font(.system(size: 12))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .background(Color.black.opacity(0.0001)) // 透明但可点击
                    .cornerRadius(3)
                    .help("编辑配置")

                    // 删除按钮（激活的配置不显示）
                    if !profile.isActive {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Text("×")
                                .font(.system(size: 16))
                                .foregroundStyle(.red)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .background(Color.black.opacity(0.0001))
                        .cornerRadius(3)
                        .help("删除配置")
                        .confirmationDialog(
                            "确定要删除配置 \"\(profile.name)\" 吗？此操作不可撤销。",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("删除", role: .destructive) {
                                viewModel.deleteProfile(profile)
                            }
                            Button("取消", role: .cancel) {}
                        }
                    }
                }
                Spacer()
            }
            .padding(EdgeInsets(top: -5, leading: 0, bottom: 0, trailing: -5))
        }
        .frame(width: 200)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(profile.isActive ? Color(hex: "#DFF6E3") : Color(hex: "#F2F4F8"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(profile.isActive ? Color(hex: "#2E7D32") : Color(hex: "#9FA7B3"), lineWidth: 2)
        )
        .contentShape(Rectangle()) // 整个区域可点击
        .onTapGesture {
            // 允许点击已选中的项目，强制重新写入
            Task {
                await viewModel.switchProfile(profile)
            }
        }
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

#Preview {
    let viewModel = MainViewModel()
    let dummyProfile = Profile(name: "Claude官方", isActive: true, settings: ClaudeSettings())
    ProfileCardView(profile: dummyProfile, viewModel: viewModel)
        .padding()
        .frame(width: 400)
}
