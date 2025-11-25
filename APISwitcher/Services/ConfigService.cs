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
        foreach (var profile in profiles)
        {
            profile.IsActive = IsProfileActive(profile, currentSettings);
        }

        // 如果当前 settings.json 有内容但未匹配到任何 profile，我们保持全部为未激活状态，避免误标。
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
