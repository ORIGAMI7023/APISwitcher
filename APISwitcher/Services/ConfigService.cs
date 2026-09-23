using System.IO;
using System.Text.Json;
using System.Diagnostics;
using APISwitcher.Models;

namespace APISwitcher.Services;

public class ConfigService
{
    private readonly string _appProfilesPath;
    private readonly string _claudeSettingsPath;
    private readonly JsonSerializerOptions _jsonOptions;

    public ConfigService()
    {
        _appProfilesPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "app_profiles.json");
        _claudeSettingsPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".claude",
            "settings.json"
        );

        _jsonOptions = new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNameCaseInsensitive = true
        };
    }

    public string AppProfilesPath => _appProfilesPath;
    public string ClaudeSettingsPath => _claudeSettingsPath;

    /// <summary>
    /// 使用默认编辑器打开配置文件
    /// </summary>
    /// <param name="path">文件路径</param>
    public void OpenFileWithDefaultEditor(string path)
    {
        try
        {
            if (!File.Exists(path))
            {
                var directory = Path.GetDirectoryName(path);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                if (Path.GetFileName(path).Equals("settings.json", StringComparison.OrdinalIgnoreCase))
                {
                    File.WriteAllText(path, "{}\n");
                }
                else if (Path.GetFileName(path).Equals("app_profiles.json", StringComparison.OrdinalIgnoreCase))
                {
                    var examplePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "app_profiles.json.example");
                    if (File.Exists(examplePath))
                    {
                        File.Copy(examplePath, path, true);
                    }
                    else
                    {
                        File.WriteAllText(path, "[]\n");
                    }
                }
                else
                {
                    throw new FileNotFoundException($"配置文件不存在: {path}");
                }
            }

            // 使用 Process.Start 打开文件，系统会自动使用默认编辑器
            Process.Start(new ProcessStartInfo
            {
                FileName = path,
                UseShellExecute = true
            });
        }
        catch (Exception ex)
        {
            throw new Exception($"打开文件失败: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 加载配置列表
    /// </summary>
    public async Task<List<Profile>> LoadProfilesAsync()
    {
        try
        {
            if (!File.Exists(_appProfilesPath))
            {
                var examplePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "app_profiles.json.example");
                if (File.Exists(examplePath))
                {
                    File.Copy(examplePath, _appProfilesPath, true);
                }
                else
                {
                    return new List<Profile>();
                }
            }

            var json = await File.ReadAllTextAsync(_appProfilesPath);
            var profiles = JsonSerializer.Deserialize<List<Profile>>(json, _jsonOptions);
            return profiles ?? new List<Profile>();
        }
        catch (Exception ex)
        {
            throw new Exception($"加载配置文件失败: {ex.Message}", ex);
        }
    }

    public async Task<ClaudeSettings?> LoadClaudeSettingsAsync()
    {
        try
        {
            if (!File.Exists(_claudeSettingsPath))
            {
                return null;
            }

            var json = await File.ReadAllTextAsync(_claudeSettingsPath);
            return JsonSerializer.Deserialize<ClaudeSettings>(json, _jsonOptions);
        }
        catch (Exception ex)
        {
            throw new Exception($"读取 Claude 配置失败: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 判断配置是否为官方配置（没有自定义 env）
    /// </summary>
    public bool IsOfficialProfile(Profile profile)
    {
        if (profile.Settings.ExtensionData == null)
        {
            return true;
        }

        // 检查 settings.env 格式（新格式）
        if (profile.Settings.ExtensionData.TryGetValue("env", out var envElement) &&
            envElement.ValueKind == JsonValueKind.Object)
        {
            var hasBaseUrl = envElement.TryGetProperty("ANTHROPIC_BASE_URL", out var baseUrl) &&
                             !string.IsNullOrEmpty(baseUrl.GetString());
            var hasAuthToken = envElement.TryGetProperty("ANTHROPIC_AUTH_TOKEN", out var authToken) &&
                               !string.IsNullOrEmpty(authToken.GetString());
            if (hasBaseUrl || hasAuthToken)
            {
                return false;
            }
        }

        // 检查 settings 顶层属性格式（旧格式）
        var hasTopLevelBaseUrl = profile.Settings.ExtensionData.TryGetValue("ANTHROPIC_BASE_URL", out var topLevelBaseUrl) &&
                                 topLevelBaseUrl.ValueKind == JsonValueKind.String &&
                                 !string.IsNullOrEmpty(topLevelBaseUrl.GetString());
        var hasTopLevelAuthToken = profile.Settings.ExtensionData.TryGetValue("ANTHROPIC_AUTH_TOKEN", out var topLevelAuthToken) &&
                                   topLevelAuthToken.ValueKind == JsonValueKind.String &&
                                   !string.IsNullOrEmpty(topLevelAuthToken.GetString());

        return !hasTopLevelBaseUrl && !hasTopLevelAuthToken;
    }

    /// <summary>
    /// 为非官方配置注入 CLAUDE_CODE_ATTRIBUTION_HEADER 环境变量
    /// </summary>
    public ClaudeSettings InjectAttributionHeader(ClaudeSettings settings)
    {
        if (settings.ExtensionData == null)
        {
            return settings;
        }

        // 深拷贝 settings 以避免修改原始对象
        var json = JsonSerializer.Serialize(settings, _jsonOptions);
        var dict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(json, _jsonOptions);
        if (dict == null)
        {
            return settings;
        }

        // 新格式：env 对象存在
        if (dict.TryGetValue("env", out var envElement) && envElement.ValueKind == JsonValueKind.Object)
        {
            var envDict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(envElement.GetRawText(), _jsonOptions);
            if (envDict != null)
            {
                envDict["CLAUDE_CODE_ATTRIBUTION_HEADER"] = JsonSerializer.SerializeToElement("0", _jsonOptions);
                dict["env"] = JsonSerializer.SerializeToElement(envDict, _jsonOptions);
            }
        }
        // 旧格式：ANTHROPIC_BASE_URL 或 ANTHROPIC_AUTH_TOKEN 直接作为顶层属性
        else if (dict.ContainsKey("ANTHROPIC_BASE_URL") || dict.ContainsKey("ANTHROPIC_AUTH_TOKEN"))
        {
            dict["CLAUDE_CODE_ATTRIBUTION_HEADER"] = JsonSerializer.SerializeToElement("0");
        }
        else
        {
            return settings;
        }

        var newJson = JsonSerializer.Serialize(dict, _jsonOptions);
        return JsonSerializer.Deserialize<ClaudeSettings>(newJson, _jsonOptions) ?? settings;
    }

    public async Task SaveClaudeSettingsAsync(ClaudeSettings settings)
    {
        try
        {
            var directory = Path.GetDirectoryName(_claudeSettingsPath);
            if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            // 读取已存在的 settings.json，保留用户原有的非 API 配置（如 permissions、hooks、mcpServers 等）
            var finalDict = new Dictionary<string, JsonElement>();
            if (File.Exists(_claudeSettingsPath))
            {
                try
                {
                    var existingJson = await File.ReadAllTextAsync(_claudeSettingsPath);
                    var existingDict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(existingJson, _jsonOptions);
                    if (existingDict != null)
                    {
                        finalDict = existingDict;
                    }
                }
                catch
                {
                    // 现有文件解析异常则直接使用新设置
                }
            }

            // 将新设置序列化为字典进行合并
            var newSettingsJson = JsonSerializer.Serialize(settings, _jsonOptions);
            var newSettingsDict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(newSettingsJson, _jsonOptions);
            if (newSettingsDict != null)
            {
                // 如果切换的目标配置没有 env，清理原有的 API 环境变量
                if (!newSettingsDict.ContainsKey("env"))
                {
                    finalDict.Remove("env");
                }

                // 清理顶层可能存在的旧版 API 键，避免干扰
                finalDict.Remove("ANTHROPIC_AUTH_TOKEN");
                finalDict.Remove("ANTHROPIC_BASE_URL");
                finalDict.Remove("ANTHROPIC_MODEL");
                finalDict.Remove("ANTHROPIC_DEFAULT_HAIKU_MODEL");
                finalDict.Remove("ANTHROPIC_DEFAULT_SONNET_MODEL");
                finalDict.Remove("ANTHROPIC_DEFAULT_OPUS_MODEL");

                foreach (var kvp in newSettingsDict)
                {
                    finalDict[kvp.Key] = kvp.Value;
                }
            }

            var json = JsonSerializer.Serialize(finalDict, _jsonOptions);
            await File.WriteAllTextAsync(_claudeSettingsPath, json);
        }
        catch (Exception ex)
        {
            throw new Exception($"保存 Claude 配置失败: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 保存配置列表到文件
    /// </summary>
    public async Task SaveProfilesAsync(List<Profile> profiles)
    {
        try
        {
            var json = JsonSerializer.Serialize(profiles, _jsonOptions);
            await File.WriteAllTextAsync(_appProfilesPath, json);
        }
        catch (Exception ex)
        {
            throw new Exception($"保存配置文件失败: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 添加新配置
    /// </summary>
    public async Task AddProfileAsync(Profile newProfile)
    {
        try
        {
            var profiles = await LoadProfilesAsync();

            // 检查名称是否重复
            if (profiles.Any(p => p.Name.Equals(newProfile.Name, StringComparison.OrdinalIgnoreCase)))
            {
                throw new Exception($"配置名称 '{newProfile.Name}' 已存在");
            }

            profiles.Add(newProfile);
            await SaveProfilesAsync(profiles);
        }
        catch (Exception ex)
        {
            throw new Exception($"添加配置失败: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 更新配置
    /// </summary>
    public async Task UpdateProfileAsync(string oldName, Profile updatedProfile)
    {
        try
        {
            var profiles = await LoadProfilesAsync();
            var index = profiles.FindIndex(p => p.Name.Equals(oldName, StringComparison.OrdinalIgnoreCase));

            if (index < 0)
            {
                throw new Exception($"配置 '{oldName}' 不存在");
            }

            // 如果修改了名称，检查新名称是否与其他配置重复（排除当前正在编辑的项自身，支持大小写修改）
            if (!oldName.Equals(updatedProfile.Name, StringComparison.Ordinal))
            {
                if (profiles.Where((p, i) => i != index).Any(p => p.Name.Equals(updatedProfile.Name, StringComparison.OrdinalIgnoreCase)))
                {
                    throw new Exception($"配置名称 '{updatedProfile.Name}' 已存在");
                }
            }

            // 保留 IsActive 状态
            updatedProfile.IsActive = profiles[index].IsActive;
            profiles[index] = updatedProfile;

            await SaveProfilesAsync(profiles);
        }
        catch (Exception ex)
        {
            throw new Exception($"更新配置失败: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 删除配置
    /// </summary>
    public async Task DeleteProfileAsync(string profileName)
    {
        try
        {
            var profiles = await LoadProfilesAsync();

            if (profiles.Count <= 1)
            {
                throw new Exception("不能删除最后一个配置");
            }

            var profileToDelete = profiles.FirstOrDefault(p => p.Name.Equals(profileName, StringComparison.OrdinalIgnoreCase));
            if (profileToDelete == null)
            {
                throw new Exception($"配置 '{profileName}' 不存在");
            }

            profiles.Remove(profileToDelete);
            await SaveProfilesAsync(profiles);
        }
        catch (Exception ex)
        {
            throw new Exception($"删除配置失败: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 从设置中提取 BaseUrl 和 AuthToken（兼容 env 格式与顶层属性格式）
    /// </summary>
    public (string baseUrl, string authToken) ExtractKeyCredentials(ClaudeSettings? settings)
    {
        if (settings?.ExtensionData == null)
        {
            return (string.Empty, string.Empty);
        }

        string baseUrl = string.Empty;
        string authToken = string.Empty;

        // 优先检查 env 对象
        if (settings.ExtensionData.TryGetValue("env", out var envElement) &&
            envElement.ValueKind == JsonValueKind.Object)
        {
            if (envElement.TryGetProperty("ANTHROPIC_BASE_URL", out var b) && b.ValueKind == JsonValueKind.String)
            {
                baseUrl = b.GetString() ?? string.Empty;
            }
            if (envElement.TryGetProperty("ANTHROPIC_AUTH_TOKEN", out var a) && a.ValueKind == JsonValueKind.String)
            {
                authToken = a.GetString() ?? string.Empty;
            }
        }

        // 兼容顶层属性
        if (string.IsNullOrEmpty(baseUrl) &&
            settings.ExtensionData.TryGetValue("ANTHROPIC_BASE_URL", out var topBaseUrl) &&
            topBaseUrl.ValueKind == JsonValueKind.String)
        {
            baseUrl = topBaseUrl.GetString() ?? string.Empty;
        }

        if (string.IsNullOrEmpty(authToken) &&
            settings.ExtensionData.TryGetValue("ANTHROPIC_AUTH_TOKEN", out var topAuthToken) &&
            topAuthToken.ValueKind == JsonValueKind.String)
        {
            authToken = topAuthToken.GetString() ?? string.Empty;
        }

        return (baseUrl, authToken);
    }

    public bool IsProfileActive(Profile profile, ClaudeSettings? currentSettings)
    {
        var (currentBaseUrl, currentAuthToken) = ExtractKeyCredentials(currentSettings);
        var (profileBaseUrl, profileAuthToken) = ExtractKeyCredentials(profile.Settings);

        bool isProfileOfficial = string.IsNullOrEmpty(profileBaseUrl) && string.IsNullOrEmpty(profileAuthToken);
        bool isCurrentOfficial = string.IsNullOrEmpty(currentBaseUrl) && string.IsNullOrEmpty(currentAuthToken);

        if (isProfileOfficial)
        {
            // 官方配置：当当前环境也没有自定义 baseUrl 和 authToken 时视为激活
            return isCurrentOfficial;
        }

        if (isCurrentOfficial)
        {
            return false;
        }

        // 非官方配置：优先比对关键凭据 BaseUrl 和 AuthToken
        if (!string.IsNullOrEmpty(profileBaseUrl) && !string.IsNullOrEmpty(profileAuthToken))
        {
            return profileBaseUrl == currentBaseUrl && profileAuthToken == currentAuthToken;
        }

        // 回退到子集匹配
        if (currentSettings?.ExtensionData == null || profile.Settings.ExtensionData == null || profile.Settings.ExtensionData.Count == 0)
        {
            return false;
        }

        foreach (var kvp in profile.Settings.ExtensionData)
        {
            if (!currentSettings.ExtensionData.TryGetValue(kvp.Key, out var currentValue))
            {
                return false;
            }

            if (!IsJsonSubset(kvp.Value, currentValue))
            {
                return false;
            }
        }

        return true;
    }

    public void UpdateActiveStatus(List<Profile> profiles, ClaudeSettings? currentSettings)
    {
        // 首先重置所有配置的激活状态
        foreach (var profile in profiles)
        {
            profile.IsActive = false;
        }

        // 找出所有匹配的配置及其匹配程度（设置项数量）
        var matchedProfiles = profiles
            .Where(p => IsProfileActive(p, currentSettings))
            .Select(p => new
            {
                Profile = p,
                MatchScore = CountSettingsKeys(p.Settings.ExtensionData)
            })
            .ToList();

        if (matchedProfiles.Count > 0)
        {
            var maxScore = matchedProfiles.Max(m => m.MatchScore);
            var bestMatches = matchedProfiles.Where(m => m.MatchScore == maxScore).ToList();

            // 只有当最高得分配置唯一时标记为激活
            if (bestMatches.Count == 1)
            {
                bestMatches[0].Profile.IsActive = true;
            }
            else
            {
                // 如果得分相同，检查是否有且仅有一个与当前 BaseUrl 和 AuthToken 完全一致的非空配置
                var (currentBaseUrl, currentAuthToken) = ExtractKeyCredentials(currentSettings);
                if (!string.IsNullOrEmpty(currentBaseUrl) && !string.IsNullOrEmpty(currentAuthToken))
                {
                    var exactMatches = bestMatches.Where(m =>
                    {
                        var (b, a) = ExtractKeyCredentials(m.Profile.Settings);
                        return b == currentBaseUrl && a == currentAuthToken;
                    }).ToList();

                    if (exactMatches.Count == 1)
                    {
                        exactMatches[0].Profile.IsActive = true;
                    }
                }
            }
        }
    }

    /// <summary>
    /// 递归计算设置中的键数量，用于确定匹配程度
    /// </summary>
    private int CountSettingsKeys(Dictionary<string, JsonElement>? extensionData)
    {
        if (extensionData == null)
        {
            return 0;
        }

        int count = 0;
        foreach (var kvp in extensionData)
        {
            count += CountJsonElementKeys(kvp.Value);
        }
        return count;
    }

    private int CountJsonElementKeys(JsonElement element)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Object:
                int count = 0;
                foreach (var prop in element.EnumerateObject())
                {
                    count += 1 + CountJsonElementKeys(prop.Value);
                }
                return count;

            case JsonValueKind.Array:
                int arrayCount = 0;
                foreach (var item in element.EnumerateArray())
                {
                    arrayCount += CountJsonElementKeys(item);
                }
                return arrayCount;

            default:
                return 1;
        }
    }

    private bool IsJsonSubset(JsonElement subset, JsonElement superset)
    {
        if (subset.ValueKind != superset.ValueKind)
        {
            return false;
        }

        switch (subset.ValueKind)
        {
            case JsonValueKind.Object:
                foreach (var subProperty in subset.EnumerateObject())
                {
                    if (!superset.TryGetProperty(subProperty.Name, out var superProperty))
                {
                    return false;
                }

                    if (!IsJsonSubset(subProperty.Value, superProperty))
                    {
                        return false;
                    }
                }
                return true;

            case JsonValueKind.Array:
                if (subset.GetArrayLength() != superset.GetArrayLength())
                {
                    return false;
                }

                var subEnumerator = subset.EnumerateArray();
                var superEnumerator = superset.EnumerateArray();

                while (subEnumerator.MoveNext() && superEnumerator.MoveNext())
                {
                    if (!IsJsonSubset(subEnumerator.Current, superEnumerator.Current))
                    {
                        return false;
                    }
                }
                return true;

            case JsonValueKind.String:
                return subset.GetString() == superset.GetString();

            case JsonValueKind.Number:
            case JsonValueKind.True:
            case JsonValueKind.False:
            case JsonValueKind.Null:
            case JsonValueKind.Undefined:
            default:
                // 对于原子值，使用原始文本避免精度丢失
                return subset.GetRawText() == superset.GetRawText();
        }
    }
}
