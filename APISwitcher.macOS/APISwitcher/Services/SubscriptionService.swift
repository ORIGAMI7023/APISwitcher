//
//  SubscriptionService.swift
//  APISwitcher
//
//  订阅信息查询服务
//

import Foundation

final class SubscriptionService: Sendable {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    /// 查询订阅信息
    func querySubscription(config: Profile) async throws -> SubscriptionInfo {
        guard let subscriptionApi = config.subscriptionApi else {
            throw SubscriptionError.notConfigured
        }

        // 从 settings 中提取 token 和 baseUrl
        let token = getTokenFromSettings(config.settings)
        let baseUrl = getBaseUrlFromSettings(config.settings)

        // 检查认证信息（cookie 认证不需要 token）
        if subscriptionApi.authType.lowercased() != "cookie" {
            guard !token.isEmpty else {
                throw SubscriptionError.missingToken
            }
        }

        guard !baseUrl.isEmpty else {
            throw SubscriptionError.missingBaseUrl
        }

        // 构建完整 URL
        let fullUrl = try combineUrl(baseUrl: baseUrl, endpoint: subscriptionApi.endpoint)

        // 创建请求
        var request = createHttpRequest(
            apiConfig: subscriptionApi,
            token: token,
            url: fullUrl
        )

        // 设置超时
        request.timeoutInterval = TimeInterval(subscriptionApi.timeout) / 1000.0

        // 发送请求
        let (data, response) = try await session.data(for: request)

        // 检查响应状态
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SubscriptionError.requestFailed
        }

        // 解析 JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SubscriptionError.invalidResponse
        }

        // 提取订阅数据：data.items[0]
        guard let dataDict = json["data"] as? [String: Any],
              let items = dataDict["items"] as? [[String: Any]],
              !items.isEmpty else {
            // API 调用成功，但没有订阅数据，表示用户未订阅
            return SubscriptionInfo(isUnsubscribed: true, isFirstLoad: false)
        }

        let item = items[0]

        guard let subscriptionInfoDict = item["subscription_info"] as? [String: Any] else {
            // 有订阅记录，但没有详细信息，也认为是未订阅
            return SubscriptionInfo(isUnsubscribed: true, isFirstLoad: false)
        }

        // 提取各个字段
        let dailyQuotaLimit = (subscriptionInfoDict["daily_quota_limit"] as? NSNumber)?.int64Value ?? 0
        let dailyQuotaUsed = (item["daily_quota_used"] as? NSNumber)?.int64Value ?? 0
        let weeklyQuotaLimit = (subscriptionInfoDict["weekly_quota_limit"] as? NSNumber)?.int64Value ?? 0
        let weeklyQuotaUsed = (item["weekly_quota_used"] as? NSNumber)?.int64Value ?? 0
        let totalQuotaLimit = (subscriptionInfoDict["total_quota_limit"] as? NSNumber)?.int64Value ?? 0
        let totalQuotaUsed = (item["total_quota_used"] as? NSNumber)?.int64Value ?? 0
        let expireTime = (item["expire_time"] as? NSNumber)?.int64Value ?? 0

        return SubscriptionInfo(
            dailyQuotaLimit: dailyQuotaLimit,
            dailyQuotaUsed: dailyQuotaUsed,
            weeklyQuotaLimit: weeklyQuotaLimit,
            weeklyQuotaUsed: weeklyQuotaUsed,
            totalQuotaLimit: totalQuotaLimit,
            totalQuotaUsed: totalQuotaUsed,
            expireTime: expireTime,
            isUnsubscribed: false,
            isFirstLoad: false
        )
    }

    /// 从 Settings 中提取 Token
    private func getTokenFromSettings(_ settings: ClaudeSettings) -> String {
        let dict = settings.toDictionary()
        if let env = dict["env"] as? [String: Any],
           let token = env["ANTHROPIC_AUTH_TOKEN"] as? String {
            return token
        }
        return ""
    }

    /// 从 Settings 中提取 BaseUrl
    private func getBaseUrlFromSettings(_ settings: ClaudeSettings) -> String {
        let dict = settings.toDictionary()
        if let env = dict["env"] as? [String: Any],
           let baseUrl = env["ANTHROPIC_BASE_URL"] as? String {
            return baseUrl
        }
        return ""
    }

    /// 组合 URL
    private func combineUrl(baseUrl: String, endpoint: String) throws -> URL {
        let cleanBase = baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanEndpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = "\(cleanBase)/\(cleanEndpoint)"

        guard let url = URL(string: urlString) else {
            throw SubscriptionError.invalidURL
        }
        return url
    }

    /// 创建 HTTP 请求
    private func createHttpRequest(apiConfig: SubscriptionApiConfig, token: String, url: URL) -> URLRequest {
        let method = apiConfig.method.uppercased()
        var request = URLRequest(url: url)
        request.httpMethod = method

        if apiConfig.authType.lowercased() == "header" {
            // 使用 Header 认证：Authorization: Bearer {token}
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if apiConfig.authType.lowercased() == "body" {
            // 使用 Body 认证：{"token": "{token}"}
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = ["token": token]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        } else if apiConfig.authType.lowercased() == "cookie" {
            // 使用 Cookie 认证
            if let sessionCookie = apiConfig.sessionCookie, !sessionCookie.isEmpty {
                request.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
            }

            // 添加额外的 headers
            if let extraHeaders = apiConfig.extraHeaders {
                for (key, value) in extraHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
            }
        }

        return request
    }
}

enum SubscriptionError: LocalizedError {
    case notConfigured
    case missingToken
    case missingBaseUrl
    case invalidURL
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "未配置订阅 API"
        case .missingToken:
            return "缺少认证 Token"
        case .missingBaseUrl:
            return "缺少 Base URL"
        case .invalidURL:
            return "无效的 API 地址"
        case .requestFailed:
            return "请求失败"
        case .invalidResponse:
            return "无效的响应数据"
        }
    }
}
