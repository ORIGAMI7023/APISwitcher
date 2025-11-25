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
            WriteIndented = true
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
        if (currentSettings == null || currentSettings.ExtensionData == null || profile.Settings.ExtensionData == null)
        {
            return false;
        }

        // 比较两个字典的内容是否相同
        if (currentSettings.ExtensionData.Count != profile.Settings.ExtensionData.Count)
        {
            return false;
        }

        foreach (var kvp in profile.Settings.ExtensionData)
        {
            if (!currentSettings.ExtensionData.TryGetValue(kvp.Key, out var currentValue))
            {
                return false;
            }

            // 使用 JsonElement 的 ToString 进行比较
            if (kvp.Value.ToString() != currentValue.ToString())
            {
                return false;
            }
        }

        return true;
    }

    public void UpdateActiveStatus(List<Profile> profiles, ClaudeSettings? currentSettings)
    {
        bool hasActive = false;
        foreach (var profile in profiles)
        {
            profile.IsActive = IsProfileActive(profile, currentSettings);
            if (profile.IsActive)
            {
                hasActive = true;
            }
        }

        // 如果没有任何配置被标记为激活，则不设置任何为激活状态
        if (!hasActive && currentSettings?.ExtensionData != null && currentSettings.ExtensionData.Count > 0)
        {
            // 当前有配置但没有匹配的 profile，所有都保持非激活状态
        }
    }
}
