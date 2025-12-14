//
//  ProfileFormViewModel.swift
//  APISwitcher
//
//  配置表单 ViewModel
//

import Foundation
import SwiftUI

@MainActor
protocol ProfileFormDelegate: AnyObject {
    func didSaveProfile(_ profile: Profile, isNew: Bool)
    func didCancelForm()
}

@MainActor
@Observable
class ProfileFormViewModel {
    // 基本信息
    var name: String
    var balanceApi: String
    var authMode: String
    var authKey: String
    var apiKey: String
    var balanceJsonPath: String
    var subscriptionApi: String
    var subscriptionJsonPath: String

    // Claude 设置
    var claudeApiKey: String
    var claudeModel: String
    var claudeBaseURL: String

    var errorMessage: String?

    private let originalProfile: Profile?
    private weak var delegate: ProfileFormDelegate?

    let authModes = ["header", "body", "cookie"]
    let commonModels = [
        "claude-sonnet-4.5",
        "claude-opus-4.5",
        "claude-haiku-4.0",
        "claude-3-5-sonnet-20241022"
    ]

    var isNew: Bool {
        originalProfile == nil
    }

    var title: String {
        isNew ? "添加配置" : "编辑配置"
    }

    init(profile: Profile? = nil, delegate: ProfileFormDelegate? = nil) {
        self.originalProfile = profile
        self.delegate = delegate

        // 简化的初始化 - 只初始化基本字段
        self.name = profile?.name ?? ""
        self.balanceApi = ""
        self.authMode = "header"
        self.authKey = "Authorization"
        self.apiKey = ""
        self.balanceJsonPath = "$.balance"
        self.subscriptionApi = ""
        self.subscriptionJsonPath = "$.data"

        // Claude 设置
        self.claudeApiKey = profile?.settings.claude?.apiKey ?? ""
        self.claudeModel = profile?.settings.claude?.model ?? "claude-sonnet-4.5"
        self.claudeBaseURL = profile?.settings.claude?.baseURL ?? ""
    }

    /// 验证表单
    func validate() -> Bool {
        errorMessage = nil

        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请输入配置名称"
            return false
        }

        if claudeApiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请输入 Claude API Key"
            return false
        }

        return true
    }

    /// 保存
    func save() {
        guard validate() else { return }

        // TODO: 需要重构以支持新的 Profile 结构
        errorMessage = "表单功能暂未适配新的配置格式"
        /*
        let claudeConfig = ClaudeSettings.ClaudeConfig(
            apiKey: claudeApiKey,
            model: claudeModel,
            baseURL: claudeBaseURL.isEmpty ? nil : claudeBaseURL
        )

        let settings = ClaudeSettings(
            claude: claudeConfig,
            mcpServers: originalProfile?.settings.mcpServers
        )

        let profile = Profile(
            name: name,
            settings: settings
        )

        delegate?.didSaveProfile(profile, isNew: isNew)
        */
    }

    /// 取消
    func cancel() {
        delegate?.didCancelForm()
    }
}
