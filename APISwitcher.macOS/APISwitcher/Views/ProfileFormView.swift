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
                            FormField("配置名称 *", text: $viewModel.name)
                                .help("显示的配置名称")
                        }
                    }

                    // 必填设置
                    GroupBox("必填设置") {
                        VStack(alignment: .leading, spacing: 12) {
                            FormField("API Key *", text: $viewModel.authToken)
                                .help("ANTHROPIC_AUTH_TOKEN")

                            FormField("Base URL *", text: $viewModel.baseUrl)
                                .help("ANTHROPIC_BASE_URL，例如: https://api.anthropic.com")
                        }
                    }

                    // 可选模型设置
                    GroupBox("可选模型设置") {
                        VStack(alignment: .leading, spacing: 12) {
                            FormField("默认模型", text: $viewModel.defaultModel)
                                .help("ANTHROPIC_MODEL，留空则不写入配置")

                            FormField("默认 Haiku 模型", text: $viewModel.defaultHaikuModel)
                                .help("ANTHROPIC_DEFAULT_HAIKU_MODEL，留空则不写入配置")

                            FormField("默认 Sonnet 模型", text: $viewModel.defaultSonnetModel)
                                .help("ANTHROPIC_DEFAULT_SONNET_MODEL，留空则不写入配置")

                            FormField("默认 Opus 模型", text: $viewModel.defaultOpusModel)
                                .help("ANTHROPIC_DEFAULT_OPUS_MODEL，留空则不写入配置")
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
        .frame(width: 550, height: 500)
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
                .frame(width: 120, alignment: .trailing)
                .padding(.top, 4)

            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    ProfileFormView(viewModel: ProfileFormViewModel())
}
