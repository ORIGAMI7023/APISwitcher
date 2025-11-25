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

    [ObservableProperty]
    private ObservableCollection<Profile> profiles = new();

    [ObservableProperty]
    private string statusMessage = "就绪";

    [ObservableProperty]
    private bool isLoading;

    public MainViewModel(ConfigService configService)
    {
        _configService = configService;
    }

    public async Task InitializeAsync()
    {
        await LoadProfilesAsync();
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
            MessageBox.Show($"成功切换到配置: {profile.Name}", "成功", MessageBoxButton.OK, MessageBoxImage.Information);
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
    }
}
