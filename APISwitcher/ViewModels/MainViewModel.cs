using System.Collections.ObjectModel;
using System.Windows;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using APISwitcher.Models;
using APISwitcher.Services;

namespace APISwitcher.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly ConfigService _configService;
    private readonly BalanceService _balanceService;
    private readonly SubscriptionService _subscriptionService;

    [ObservableProperty]
    private ObservableCollection<Profile> profiles = new();

    [ObservableProperty]
    private string statusMessage = "就绪";

    [ObservableProperty]
    private bool isLoading;

    [ObservableProperty]
    private SubscriptionInfo? activeSubscriptionInfo;

    [ObservableProperty]
    private bool showSubscriptionPanel;

    // 视图导航
    [ObservableProperty]
    private bool isFormViewVisible = false;

    [ObservableProperty]
    private Profile? editingProfile; // null = 添加模式，非null = 编辑模式

    // 表单字段
    [ObservableProperty]
    private string formProfileName = string.Empty;

    [ObservableProperty]
    private string formBaseUrl = string.Empty;

    [ObservableProperty]
    private string formApiKey = string.Empty;

    // 表单标题
    public string FormTitle => EditingProfile == null ? "添加新配置" : "编辑配置";

    public MainViewModel(ConfigService configService, BalanceService balanceService, SubscriptionService subscriptionService)
    {
        _configService = configService;
        _balanceService = balanceService;
        _subscriptionService = subscriptionService;
    }

    public async Task InitializeAsync()
    {
        await LoadProfilesAsync();
        // 启动时查询所有配置的余额
        await QueryAllBalancesAsync();
        // 查询当前激活配置的订阅信息
        await QueryActiveSubscriptionAsync();
    }

    /// <summary>
    /// 当窗口激活时调用
    /// </summary>
    public async Task OnWindowActivatedAsync()
    {
        await QueryAllBalancesAsync();
        await QueryActiveSubscriptionAsync();
    }

    [RelayCommand]
    private async Task LoadProfilesAsync()
    {
        try
        {
            IsLoading = true;
            StatusMessage = "正在加载配置...";

            var loadedProfiles = await _configService.LoadProfilesAsync();
            var currentSettings = await _configService.LoadClaudeSettingsAsync();

            _configService.UpdateActiveStatus(loadedProfiles, currentSettings);

            Profiles.Clear();
            foreach (var profile in loadedProfiles)
            {
                Profiles.Add(profile);
            }

            StatusMessage = $"已加载 {Profiles.Count} 个配置";
        }
        catch (Exception ex)
        {
            StatusMessage = $"加载失败: {ex.Message}";
            MessageBox.Show($"加载配置失败:\n{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task SwitchProfileAsync(Profile? profile)
    {
        if (profile == null)
        {
            return;
        }

        try
        {
            IsLoading = true;
            StatusMessage = $"正在切换到 {profile.Name}...";

            await _configService.SaveClaudeSettingsAsync(profile.Settings);

            foreach (var p in Profiles)
            {
                p.IsActive = false;
            }
            profile.IsActive = true;

            StatusMessage = $"已切换到 {profile.Name}";

            // 切换后查询该配置的余额
            await QuerySingleBalanceAsync(profile);

            // 查询订阅信息
            await QueryActiveSubscriptionAsync();
        }
        catch (Exception ex)
        {
            StatusMessage = $"切换失败: {ex.Message}";
            MessageBox.Show($"切换配置失败:\n{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private async Task RefreshAsync()
    {
        await LoadProfilesAsync();
        await QueryAllBalancesAsync();
        await QueryActiveSubscriptionAsync();
    }

    /// <summary>
    /// 查询所有配置的余额
    /// </summary>
    private async Task QueryAllBalancesAsync()
    {
        // 首先清除所有不应该显示余额的配置的 BalanceInfo
        foreach (var profile in Profiles.Where(p => !p.ShouldShowBalance))
        {
            profile.BalanceInfo = null;
        }

        // 然后查询应该显示余额的配置
        var tasks = Profiles
            .Where(p => p.ShouldShowBalance)
            .Select(p => QuerySingleBalanceAsync(p));

        await Task.WhenAll(tasks);
    }

    /// <summary>
    /// 查询单个配置的余额
    /// </summary>
    private async Task QuerySingleBalanceAsync(Profile profile)
    {
        if (!profile.ShouldShowBalance)
        {
            return;
        }

        try
        {
            // 不要每次都创建新的 BalanceInfo
            // 如果已经存在，设置为加载状态；否则创建新的
            if (profile.BalanceInfo == null)
            {
                profile.BalanceInfo = new BalanceInfo { IsLoading = true, IsFirstLoad = true };
            }
            else
            {
                profile.BalanceInfo.IsLoading = true;
            }

            // 执行查询（BalanceService 会保留和更新状态）
            var balanceInfo = await _balanceService.QueryBalanceAsync(profile);
            profile.BalanceInfo = balanceInfo;
        }
        catch (Exception ex)
        {
            // 如果已有 BalanceInfo，更新错误状态；否则创建新的
            if (profile.BalanceInfo != null)
            {
                profile.BalanceInfo.IsLoading = false;
                profile.BalanceInfo.HasError = true;
                profile.BalanceInfo.ErrorMessage = ex.Message;
                profile.BalanceInfo.FailureCount++;
            }
            else
            {
                profile.BalanceInfo = new BalanceInfo
                {
                    IsLoading = false,
                    HasError = true,
                    ErrorMessage = ex.Message,
                    FailureCount = 1
                };
            }
        }
    }

    /// <summary>
    /// 查询当前激活配置的订阅信息
    /// </summary>
    private async Task QueryActiveSubscriptionAsync()
    {
        // 找到激活的配置
        var activeProfile = Profiles.FirstOrDefault(p => p.IsActive);

        // 检查是否应该显示订阅面板（只有 Claude_Opus_4.5 才显示）
        var shouldShow = activeProfile?.Name == "Claude_Opus_4.5" &&
                         activeProfile?.ShouldShowSubscription == true;

        if (!shouldShow)
        {
            // 先清除错误状态，避免收缩动画时显示"更新失败"
            if (ActiveSubscriptionInfo != null)
            {
                ActiveSubscriptionInfo.HasError = false;
                ActiveSubscriptionInfo.ErrorMessage = null;
            }

            // 触发面板隐藏动画
            ShowSubscriptionPanel = false;

            // 动画完成后再清空订阅信息（延迟执行）
            _ = Task.Delay(350).ContinueWith(_ => ActiveSubscriptionInfo = null);
            return;
        }

        // 显示面板
        ShowSubscriptionPanel = true;

        try
        {
            if (ActiveSubscriptionInfo == null)
            {
                ActiveSubscriptionInfo = new SubscriptionInfo { IsLoading = true, IsFirstLoad = true };
            }
            else
            {
                ActiveSubscriptionInfo.IsLoading = true;
                // 刷新时不是首次加载，保持 IsFirstLoad = false
            }

            var subscriptionInfo = await _subscriptionService.QuerySubscriptionAsync(activeProfile!);
            ActiveSubscriptionInfo = subscriptionInfo;
        }
        catch (Exception ex)
        {
            if (ActiveSubscriptionInfo != null)
            {
                ActiveSubscriptionInfo.IsLoading = false;
                ActiveSubscriptionInfo.HasError = true;
                ActiveSubscriptionInfo.ErrorMessage = ex.Message;
            }
            else
            {
                ActiveSubscriptionInfo = new SubscriptionInfo
                {
                    IsLoading = false,
                    HasError = true,
                    ErrorMessage = ex.Message
                };
            }
        }
    }

    /// <summary>
    /// 显示添加配置视图
    /// </summary>
    [RelayCommand]
    private void ShowAddView()
    {
        EditingProfile = null;
        FormProfileName = string.Empty;
        FormBaseUrl = string.Empty;
        FormApiKey = string.Empty;
        IsFormViewVisible = true;
    }

    /// <summary>
    /// 显示编辑配置视图
    /// </summary>
    [RelayCommand]
    private void ShowEditView(Profile profile)
    {
        EditingProfile = profile;
        FormProfileName = profile.Name;

        // 从 Settings.ExtensionData 中提取 env 数据
        if (profile.Settings.ExtensionData?.TryGetValue("env", out var envElement) == true
            && envElement.ValueKind == System.Text.Json.JsonValueKind.Object)
        {
            if (envElement.TryGetProperty("ANTHROPIC_BASE_URL", out var baseUrlElement))
            {
                FormBaseUrl = baseUrlElement.GetString() ?? string.Empty;
            }

            if (envElement.TryGetProperty("ANTHROPIC_AUTH_TOKEN", out var tokenElement))
            {
                FormApiKey = tokenElement.GetString() ?? string.Empty;
            }
        }

        IsFormViewVisible = true;
        OnPropertyChanged(nameof(FormTitle));
    }

    /// <summary>
    /// 返回列表视图
    /// </summary>
    [RelayCommand]
    private void BackToList()
    {
        IsFormViewVisible = false;
        EditingProfile = null;
    }

    /// <summary>
    /// 保存配置（添加或更新）
    /// </summary>
    [RelayCommand]
    private async Task SaveProfileAsync()
    {
        try
        {
            // 验证输入
            if (string.IsNullOrWhiteSpace(FormProfileName))
            {
                MessageBox.Show("请输入配置名称", "验证失败", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(FormBaseUrl))
            {
                MessageBox.Show("请输入 Base URL", "验证失败", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(FormApiKey))
            {
                MessageBox.Show("请输入 API Key", "验证失败", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            // 验证 URL 格式
            if (!Uri.TryCreate(FormBaseUrl, UriKind.Absolute, out _))
            {
                MessageBox.Show("Base URL 格式不正确", "验证失败", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            IsLoading = true;
            StatusMessage = EditingProfile == null ? "正在添加配置..." : "正在更新配置...";

            // 构建配置对象
            var profile = new Profile
            {
                Name = FormProfileName.Trim(),
                Settings = new ClaudeSettings
                {
                    ExtensionData = new Dictionary<string, System.Text.Json.JsonElement>
                    {
                        ["env"] = System.Text.Json.JsonSerializer.SerializeToElement(new Dictionary<string, string>
                        {
                            ["ANTHROPIC_AUTH_TOKEN"] = FormApiKey.Trim(),
                            ["ANTHROPIC_BASE_URL"] = FormBaseUrl.Trim(),
                            ["API_TIMEOUT_MS"] = "3000000",
                            ["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"
                        }),
                        ["alwaysThinkingEnabled"] = System.Text.Json.JsonSerializer.SerializeToElement(false)
                    }
                }
            };

            if (EditingProfile == null)
            {
                // 添加模式
                await _configService.AddProfileAsync(profile);
                StatusMessage = "配置添加成功";
            }
            else
            {
                // 编辑模式
                await _configService.UpdateProfileAsync(EditingProfile.Name, profile);
                StatusMessage = "配置更新成功";
            }

            // 返回列表并刷新
            IsFormViewVisible = false;
            await LoadProfilesAsync();
        }
        catch (Exception ex)
        {
            StatusMessage = $"保存失败: {ex.Message}";
            MessageBox.Show($"保存配置失败:\n{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            IsLoading = false;
        }
    }

    /// <summary>
    /// 删除配置
    /// </summary>
    [RelayCommand]
    private async Task DeleteProfileAsync(Profile profile)
    {
        try
        {
            var result = MessageBox.Show(
                $"确定要删除配置 \"{profile.Name}\" 吗？\n此操作不可撤销。",
                "确认删除",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (result != MessageBoxResult.Yes)
            {
                return;
            }

            IsLoading = true;
            StatusMessage = $"正在删除配置 {profile.Name}...";

            await _configService.DeleteProfileAsync(profile.Name);

            StatusMessage = $"配置 {profile.Name} 已删除";
            await LoadProfilesAsync();
        }
        catch (Exception ex)
        {
            StatusMessage = $"删除失败: {ex.Message}";
            MessageBox.Show($"删除配置失败:\n{ex.Message}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            IsLoading = false;
        }
    }
}
