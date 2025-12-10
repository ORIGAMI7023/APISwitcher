using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using APISwitcher.Models;

namespace APISwitcher.Services;

/// <summary>
/// 订阅查询服务
/// </summary>
public class SubscriptionService : IDisposable
{
    private readonly HttpClient _httpClient;

    public SubscriptionService()
    {
        _httpClient = new HttpClient();
    }

    /// <summary>
    /// 查询Profile的订阅信息
    /// </summary>
    public async Task<SubscriptionInfo> QuerySubscriptionAsync(Profile profile)
    {
        if (profile.SubscriptionApi == null)
        {
            throw new InvalidOperationException("未配置订阅API");
        }

        var subscriptionInfo = profile.SubscriptionInfo ?? new SubscriptionInfo();
        subscriptionInfo.IsLoading = true;

        try
        {
            var token = GetTokenFromSettings(profile.Settings);
            var baseUrl = GetBaseUrlFromSettings(profile.Settings);

            // Cookie认证不需要token
            if (profile.SubscriptionApi.AuthType.ToLower() != "cookie")
            {
                if (string.IsNullOrEmpty(token))
                {
                    subscriptionInfo.HasError = true;
                    subscriptionInfo.ErrorMessage = "缺少认证 Token";
                    subscriptionInfo.IsLoading = false;
                    return subscriptionInfo;
                }
            }

            if (string.IsNullOrEmpty(baseUrl))
            {
                subscriptionInfo.HasError = true;
                subscriptionInfo.ErrorMessage = "缺少 BaseUrl";
                subscriptionInfo.IsLoading = false;
                return subscriptionInfo;
            }

            // 构建完整URL
            var fullUrl = CombineUrl(baseUrl, profile.SubscriptionApi.Endpoint);

            // 创建请求
            using var request = CreateHttpRequest(profile.SubscriptionApi, token, fullUrl);

            // 设置超时
            using var cts = new CancellationTokenSource(profile.SubscriptionApi.Timeout);

            // 发送请求
            var response = await _httpClient.SendAsync(request, cts.Token);
            response.EnsureSuccessStatusCode();

            // 解析响应
            var responseBody = await response.Content.ReadAsStringAsync();
            var jsonNode = JsonNode.Parse(responseBody);

            if (jsonNode == null)
            {
                throw new Exception("响应内容为空");
            }

            // 提取数据：data.items[0]
            var item = jsonNode["data"]?["items"]?[0];
            if (item == null)
            {
                throw new Exception("未找到订阅数据");
            }

            var subscriptionInfoNode = item["subscription_info"];
            if (subscriptionInfoNode == null)
            {
                throw new Exception("未找到订阅详情");
            }

            // 提取各个字段
            subscriptionInfo.DailyQuotaLimit = subscriptionInfoNode["daily_quota_limit"]?.GetValue<long>() ?? 0;
            subscriptionInfo.DailyQuotaUsed = item["daily_quota_used"]?.GetValue<long>() ?? 0;
            subscriptionInfo.WeeklyQuotaLimit = subscriptionInfoNode["weekly_quota_limit"]?.GetValue<long>() ?? 0;
            subscriptionInfo.WeeklyQuotaUsed = item["weekly_quota_used"]?.GetValue<long>() ?? 0;
            subscriptionInfo.TotalQuotaLimit = subscriptionInfoNode["total_quota_limit"]?.GetValue<long>() ?? 0;
            subscriptionInfo.TotalQuotaUsed = item["total_quota_used"]?.GetValue<long>() ?? 0;
            subscriptionInfo.ExpireTime = item["expire_time"]?.GetValue<long>() ?? 0;

            subscriptionInfo.HasError = false;
        }
        catch (OperationCanceledException)
        {
            subscriptionInfo.HasError = true;
            subscriptionInfo.ErrorMessage = "请求超时";
        }
        catch (HttpRequestException ex)
        {
            subscriptionInfo.HasError = true;
            subscriptionInfo.ErrorMessage = $"网络错误: {ex.Message}";
        }
        catch (Exception ex)
        {
            subscriptionInfo.HasError = true;
            subscriptionInfo.ErrorMessage = $"查询失败: {ex.Message}";
        }
        finally
        {
            subscriptionInfo.IsLoading = false;
        }

        return subscriptionInfo;
    }

    /// <summary>
    /// 从Settings中提取Token
    /// </summary>
    private string? GetTokenFromSettings(ClaudeSettings settings)
    {
        if (settings.ExtensionData?.TryGetValue("env", out var envElement) == true)
        {
            if (envElement.ValueKind == JsonValueKind.Object)
            {
                if (envElement.TryGetProperty("ANTHROPIC_AUTH_TOKEN", out var tokenElement))
                {
                    return tokenElement.GetString();
                }
            }
        }
        return null;
    }

    /// <summary>
    /// 从Settings中提取BaseUrl
    /// </summary>
    private string? GetBaseUrlFromSettings(ClaudeSettings settings)
    {
        if (settings.ExtensionData?.TryGetValue("env", out var envElement) == true)
        {
            if (envElement.ValueKind == JsonValueKind.Object)
            {
                if (envElement.TryGetProperty("ANTHROPIC_BASE_URL", out var baseUrlElement))
                {
                    return baseUrlElement.GetString();
                }
            }
        }
        return null;
    }

    /// <summary>
    /// 组合URL
    /// </summary>
    private string CombineUrl(string baseUrl, string endpoint)
    {
        baseUrl = baseUrl.TrimEnd('/');
        endpoint = endpoint.TrimStart('/');
        return $"{baseUrl}/{endpoint}";
    }

    /// <summary>
    /// 创建HTTP请求
    /// </summary>
    private HttpRequestMessage CreateHttpRequest(SubscriptionApiConfig apiConfig, string? token, string url)
    {
        var method = apiConfig.Method.ToUpper() == "POST" ? HttpMethod.Post : HttpMethod.Get;
        var request = new HttpRequestMessage(method, url);

        if (apiConfig.AuthType.ToLower() == "header")
        {
            // 使用Header认证：Authorization: Bearer {token}
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
        else if (apiConfig.AuthType.ToLower() == "body")
        {
            // 使用Body认证：{"token": "{token}"}
            var bodyContent = new { token };
            request.Content = JsonContent.Create(bodyContent);
        }
        else if (apiConfig.AuthType.ToLower() == "cookie")
        {
            // 使用Cookie认证
            if (!string.IsNullOrEmpty(apiConfig.SessionCookie))
            {
                request.Headers.Add("Cookie", apiConfig.SessionCookie);
            }

            // 添加额外的headers
            if (apiConfig.ExtraHeaders != null)
            {
                foreach (var header in apiConfig.ExtraHeaders)
                {
                    request.Headers.Add(header.Key, header.Value);
                }
            }
        }

        return request;
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}
