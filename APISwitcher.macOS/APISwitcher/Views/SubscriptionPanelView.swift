//
//  SubscriptionPanelView.swift
//  APISwitcher
//
//  订阅信息面板视图（匹配 WPF 版本）
//

import SwiftUI

struct SubscriptionPanelView: View {
    let subscription: SubscriptionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题行
            HStack {
                Text("月卡订阅信息")
                    .font(.system(size: 16, weight: .bold))

                if subscription.hasError {
                    Text("更新失败")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#D32F2F"))
                        .padding(.leading, 10)
                }
            }

            // 加载状态
            if subscription.isFirstLoad {
                Text("加载中...")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#757575"))
            }

            // 未订阅状态
            if subscription.isUnsubscribed {
                Text("月卡未订阅")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#FF9800"))
            }

            // 订阅数据显示
            if !subscription.isFirstLoad && !subscription.hasError && !subscription.isUnsubscribed {
                VStack(spacing: 10) {
                    // 日限额
                    QuotaRowView(
                        title: "日限额",
                        used: subscription.dailyQuotaUsedUsd,
                        limit: subscription.dailyQuotaLimitUsd,
                        percent: subscription.dailyUsagePercent
                    )

                    // 周限额
                    QuotaRowView(
                        title: "周限额",
                        used: subscription.weeklyQuotaUsedUsd,
                        limit: subscription.weeklyQuotaLimitUsd,
                        percent: subscription.weeklyUsagePercent
                    )

                    // 总限额
                    QuotaRowView(
                        title: "总限额",
                        used: subscription.totalQuotaUsedUsd,
                        limit: subscription.totalQuotaLimitUsd,
                        percent: subscription.totalUsagePercent
                    )

                    // 到期时间
                    HStack {
                        Text("到期时间：")
                            .font(.system(size: 13))

                        Text("\(subscription.expireTimeFormatted) (剩余 \(subscription.daysRemaining) 天)")
                            .font(.system(size: 13))
                    }
                    .padding(.top, 5)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color(hex: "#F8F9FA"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#DEE2E6"), lineWidth: 1)
        )
    }
}

/// 限额行视图（带进度条）
struct QuotaRowView: View {
    let title: String
    let used: String
    let limit: String
    let percent: Double

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 13))

                Spacer()

                Text("\(used) / \(limit) (\(String(format: "%.1f", percent))%)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#666666"))
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    // 进度
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * min(percent / 100, 1.0))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}
