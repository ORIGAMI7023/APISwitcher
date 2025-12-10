using CommunityToolkit.Mvvm.ComponentModel;
using System.Text.Json.Serialization;

namespace APISwitcher.Models;

public partial class Profile : ObservableObject
{
    [ObservableProperty]
    private string name = string.Empty;

    [ObservableProperty]
    private bool isActive;

    public ClaudeSettings Settings { get; set; } = new();

    /// <summary>
    /// 余额API配置（可选，如果为null则不显示余额）
    /// </summary>
    [JsonPropertyName("balanceApi")]
    public BalanceApiConfig? BalanceApi { get; set; }

    /// <summary>
    /// 余额信息（运行时数据，不序列化）
    /// </summary>
    [JsonIgnore]
    [ObservableProperty]
    private BalanceInfo? balanceInfo;

    /// <summary>
    /// 是否应该显示余额信息
    /// </summary>
    [JsonIgnore]
    public bool ShouldShowBalance => BalanceApi != null;

    /// <summary>
    /// 订阅API配置（可选，如果为null则不显示订阅信息）
    /// </summary>
    [JsonPropertyName("subscriptionApi")]
    public SubscriptionApiConfig? SubscriptionApi { get; set; }

    /// <summary>
    /// 订阅信息（运行时数据，不序列化）
    /// </summary>
    [JsonIgnore]
    [ObservableProperty]
    private SubscriptionInfo? subscriptionInfo;

    /// <summary>
    /// 是否应该显示订阅信息
    /// </summary>
    [JsonIgnore]
    public bool ShouldShowSubscription => SubscriptionApi != null;
}
