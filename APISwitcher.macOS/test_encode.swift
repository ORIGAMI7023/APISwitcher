import Foundation

// 测试 ClaudeSettings 序列化
let settings = ClaudeSettings(
    claude: ClaudeSettings.ClaudeConfig(
        apiKey: "test-key",
        model: "claude-sonnet-4",
        baseURL: "https://api.test.com"
    ),
    mcpServers: nil
)

// 添加 env 等额外属性
var settingsDict: [String: Any] = settings.toDictionary()
settingsDict["env"] = [
    "ANTHROPIC_AUTH_TOKEN": "test-token",
    "ANTHROPIC_BASE_URL": "https://test.com"
]
settingsDict["alwaysThinkingEnabled"] = false

print("原始配置:")
print(settingsDict)

// 序列化测试
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let data = try encoder.encode(settings)
    print("\n序列化结果:")
    print(String(data: data, encoding: .utf8) ?? "")
} catch {
    print("序列化失败: \(error)")
}
