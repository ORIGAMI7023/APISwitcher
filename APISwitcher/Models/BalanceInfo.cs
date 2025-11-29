using CommunityToolkit.Mvvm.ComponentModel;

namespace APISwitcher.Models;

/// <summary>
/// 余额信息
/// </summary>
public partial class BalanceInfo : ObservableObject
{
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private decimal balance;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private string displayUnit = "usd";

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private bool isUnlimited;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private bool isLoading;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private bool hasError;

    [ObservableProperty]
    private string? errorMessage;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private bool isFirstLoad = true;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private int failureCount = 0;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DisplayText))]
    private decimal? lastSuccessBalance;

    /// <summary>
    /// 格式化的余额显示文本
    /// </summary>
    public string DisplayText
    {
        get
        {
            // 仅首次加载时显示"加载中"
            if (IsLoading && IsFirstLoad)
                return "加载中...";

            // 多次失败（例如3次以上）才显示错误
            if (HasError && FailureCount >= 3)
                return "查询失败";

            if (IsUnlimited)
                return "无限额度";

            // 如果正在刷新但不是首次加载，显示上次成功的余额
            if (IsLoading && !IsFirstLoad && LastSuccessBalance.HasValue)
            {
                return FormatBalance(LastSuccessBalance.Value);
            }

            // 如果有错误但失败次数不多，显示上次成功的余额
            if (HasError && FailureCount < 3 && LastSuccessBalance.HasValue)
            {
                return FormatBalance(LastSuccessBalance.Value);
            }

            // 显示当前余额
            return FormatBalance(Balance);
        }
    }

    /// <summary>
    /// 格式化余额显示
    /// </summary>
    private string FormatBalance(decimal amount)
    {
        return DisplayUnit.ToLower() switch
        {
            "usd" => $"${amount:F2}",
            "cny" => $"¥{amount:F2}",
            "times" => $"剩余{amount:F0}次",
            _ => amount.ToString("F2")
        };
    }
}
