//
//  SubscriptionView.swift
//  APISwitcher
//
//  订阅信息视图（已废弃，使用 SubscriptionPanelView）
//

import SwiftUI

struct SubscriptionView: View {
    let subscription: SubscriptionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if subscription.isUnsubscribed {
                Text("未订阅")
                    .foregroundStyle(.secondary)
            } else {
                Text("订阅信息")
                    .font(.headline)

                Divider()

                // 到期时间
                HStack {
                    Text("到期时间:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(subscription.expireTimeFormatted)
                        .font(.caption)
                }

                // 剩余天数
                HStack {
                    Text("剩余天数:")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(subscription.daysRemaining) 天")
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    SubscriptionView(subscription: SubscriptionInfo(
        expireTime: 1735689600,
        isUnsubscribed: false,
        isFirstLoad: false
    ))
    .frame(width: 300)
    .padding()
}
