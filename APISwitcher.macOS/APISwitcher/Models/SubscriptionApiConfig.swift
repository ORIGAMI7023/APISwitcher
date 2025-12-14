//
//  SubscriptionApiConfig.swift
//  APISwitcher
//
//  订阅 API 配置
//

import Foundation

/// 订阅 API 配置
struct SubscriptionApiConfig: Codable, Equatable, Sendable {
    /// API 端点 URL（相对于 BaseUrl）
    /// 例如："/api/subscription/user/?p=0&size=10"
    var endpoint: String

    /// HTTP 方法：GET 或 POST
    var method: String = "GET"

    /// 认证方式：header、body 或 cookie
    var authType: String = "cookie"

    /// Session Cookie（当 authType 为 cookie 时使用）
    var sessionCookie: String?

    /// 额外的 HTTP Headers（当 authType 为 cookie 时可能需要）
    var extraHeaders: [String: String]?

    /// 请求超时时间（毫秒）
    var timeout: Int = 10000

    init(
        endpoint: String = "",
        method: String = "GET",
        authType: String = "cookie",
        sessionCookie: String? = nil,
        extraHeaders: [String: String]? = nil,
        timeout: Int = 10000
    ) {
        self.endpoint = endpoint
        self.method = method
        self.authType = authType
        self.sessionCookie = sessionCookie
        self.extraHeaders = extraHeaders
        self.timeout = timeout
    }
}
