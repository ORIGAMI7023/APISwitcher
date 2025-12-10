using System.Text.Json.Serialization;

namespace APISwitcher.Models;

/// <summary>
/// 订阅API配置
/// </summary>
public class SubscriptionApiConfig
{
    /// <summary>
    /// API端点URL（相对于BaseUrl）
    /// 例如："/api/subscription/user/?p=0&size=10"
    /// </summary>
    [JsonPropertyName("endpoint")]
    public string Endpoint { get; set; } = string.Empty;

    /// <summary>
    /// HTTP方法：GET 或 POST
    /// </summary>
    [JsonPropertyName("method")]
    public string Method { get; set; } = "GET";

    /// <summary>
    /// 认证方式：header、body 或 cookie
    /// </summary>
    [JsonPropertyName("authType")]
    public string AuthType { get; set; } = "cookie";

    /// <summary>
    /// Session Cookie（当 authType 为 cookie 时使用）
    /// </summary>
    [JsonPropertyName("sessionCookie")]
    public string? SessionCookie { get; set; }

    /// <summary>
    /// 额外的 HTTP Headers（当 authType 为 cookie 时可能需要）
    /// </summary>
    [JsonPropertyName("extraHeaders")]
    public Dictionary<string, string>? ExtraHeaders { get; set; }

    /// <summary>
    /// 请求超时时间（毫秒）
    /// </summary>
    [JsonPropertyName("timeout")]
    public int Timeout { get; set; } = 10000;
}
