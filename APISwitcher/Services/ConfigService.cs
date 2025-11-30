using System.IO;
using System.Text.Json;
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

    public async Task<List<Profile>> LoadProfilesAsync()
    {
        try
        {
            if (!File.Exists(_appProfilesPath))
            {
                return new List<Profile>();
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

    public async Task SaveClaudeSettingsAsync(ClaudeSettings settings)
    {
        try
        {
            var directory = Path.GetDirectoryName(_claudeSettingsPath);
            if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            var json = JsonSerializer.Serialize(settings, _jsonOptions);
            await File.WriteAllTextAsync(_claudeSettingsPath, json);
        }
        catch (Exception ex)
        {
            throw new Exception($"保存 Claude 配置失败: {ex.Message}", ex);
        }
    }

    public bool IsProfileActive(Profile profile, ClaudeSettings? currentSettings)
    {
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

        if (currentSettings?.ExtensionData == null)
        {
            return;
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

        // 只选择匹配程度最高的配置作为激活配置
        // 如果有多个配置得分相同，则都不激活（避免歧义）
        if (matchedProfiles.Count > 0)
        {
            var maxScore = matchedProfiles.Max(m => m.MatchScore);
            var bestMatches = matchedProfiles.Where(m => m.MatchScore == maxScore).ToList();

            // 只有当最高得分配置唯一时才标记为激活
            if (bestMatches.Count == 1)
            {
                bestMatches[0].Profile.IsActive = true;
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
