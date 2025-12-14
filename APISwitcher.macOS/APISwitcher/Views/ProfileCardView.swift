//
//  ProfileCardView.swift
//  APISwitcher
//
//  配置卡片视图（匹配 WPF 版本简洁风格）
//

import SwiftUI

struct ProfileCardView: View {
    let profileIndex: Int
    @Bindable var viewModel: MainViewModel

    private var profile: Profile {
        viewModel.profiles[profileIndex]
    }

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

                // 余额信息
                if profile.shouldShowBalance {
                    if let balance = profile.balanceInfo {
                        Text(balance.formattedBalance)
                            .font(.system(size: 12))
                            .foregroundStyle(balance.isUnlimited ? Color(hex: "#388E3C") : Color(hex: "#1976D2"))
                            .multilineTextAlignment(.center)
                    }
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
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }

                    // 删除按钮（激活的配置不显示）
                    if !profile.isActive {
                        Button {
                            viewModel.deleteProfile(profile)
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
                        .onHover { isHovered in
                            if isHovered {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
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
            if !profile.isActive {
                Task {
                    await viewModel.switchProfile(profile)
                }
            }
        }
        .onHover { isHovered in
            if !profile.isActive {
                if isHovered {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
}

// 扩展：判断可选字符串是否为空
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

#Preview {
    let viewModel = MainViewModel()
    // 预览时无法直接添加 profiles，使用空视图占位
    ProfileCardView(profileIndex: 0, viewModel: viewModel)
        .padding()
        .frame(width: 400)
}
