//
//  SubscriptionInfo.swift
//  APISwitcher
//
//  订阅信息模型（匹配 WPF 版本）
//

import Foundation

struct SubscriptionInfo: Codable, Equatable, Sendable {
    var dailyQuotaLimit: Int64
    var dailyQuotaUsed: Int64
    var weeklyQuotaLimit: Int64
    var weeklyQuotaUsed: Int64
    var totalQuotaLimit: Int64
    var totalQuotaUsed: Int64
    var expireTime: Int64

    var isLoading: Bool
    var hasError: Bool
    var errorMessage: String?
    var isUnsubscribed: Bool
    var isFirstLoad: Bool

    /// 单位换算除数（API原始值除以此数得到美元）
    private let divisor: Double = 500000.0

    init(
        dailyQuotaLimit: Int64 = 0,
        dailyQuotaUsed: Int64 = 0,
        weeklyQuotaLimit: Int64 = 0,
        weeklyQuotaUsed: Int64 = 0,
        totalQuotaLimit: Int64 = 0,
        totalQuotaUsed: Int64 = 0,
        expireTime: Int64 = 0,
        isLoading: Bool = false,
        hasError: Bool = false,
        errorMessage: String? = nil,
        isUnsubscribed: Bool = false,
        isFirstLoad: Bool = true
    ) {
        self.dailyQuotaLimit = dailyQuotaLimit
        self.dailyQuotaUsed = dailyQuotaUsed
        self.weeklyQuotaLimit = weeklyQuotaLimit
        self.weeklyQuotaUsed = weeklyQuotaUsed
        self.totalQuotaLimit = totalQuotaLimit
        self.totalQuotaUsed = totalQuotaUsed
        self.expireTime = expireTime
        self.isLoading = isLoading
        self.hasError = hasError
        self.errorMessage = errorMessage
        self.isUnsubscribed = isUnsubscribed
        self.isFirstLoad = isFirstLoad
    }

    // MARK: - Computed Properties

    /// 日限额（美元）
    var dailyQuotaLimitUsd: String {
        String(format: "$%.2f", Double(dailyQuotaLimit) / divisor)
    }

    /// 日已用（美元）
    var dailyQuotaUsedUsd: String {
        String(format: "$%.2f", Double(dailyQuotaUsed) / divisor)
    }

    /// 周限额（美元）
    var weeklyQuotaLimitUsd: String {
        String(format: "$%.2f", Double(weeklyQuotaLimit) / divisor)
    }

    /// 周已用（美元）
    var weeklyQuotaUsedUsd: String {
        String(format: "$%.2f", Double(weeklyQuotaUsed) / divisor)
    }

    /// 总限额（美元）
    var totalQuotaLimitUsd: String {
        String(format: "$%.2f", Double(totalQuotaLimit) / divisor)
    }

    /// 总已用（美元）
    var totalQuotaUsedUsd: String {
        String(format: "$%.2f", Double(totalQuotaUsed) / divisor)
    }

    /// 日使用百分比
    var dailyUsagePercent: Double {
        dailyQuotaLimit > 0 ? Double(dailyQuotaUsed) / Double(dailyQuotaLimit) * 100 : 0
    }

    /// 周使用百分比
    var weeklyUsagePercent: Double {
        weeklyQuotaLimit > 0 ? Double(weeklyQuotaUsed) / Double(weeklyQuotaLimit) * 100 : 0
    }

    /// 总使用百分比
    var totalUsagePercent: Double {
        totalQuotaLimit > 0 ? Double(totalQuotaUsed) / Double(totalQuotaLimit) * 100 : 0
    }

    /// 剩余天数
    var daysRemaining: Int {
        guard expireTime > 0 else { return 0 }
        let expireDate = Date(timeIntervalSince1970: TimeInterval(expireTime))
        let timeInterval = expireDate.timeIntervalSince(Date())
        return max(0, Int(ceil(timeInterval / 86400)))
    }

    /// 到期时间格式化字符串
    var expireTimeFormatted: String {
        guard expireTime > 0 else { return "未知" }
        let expireDate = Date(timeIntervalSince1970: TimeInterval(expireTime))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: expireDate)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case dailyQuotaLimit, dailyQuotaUsed
        case weeklyQuotaLimit, weeklyQuotaUsed
        case totalQuotaLimit, totalQuotaUsed
        case expireTime
        case isLoading, hasError, errorMessage
        case isUnsubscribed, isFirstLoad
    }
}
