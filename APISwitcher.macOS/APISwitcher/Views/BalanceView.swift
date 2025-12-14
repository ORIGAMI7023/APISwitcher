//
//  BalanceView.swift
//  APISwitcher
//
//  余额显示视图
//

import SwiftUI

struct BalanceView: View {
    let balance: BalanceInfo

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("余额")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(balance.formattedBalance)
                    .font(.headline)
            }

            Spacer()

            Text(relativeTime)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: balance.lastUpdated, relativeTo: Date())
    }
}

#Preview {
    BalanceView(balance: BalanceInfo(balance: 123.45, currency: "USD"))
        .padding()
        .frame(width: 300)
}
