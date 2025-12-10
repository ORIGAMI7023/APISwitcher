using CommunityToolkit.Mvvm.ComponentModel;

namespace APISwitcher.Models;

/// <summary>
/// 订阅信息
/// </summary>
public partial class SubscriptionInfo : ObservableObject
{
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DailyUsagePercent), nameof(DailyQuotaLimitUsd))]
    private long dailyQuotaLimit;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DailyUsagePercent), nameof(DailyQuotaUsedUsd))]
    private long dailyQuotaUsed;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(WeeklyUsagePercent), nameof(WeeklyQuotaLimitUsd))]
    private long weeklyQuotaLimit;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(WeeklyUsagePercent), nameof(WeeklyQuotaUsedUsd))]
    private long weeklyQuotaUsed;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(TotalUsagePercent), nameof(TotalQuotaLimitUsd))]
    private long totalQuotaLimit;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(TotalUsagePercent), nameof(TotalQuotaUsedUsd))]
    private long totalQuotaUsed;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(DaysRemaining), nameof(ExpireTimeFormatted))]
    private long expireTime;

    [ObservableProperty]
    private bool isLoading;

    [ObservableProperty]
    private bool hasError;

    [ObservableProperty]
    private string? errorMessage;

    /// <summary>
    /// 是否首次加载（用于控制UI显示，首次加载时隐藏内容显示加载提示，刷新时保留旧内容）
    /// </summary>
    [ObservableProperty]
    private bool isFirstLoad = true;

    /// <summary>
    /// 单位换算除数（API原始值除以此数得到美元）
    /// </summary>
    private const double Divisor = 500000.0;

    /// <summary>
    /// 日限额（美元）
    /// </summary>
    public string DailyQuotaLimitUsd => $"${DailyQuotaLimit / Divisor:F2}";

    /// <summary>
    /// 日已用（美元）
    /// </summary>
    public string DailyQuotaUsedUsd => $"${DailyQuotaUsed / Divisor:F2}";

    /// <summary>
    /// 周限额（美元）
    /// </summary>
    public string WeeklyQuotaLimitUsd => $"${WeeklyQuotaLimit / Divisor:F2}";

    /// <summary>
    /// 周已用（美元）
    /// </summary>
    public string WeeklyQuotaUsedUsd => $"${WeeklyQuotaUsed / Divisor:F2}";

    /// <summary>
    /// 总限额（美元）
    /// </summary>
    public string TotalQuotaLimitUsd => $"${TotalQuotaLimit / Divisor:F2}";

    /// <summary>
    /// 总已用（美元）
    /// </summary>
    public string TotalQuotaUsedUsd => $"${TotalQuotaUsed / Divisor:F2}";

    /// <summary>
    /// 日使用百分比
    /// </summary>
    public double DailyUsagePercent => DailyQuotaLimit > 0 ? (double)DailyQuotaUsed / DailyQuotaLimit * 100 : 0;

    /// <summary>
    /// 周使用百分比
    /// </summary>
    public double WeeklyUsagePercent => WeeklyQuotaLimit > 0 ? (double)WeeklyQuotaUsed / WeeklyQuotaLimit * 100 : 0;

    /// <summary>
    /// 总使用百分比
    /// </summary>
    public double TotalUsagePercent => TotalQuotaLimit > 0 ? (double)TotalQuotaUsed / TotalQuotaLimit * 100 : 0;

    /// <summary>
    /// 剩余天数
    /// </summary>
    public int DaysRemaining
    {
        get
        {
            if (ExpireTime == 0) return 0;
            var expireDate = DateTimeOffset.FromUnixTimeSeconds(ExpireTime);
            var timeSpan = expireDate - DateTimeOffset.UtcNow;
            return Math.Max(0, (int)Math.Ceiling(timeSpan.TotalDays));
        }
    }

    /// <summary>
    /// 到期时间格式化字符串
    /// </summary>
    public string ExpireTimeFormatted
    {
        get
        {
            if (ExpireTime == 0) return "未知";
            var expireDate = DateTimeOffset.FromUnixTimeSeconds(ExpireTime).ToLocalTime();
            return expireDate.ToString("yyyy/M/d HH:mm");
        }
    }
}
