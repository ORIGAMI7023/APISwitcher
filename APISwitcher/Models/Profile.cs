using CommunityToolkit.Mvvm.ComponentModel;

namespace APISwitcher.Models;

public partial class Profile : ObservableObject
{
    [ObservableProperty]
    private string name = string.Empty;

    [ObservableProperty]
    private bool isActive;

    public ClaudeSettings Settings { get; set; } = new();
}
