using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using APISwitcher.Models;

namespace APISwitcher.Services;

/// <summary>
/// 余额查询服务
/// </summary>
public class BalanceService : IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly JsonSerializerOptions _jsonOptions;

    public BalanceService()
    {
        _httpClient = new HttpClient();
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        };
    }

    /// <summary>
    /// 查询Profile的余额
    /// </summary>
    public async Task<BalanceInfo> QueryBalanceAsync(Profile profile)
    {
        // 检查是否配置了余额API（在最开始检查，避免创建不必要的对象）
        if (profile.BalanceApi == null)
        {
            throw new InvalidOperationException("未配置余额API");
        }

        // 获取当前的 BalanceInfo（如果存在），保留历史状态
        var balanceInfo = profile.BalanceInfo ?? new BalanceInfo { IsFirstLoad = true };
        balanceInfo.IsLoading = true;

        try
        {

            // 从Profile的Settings中获取环境变量
            var token = GetTokenFromSettings(profile.Settings);
            var baseUrl = GetBaseUrlFromSettings(profile.Settings);

            if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(baseUrl))
            {
                balanceInfo.HasError = true;
                balanceInfo.ErrorMessage = "缺少认证信息";
                balanceInfo.IsLoading = false;
                return balanceInfo;
            }

            // 构建完整URL
            var fullUrl = CombineUrl(baseUrl, profile.BalanceApi.Endpoint);

            // 创建请求
            using var request = CreateHttpRequest(profile.BalanceApi, token, fullUrl);

            // 设置超时
            using var cts = new CancellationTokenSource(profile.BalanceApi.Timeout);

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

            // 计算余额（返回 long）
            var rawBalance = CalculateBalance(jsonNode, profile.BalanceApi);
            decimal balance = rawBalance;

            // 应用除数进行单位转换（使用 decimal 保证精度）
            if (profile.BalanceApi.Divisor > 0 && profile.BalanceApi.Divisor != 1.0)
            {
                balance = balance / (decimal)profile.BalanceApi.Divisor;
            }

            var isUnlimited = false;

            if (!string.IsNullOrEmpty(profile.BalanceApi.UnlimitedField))
            {
                try
                {
                    isUnlimited = ExtractValue<bool>(jsonNode, profile.BalanceApi.UnlimitedField);
                }
                catch
                {
                    // 如果提取失败，默认为false
                    isUnlimited = false;
                }
            }

            // 查询成功，更新余额信息
            balanceInfo.Balance = balance;
            balanceInfo.IsUnlimited = isUnlimited;
            balanceInfo.DisplayUnit = profile.BalanceApi.DisplayUnit;
            balanceInfo.HasError = false;
            balanceInfo.FailureCount = 0;  // 重置失败计数
            balanceInfo.LastSuccessBalance = balance;  // 保存成功的余额
            balanceInfo.IsFirstLoad = false;  // 标记已完成首次加载
        }
        catch (OperationCanceledException)
        {
            balanceInfo.HasError = true;
            balanceInfo.ErrorMessage = "请求超时";
            balanceInfo.FailureCount++;  // 增加失败计数
        }
        catch (HttpRequestException ex)
        {
            balanceInfo.HasError = true;
            balanceInfo.ErrorMessage = $"网络错误: {ex.Message}";
            balanceInfo.FailureCount++;  // 增加失败计数
        }
        catch (Exception ex)
        {
            balanceInfo.HasError = true;
            balanceInfo.ErrorMessage = $"查询失败: {ex.Message}";
            balanceInfo.FailureCount++;  // 增加失败计数
        }
        finally
        {
            balanceInfo.IsLoading = false;
        }

        return balanceInfo;
    }

    /// <summary>
    /// 计算余额
    /// </summary>
    private long CalculateBalance(JsonNode jsonNode, BalanceApiConfig apiConfig)
    {
        // 优先使用 balanceField
        if (!string.IsNullOrEmpty(apiConfig.BalanceField))
        {
            return ExtractValue<long>(jsonNode, apiConfig.BalanceField);
        }

        // 如果没有 balanceField，则使用 limitField - usedField
        if (!string.IsNullOrEmpty(apiConfig.LimitField) && !string.IsNullOrEmpty(apiConfig.UsedField))
        {
            var limit = ExtractValue<long>(jsonNode, apiConfig.LimitField);
            var used = ExtractValue<long>(jsonNode, apiConfig.UsedField);
            return limit - used;
        }

        throw new Exception("未配置有效的余额字段（balanceField 或 limitField+usedField）");
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
    private HttpRequestMessage CreateHttpRequest(BalanceApiConfig apiConfig, string token, string url)
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

        return request;
    }

    /// <summary>
    /// 从JSON中提取指定路径的值
    /// </summary>
    private T ExtractValue<T>(JsonNode jsonNode, string path)
    {
        var parts = path.Split('.');
        JsonNode? current = jsonNode;

        foreach (var part in parts)
        {
            if (current is JsonObject obj)
            {
                current = obj[part];
            }
            else
            {
                throw new Exception($"无法找到路径: {path}");
            }
        }

        if (current == null)
        {
            throw new Exception($"路径 {path} 的值为null");
        }

        // 根据类型转换
        if (typeof(T) == typeof(long))
        {
            return (T)(object)current.GetValue<long>();
        }
        else if (typeof(T) == typeof(bool))
        {
            return (T)(object)current.GetValue<bool>();
        }
        else if (typeof(T) == typeof(string))
        {
            return (T)(object)(current.GetValue<string>() ?? string.Empty);
        }

        throw new NotSupportedException($"不支持的类型: {typeof(T)}");
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}
