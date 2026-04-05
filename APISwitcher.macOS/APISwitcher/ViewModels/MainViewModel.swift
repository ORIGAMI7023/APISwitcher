//
//  MainViewModel.swift
//  APISwitcher
//
//  主窗口 ViewModel

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
        // 移除已选中检查，允许强制重新写入
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

    /// 打开配置文件
    func openConfigFile() {
        do {
            try configService.openFileWithDefaultEditor(configService.appProfilesPath)
            statusMessage = "已打开配置文件"
        } catch {
            statusMessage = "打开文件失败: \(error.localizedDescription)"
        }
    }

    /// 打开 Claude 设置文件
    func openClaudeSettingsFile() {
        do {
            try configService.openFileWithDefaultEditor(configService.settingsPath)
            statusMessage = "已打开 Claude 设置文件"
        } catch {
            statusMessage = "打开文件失败: \(error.localizedDescription)"
        }
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
