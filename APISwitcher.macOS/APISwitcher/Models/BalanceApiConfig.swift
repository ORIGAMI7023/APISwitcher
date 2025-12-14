//
//  BalanceApiConfig.swift
//  APISwitcher
//
//  余额 API 配置
//

import Foundation

/// 余额 API 配置
struct BalanceApiConfig: Codable, Equatable, Sendable {
    /// API 端点 URL（相对于 BaseUrl）
    /// 例如："/api/token/query" 或 "/api/usage/token"
    var endpoint: String

    /// HTTP 方法：GET 或 POST
    var method: String = "GET"

    /// 认证方式：header、body 或 cookie
    /// - header: 使用 Authorization: Bearer {token}
    /// - body: 在请求体中发送 {"token": "{token}"}
    /// - cookie: 使用 Cookie header 认证（需要配置 sessionCookie）
    var authType: String = "header"

    /// Session Cookie（当 authType 为 cookie 时使用）
    /// 例如："session=MTc2NDQ4OTIzN3x..."
    var sessionCookie: String?

    /// 额外的 HTTP Headers（当 authType 为 cookie 时可能需要）
    /// 例如：{"new-api-user": "285", "origin": "https://example.com"}
    var extraHeaders: [String: String]?

    /// 响应中余额字段的路径（使用点号分隔）
    /// 例如："data.total_available"
    /// 如果不设置此字段，则使用 limitField 和 usedField 计算
    var balanceField: String?

    /// 响应中总额度字段的路径（用于计算型余额）
    /// 例如："data.total_usage_limit"
    var limitField: String?

    /// 响应中已用额度字段的路径（用于计算型余额）
    /// 例如："data.total_usage_count"
    var usedField: String?

    /// 响应中无限额度标志字段的路径
    /// 例如："data.unlimited_quota"
    var unlimitedField: String?

    /// 显示单位：usd（美元）/ cny（人民币）/ times（次数）
    var displayUnit: String = "usd"

    /// 请求超时时间（毫秒）
    var timeout: Int = 10000

    /// 余额除数，用于单位转换
    /// 例如：500000 表示原始值需要除以 500000
    /// 默认值为 1（不转换）
    var divisor: Double = 1.0

    init(
        endpoint: String = "",
        method: String = "GET",
        authType: String = "header",
        sessionCookie: String? = nil,
        extraHeaders: [String: String]? = nil,
        balanceField: String? = nil,
        limitField: String? = nil,
        usedField: String? = nil,
        unlimitedField: String? = nil,
        displayUnit: String = "usd",
        timeout: Int = 10000,
        divisor: Double = 1.0
    ) {
        self.endpoint = endpoint
        self.method = method
        self.authType = authType
        self.sessionCookie = sessionCookie
        self.extraHeaders = extraHeaders
        self.balanceField = balanceField
        self.limitField = limitField
        self.usedField = usedField
        self.unlimitedField = unlimitedField
        self.displayUnit = displayUnit
        self.timeout = timeout
        self.divisor = divisor
    }
}
