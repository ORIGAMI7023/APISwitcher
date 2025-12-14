//
//  ProfileFormView.swift
//  APISwitcher
//
//  配置表单视图
//

import SwiftUI

struct ProfileFormView: View {
    @Bindable var viewModel: ProfileFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(viewModel.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()

            Divider()

            // 表单内容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    GroupBox("基本信息") {
                        VStack(alignment: .leading, spacing: 12) {
                            FormField("配置名称", text: $viewModel.name)
                        }
                    }

                    // Claude 设置
                    GroupBox("Claude 设置") {
                        VStack(alignment: .leading, spacing: 12) {
                            FormField("API Key", text: $viewModel.claudeApiKey)
                                .help("Claude API 密钥")

                            HStack {
                                Text("模型:")
                                    .frame(width: 100, alignment: .trailing)

                                Picker("", selection: $viewModel.claudeModel) {
                                    ForEach(viewModel.commonModels, id: \.self) { model in
                                        Text(model).tag(model)
                                    }
                                }
                                .labelsHidden()
                            }

                            FormField("Base URL (可选)", text: $viewModel.claudeBaseURL)
                                .help("自定义 API 端点")
                        }
                    }

                    // 余额查询设置
                    GroupBox("余额查询 (可选)") {
                        VStack(alignment: .leading, spacing: 12) {
                            FormField("余额 API", text: $viewModel.balanceApi)

                            HStack {
                                Text("认证方式:")
                                    .frame(width: 100, alignment: .trailing)

                                Picker("", selection: $viewModel.authMode) {
                                    ForEach(viewModel.authModes, id: \.self) { mode in
                                        Text(mode.capitalized).tag(mode)
                                    }
                                }
                                .labelsHidden()
                            }

                            FormField("认证键名", text: $viewModel.authKey)
                                .help("如 Authorization、X-API-Key、session 等")

                            FormField("API Key", text: $viewModel.apiKey)
                                .help("用于余额查询的认证密钥")

                            FormField("余额 JSON 路径", text: $viewModel.balanceJsonPath)
                                .help("如 $.data.balance 或 $.balance")
                        }
                    }

                    // 订阅查询设置
                    GroupBox("订阅查询 (可选)") {
                        VStack(alignment: .leading, spacing: 12) {
                            FormField("订阅 API", text: $viewModel.subscriptionApi)

                            FormField("订阅 JSON 路径", text: $viewModel.subscriptionJsonPath)
                                .help("如 $.data 或留空使用整个响应")
                        }
                    }

                    // 错误信息
                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.callout)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            // 底部按钮
            HStack {
                Button("取消") {
                    viewModel.cancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("保存") {
                    viewModel.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - FormField 辅助视图
struct FormField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .frame(width: 100, alignment: .trailing)
                .padding(.top, 4)

            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    ProfileFormView(viewModel: ProfileFormViewModel())
}
