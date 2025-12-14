//
//  BalanceService.swift
//  APISwitcher
//
//  余额查询服务
//

import Foundation

final class BalanceService: Sendable {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    /// 查询余额
    func queryBalance(config: Profile) async throws -> BalanceInfo {
        guard let balanceApi = config.balanceApi else {
            throw BalanceError.notConfigured
        }

        // 从 settings 中提取 token 和 baseUrl
        let token = getTokenFromSettings(config.settings)
        let baseUrl = getBaseUrlFromSettings(config.settings)

        // 检查认证信息（cookie 认证不需要 token）
        if balanceApi.authType.lowercased() != "cookie" {
            guard !token.isEmpty else {
                throw BalanceError.missingToken
            }
        }

        guard !baseUrl.isEmpty else {
            throw BalanceError.missingBaseUrl
        }

        // 构建完整 URL
        let fullUrl = try combineUrl(baseUrl: baseUrl, endpoint: balanceApi.endpoint)

        // 创建请求
        var request = createHttpRequest(
            apiConfig: balanceApi,
            token: token,
            url: fullUrl
        )

        // 设置超时
        request.timeoutInterval = TimeInterval(balanceApi.timeout) / 1000.0

        // 发送请求
        let (data, response) = try await session.data(for: request)

        // 检查响应状态
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BalanceError.requestFailed
        }

        // 解析 JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BalanceError.invalidResponse
        }

        // 计算余额
        var balance = try calculateBalance(from: json, apiConfig: balanceApi)

        // 应用除数进行单位转换
        if balanceApi.divisor > 0 && balanceApi.divisor != 1.0 {
            balance = balance / balanceApi.divisor
        }

        // 检查是否无限额度
        var isUnlimited = false
        if let unlimitedField = balanceApi.unlimitedField {
            isUnlimited = (try? extractValue(from: json, path: unlimitedField) as? Bool) ?? false
        }

        return BalanceInfo(
            balance: balance,
            currency: balanceApi.displayUnit,
            isUnlimited: isUnlimited
        )
    }

    /// 计算余额
    private func calculateBalance(from json: [String: Any], apiConfig: BalanceApiConfig) throws -> Double {
        // 优先使用 balanceField
        if let balanceField = apiConfig.balanceField, !balanceField.isEmpty {
            if let value = try? extractValue(from: json, path: balanceField) {
                if let doubleValue = value as? Double {
                    return doubleValue
                } else if let intValue = value as? Int {
                    return Double(intValue)
                } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
                    return doubleValue
                }
            }
        }

        // 如果没有 balanceField，则使用 limitField - usedField
        if let limitField = apiConfig.limitField, !limitField.isEmpty,
           let usedField = apiConfig.usedField, !usedField.isEmpty {
            if let limitValue = try? extractValue(from: json, path: limitField),
               let usedValue = try? extractValue(from: json, path: usedField) {
                let limit = (limitValue as? Double) ?? Double((limitValue as? Int) ?? 0)
                let used = (usedValue as? Double) ?? Double((usedValue as? Int) ?? 0)
                return limit - used
            }
        }

        throw BalanceError.balanceNotFound
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
            throw BalanceError.invalidURL
        }
        return url
    }

    /// 创建 HTTP 请求
    private func createHttpRequest(apiConfig: BalanceApiConfig, token: String, url: URL) -> URLRequest {
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

    /// 从 JSON 中提取指定路径的值
    private func extractValue(from json: [String: Any], path: String) throws -> Any {
        let parts = path.split(separator: ".")
        var current: Any = json

        for part in parts {
            if let dict = current as? [String: Any],
               let value = dict[String(part)] {
                current = value
            } else {
                throw BalanceError.pathNotFound(path)
            }
        }

        return current
    }
}

enum BalanceError: LocalizedError {
    case notConfigured
    case missingToken
    case missingBaseUrl
    case invalidURL
    case requestFailed
    case invalidResponse
    case balanceNotFound
    case pathNotFound(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "未配置余额 API"
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
        case .balanceNotFound:
            return "无法从响应中提取余额"
        case .pathNotFound(let path):
            return "无法找到路径: \(path)"
        }
    }
}
