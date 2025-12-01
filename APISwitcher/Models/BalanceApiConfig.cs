using System.Text.Json.Serialization;

namespace APISwitcher.Models;

/// <summary>
/// 余额API配置
/// </summary>
public class BalanceApiConfig
{
    /// <summary>
    /// API端点URL（相对于BaseUrl）
    /// 例如："/api/token/query" 或 "/api/usage/token"
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
    /// - header: 使用 Authorization: Bearer {token}
    /// - body: 在请求体中发送 {"token": "{token}"}
    /// - cookie: 使用 Cookie header 认证（需要配置 sessionCookie）
    /// </summary>
    [JsonPropertyName("authType")]
    public string AuthType { get; set; } = "header";

    /// <summary>
    /// Session Cookie（当 authType 为 cookie 时使用）
    /// 例如："session=MTc2NDQ4OTIzN3x..."
    /// </summary>
    [JsonPropertyName("sessionCookie")]
    public string? SessionCookie { get; set; }

    /// <summary>
    /// 额外的 HTTP Headers（当 authType 为 cookie 时可能需要）
    /// 例如：{"new-api-user": "285", "origin": "https://example.com"}
    /// </summary>
    [JsonPropertyName("extraHeaders")]
    public Dictionary<string, string>? ExtraHeaders { get; set; }

    /// <summary>
    /// 响应中余额字段的路径（使用点号分隔）
    /// 例如："data.total_available"
    /// 如果不设置此字段，则使用 limitField 和 usedField 计算
    /// </summary>
    [JsonPropertyName("balanceField")]
    public string? BalanceField { get; set; }

    /// <summary>
    /// 响应中总额度字段的路径（用于计算型余额）
    /// 例如："data.total_usage_limit"
    /// </summary>
    [JsonPropertyName("limitField")]
    public string? LimitField { get; set; }

    /// <summary>
    /// 响应中已用额度字段的路径（用于计算型余额）
    /// 例如："data.total_usage_count"
    /// </summary>
    [JsonPropertyName("usedField")]
    public string? UsedField { get; set; }

    /// <summary>
    /// 响应中无限额度标志字段的路径
    /// 例如："data.unlimited_quota"
    /// </summary>
    [JsonPropertyName("unlimitedField")]
    public string? UnlimitedField { get; set; }

    /// <summary>
    /// 显示单位：usd（美元）/ cny（人民币）/ times（次数）
    /// </summary>
    [JsonPropertyName("displayUnit")]
    public string DisplayUnit { get; set; } = "usd";

    /// <summary>
    /// 请求超时时间（毫秒）
    /// </summary>
    [JsonPropertyName("timeout")]
    public int Timeout { get; set; } = 10000;

    /// <summary>
    /// 余额除数，用于单位转换
    /// 例如：500000 表示原始值需要除以500000
    /// 默认值为1（不转换）
    /// </summary>
    [JsonPropertyName("divisor")]
    public double Divisor { get; set; } = 1.0;
}
