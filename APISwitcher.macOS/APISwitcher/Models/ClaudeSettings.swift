//
//  ClaudeSettings.swift
//  APISwitcher
//
//  Claude 配置模型，支持动态 JSON 属性
//

import Foundation

struct ClaudeSettings: Codable, Equatable, Sendable {
    var claude: ClaudeConfig?
    var mcpServers: [String: MCPServer]?

    // 动态存储其他未知属性
    private var additionalProperties: [String: AnyCodableValue] = [:]

    // 嵌套结构：Claude 配置
    struct ClaudeConfig: Codable, Equatable, Sendable {
        var apiKey: String?
        var model: String?
        var baseURL: String?
        var timeout: Int?

        // 动态属性
        private var extra: [String: AnyCodableValue] = [:]

        private enum CodingKeys: String, CodingKey {
            case apiKey, model, baseURL, timeout
        }

        init(apiKey: String? = nil, model: String? = nil, baseURL: String? = nil, timeout: Int? = nil) {
            self.apiKey = apiKey
            self.model = model
            self.baseURL = baseURL
            self.timeout = timeout
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

            for key in container.allKeys {
                switch key.stringValue {
                case "apiKey":
                    apiKey = try? container.decode(String.self, forKey: key)
                case "model":
                    model = try? container.decode(String.self, forKey: key)
                case "baseURL":
                    baseURL = try? container.decode(String.self, forKey: key)
                case "timeout":
                    timeout = try? container.decode(Int.self, forKey: key)
                default:
                    if let value = try? container.decode(AnyCodableValue.self, forKey: key) {
                        extra[key.stringValue] = value
                    }
                }
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicCodingKeys.self)

            if let apiKey = apiKey {
                try container.encode(apiKey, forKey: DynamicCodingKeys(stringValue: "apiKey")!)
            }
            if let model = model {
                try container.encode(model, forKey: DynamicCodingKeys(stringValue: "model")!)
            }
            if let baseURL = baseURL {
                try container.encode(baseURL, forKey: DynamicCodingKeys(stringValue: "baseURL")!)
            }
            if let timeout = timeout {
                try container.encode(timeout, forKey: DynamicCodingKeys(stringValue: "timeout")!)
            }

            for (key, value) in extra {
                try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        }

        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = [:]
            if let apiKey = apiKey { dict["apiKey"] = apiKey }
            if let model = model { dict["model"] = model }
            if let baseURL = baseURL { dict["baseURL"] = baseURL }
            if let timeout = timeout { dict["timeout"] = timeout }

            for (key, value) in extra {
                dict[key] = value.toAny()
            }

            return dict
        }
    }

    // MCP 服务器配置
    struct MCPServer: Codable, Equatable, Sendable {
        var command: String
        var args: [String]?
        var env: [String: String]?

        // 动态属性
        private var extra: [String: AnyCodableValue] = [:]

        private enum CodingKeys: String, CodingKey {
            case command, args, env
        }

        init(command: String, args: [String]? = nil, env: [String: String]? = nil) {
            self.command = command
            self.args = args
            self.env = env
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

            command = try container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "command")!)
            args = try? container.decode([String].self, forKey: DynamicCodingKeys(stringValue: "args")!)
            env = try? container.decode([String: String].self, forKey: DynamicCodingKeys(stringValue: "env")!)

            for key in container.allKeys where !["command", "args", "env"].contains(key.stringValue) {
                if let value = try? container.decode(AnyCodableValue.self, forKey: key) {
                    extra[key.stringValue] = value
                }
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicCodingKeys.self)

            try container.encode(command, forKey: DynamicCodingKeys(stringValue: "command")!)
            if let args = args {
                try container.encode(args, forKey: DynamicCodingKeys(stringValue: "args")!)
            }
            if let env = env {
                try container.encode(env, forKey: DynamicCodingKeys(stringValue: "env")!)
            }

            for (key, value) in extra {
                try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        }

        func toDictionary() -> [String: Any] {
            var dict: [String: Any] = ["command": command]
            if let args = args { dict["args"] = args }
            if let env = env { dict["env"] = env }

            for (key, value) in extra {
                dict[key] = value.toAny()
            }

            return dict
        }
    }

    private enum CodingKeys: String, CodingKey {
        case claude, mcpServers
    }

    init(claude: ClaudeConfig? = nil, mcpServers: [String: MCPServer]? = nil) {
        self.claude = claude
        self.mcpServers = mcpServers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        for key in container.allKeys {
            switch key.stringValue {
            case "claude":
                claude = try? container.decode(ClaudeConfig.self, forKey: key)
            case "mcpServers":
                mcpServers = try? container.decode([String: MCPServer].self, forKey: key)
            default:
                if let value = try? container.decode(AnyCodableValue.self, forKey: key) {
                    additionalProperties[key.stringValue] = value
                }
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)

        if let claude = claude {
            try container.encode(claude, forKey: DynamicCodingKeys(stringValue: "claude")!)
        }
        if let mcpServers = mcpServers {
            try container.encode(mcpServers, forKey: DynamicCodingKeys(stringValue: "mcpServers")!)
        }

        for (key, value) in additionalProperties {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }

    /// 转换为字典（用于 JSON 子集匹配）
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        if let claude = claude {
            dict["claude"] = claude.toDictionary()
        }

        if let mcpServers = mcpServers {
            dict["mcpServers"] = mcpServers.mapValues { $0.toDictionary() }
        }

        for (key, value) in additionalProperties {
            dict[key] = value.toAny()
        }

        return dict
    }
}

/// 动态编码键
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
