//
//  Profile.swift
//  APISwitcher
//
//  配置模型
//

import Foundation

struct Profile: Identifiable, Codable, Equatable, Sendable {
    var name: String
    var isActive: Bool = false
    var settings: ClaudeSettings

    /// 余额 API 配置（可选，如果为 nil 则不显示余额）
    var balanceApi: BalanceApiConfig?

    /// 订阅 API 配置（可选，如果为 nil 则不显示订阅信息）
    var subscriptionApi: SubscriptionApiConfig?

    // 运行时状态（不编码到 JSON）
    var balanceInfo: BalanceInfo?
    var subscriptionInfo: SubscriptionInfo?

    // 计算属性：根据名称生成稳定的 ID
    var id: String {
        name
    }

    var shouldShowBalance: Bool {
        balanceApi != nil
    }

    var shouldShowSubscription: Bool {
        subscriptionApi != nil
    }

    enum CodingKeys: String, CodingKey {
        case name, isActive, settings, balanceApi, subscriptionApi
    }

    init(
        name: String,
        isActive: Bool = false,
        settings: ClaudeSettings,
        balanceApi: BalanceApiConfig? = nil,
        subscriptionApi: SubscriptionApiConfig? = nil
    ) {
        self.name = name
        self.isActive = isActive
        self.settings = settings
        self.balanceApi = balanceApi
        self.subscriptionApi = subscriptionApi
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        settings = try container.decode(ClaudeSettings.self, forKey: .settings)
        balanceApi = try? container.decodeIfPresent(BalanceApiConfig.self, forKey: .balanceApi)
        subscriptionApi = try? container.decodeIfPresent(SubscriptionApiConfig.self, forKey: .subscriptionApi)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(settings, forKey: .settings)
        if let balanceApi = balanceApi {
            try container.encode(balanceApi, forKey: .balanceApi)
        }
        if let subscriptionApi = subscriptionApi {
            try container.encode(subscriptionApi, forKey: .subscriptionApi)
        }
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}
