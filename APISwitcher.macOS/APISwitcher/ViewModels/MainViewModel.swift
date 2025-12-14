//
//  MainViewModel.swift
//  APISwitcher
//
//  主窗口 ViewModel
//

import Foundation
import SwiftUI

@MainActor
@Observable
class MainViewModel {
    var profiles: [Profile] = []
    var isLoading = false
    var statusMessage = "就绪"
    var showingForm = false
    var formViewModel: ProfileFormViewModel?

    // 用于触发 UI 刷新的回调
    var refreshUI: (() -> Void)?

    private let configService = ConfigService()
    private let balanceService = BalanceService()
    private let subscriptionService = SubscriptionService()

    /// 初始化
    func initialize() async {
        await loadProfiles()
    }

    /// 加载配置列表
    func loadProfiles() async {
        isLoading = true
        statusMessage = "加载配置..."

        do {
            var loadedProfiles = try configService.loadProfiles()
            loadedProfiles = configService.markActiveProfile(loadedProfiles)

            profiles = loadedProfiles
            statusMessage = "加载完成，共 \(loadedProfiles.count) 个配置"
            isLoading = false
        } catch {
            statusMessage = "加载失败: \(error.localizedDescription)"
            isLoading = false
            profiles = []
        }
    }

    /// 切换配置
    func switchProfile(_ profile: Profile) async {
        guard !profile.isActive else { return }

        statusMessage = "正在切换到 \(profile.name)..."
        isLoading = true

        do {
            try configService.switchProfile(profile)

            // 使用 map 创建全新的数组，确保触发 SwiftUI 更新
            let targetId = profile.id
            let newProfiles = profiles.map { p in
                var updated = p
                updated.isActive = (p.id == targetId)
                return updated
            }

            profiles = newProfiles

            // 触发 UI 刷新
            refreshUI?()

            statusMessage = "已切换到 \(profile.name)"
        } catch {
            statusMessage = "切换失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 查询余额
    func queryBalance(for profile: Profile) async {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        statusMessage = "正在查询 \(profile.name) 的余额..."

        do {
            let balance = try await balanceService.queryBalance(config: profile)
            profiles[index].balanceInfo = balance
            statusMessage = "余额查询成功"
        } catch {
            statusMessage = "余额查询失败: \(error.localizedDescription)"
        }
    }

    /// 查询订阅信息
    func querySubscription(for profile: Profile) async {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }

        statusMessage = "正在查询 \(profile.name) 的订阅信息..."

        do {
            let subscription = try await subscriptionService.querySubscription(config: profile)
            profiles[index].subscriptionInfo = subscription
            statusMessage = "订阅信息查询成功"
        } catch {
            statusMessage = "订阅信息查询失败: \(error.localizedDescription)"
        }
    }

    /// 批量查询所有配置的余额
    func refreshAllBalances() async {
        statusMessage = "正在刷新所有余额..."

        let profilesToQuery = profiles.filter { $0.balanceApi != nil }

        for profile in profilesToQuery {
            guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { continue }

            do {
                let balance = try await balanceService.queryBalance(config: profile)
                profiles[index].balanceInfo = balance
            } catch {
                // 忽略单个查询的错误，继续查询其他配置
                continue
            }
        }

        statusMessage = "余额刷新完成"
    }

    /// 显示添加表单
    func showAddForm() {
        formViewModel = ProfileFormViewModel(delegate: self)
        showingForm = true
    }

    /// 显示编辑表单
    func editProfile(_ profile: Profile) {
        formViewModel = ProfileFormViewModel(profile: profile, delegate: self)
        showingForm = true
    }

    /// 删除配置
    func deleteProfile(_ profile: Profile) {
        do {
            try configService.deleteProfile(profile)
            profiles.removeAll { $0.id == profile.id }
            statusMessage = "已删除 \(profile.name)"
        } catch {
            statusMessage = "删除失败: \(error.localizedDescription)"
        }
    }

    /// 刷新
    func refresh() async {
        await loadProfiles()
    }
}

// MARK: - ProfileFormDelegate
extension MainViewModel: ProfileFormDelegate {
    func didSaveProfile(_ profile: Profile, isNew: Bool) {
        do {
            if isNew {
                try configService.addProfile(profile)
            } else {
                try configService.updateProfile(profile)
            }

            Task {
                await loadProfiles()
            }

            statusMessage = isNew ? "已添加 \(profile.name)" : "已更新 \(profile.name)"
        } catch {
            statusMessage = "保存失败: \(error.localizedDescription)"
        }

        showingForm = false
    }

    func didCancelForm() {
        showingForm = false
    }
}
