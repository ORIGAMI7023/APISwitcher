//
//  BalanceInfo.swift
//  APISwitcher
//
//  余额信息模型
//

import Foundation

struct BalanceInfo: Codable, Equatable, Sendable {
    let balance: Double
    let currency: String
    let isUnlimited: Bool
    let lastUpdated: Date

    init(balance: Double, currency: String = "usd", isUnlimited: Bool = false, lastUpdated: Date = Date()) {
        self.balance = balance
        self.currency = currency
        self.isUnlimited = isUnlimited
        self.lastUpdated = lastUpdated
    }

    /// 格式化的余额显示
    var formattedBalance: String {
        if isUnlimited {
            return "无限额度"
        }

        switch currency.lowercased() {
        case "usd":
            return String(format: "$%.2f", balance)
        case "cny":
            return String(format: "¥%.2f", balance)
        case "times":
            return String(format: "%.0f 次", balance)
        default:
            return String(format: "%.2f %@", balance, currency)
        }
    }
}
