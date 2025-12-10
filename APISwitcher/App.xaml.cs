using System.Windows;
using APISwitcher.Services;
using APISwitcher.ViewModels;
using Microsoft.Extensions.DependencyInjection;

namespace APISwitcher;

public partial class App : Application
{
    private readonly ServiceProvider _serviceProvider;

    public App()
    {
        var services = new ServiceCollection();
        ConfigureServices(services);
        _serviceProvider = services.BuildServiceProvider();
    }

    private void ConfigureServices(IServiceCollection services)
    {
        // 注册服务
        services.AddSingleton<ConfigService>();
        services.AddSingleton<BalanceService>();
        services.AddSingleton<SubscriptionService>();

        // 注册ViewModel和View
        services.AddSingleton<MainViewModel>();
        services.AddSingleton<MainWindow>();
    }

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var mainWindow = _serviceProvider.GetRequiredService<MainWindow>();
        mainWindow.Show();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        // 清理资源
        _serviceProvider.GetService<BalanceService>()?.Dispose();
        _serviceProvider.GetService<SubscriptionService>()?.Dispose();
        _serviceProvider?.Dispose();
        base.OnExit(e);
    }
}
