//
//  PathHelper.swift
//  APISwitcher
//
//  路径处理工具
//

import Foundation

class PathHelper {
    /// 获取 app_profiles.json 路径（优先使用应用支持目录）
    static func getProfilesPath() -> URL {
        let fileManager = FileManager.default

        // 首先尝试应用支持目录
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appDir = appSupport.appendingPathComponent("APISwitcher", isDirectory: true)

            // 确保目录存在
            try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)

            let profilesPath = appDir.appendingPathComponent("app_profiles.json")

            // 如果文件不存在，尝试从 Bundle 复制示例文件
            if !fileManager.fileExists(atPath: profilesPath.path) {
                copyExampleProfilesIfNeeded(to: profilesPath)
            }

            return profilesPath
        }

        // 降级到用户主目录
        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".apiswitcher/app_profiles.json")
    }

    /// 获取 Claude 设置路径
    static func getClaudeSettingsPath() -> URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }

    /// 从 Bundle 复制示例配置文件
    private static func copyExampleProfilesIfNeeded(to destination: URL) {
        guard let examplePath = Bundle.main.url(forResource: "app_profiles.example", withExtension: "json") else {
            // 如果 Bundle 中没有示例文件，创建空数组
            let emptyProfiles = "[]"
            try? emptyProfiles.write(to: destination, atomically: true, encoding: .utf8)
            return
        }

        try? FileManager.default.copyItem(at: examplePath, to: destination)
    }

    /// 确保文件所在目录存在
    static func ensureDirectoryExists(for fileURL: URL) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// 从 URL 提取域名
    static func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return ""
        }
        return host
    }
}
