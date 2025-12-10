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

        // 检查是否应该显示订阅面板
        ShowSubscriptionPanel = activeProfile?.ShouldShowSubscription == true;

        if (!ShowSubscriptionPanel)
        {
            ActiveSubscriptionInfo = null;
            return;
        }

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
}
