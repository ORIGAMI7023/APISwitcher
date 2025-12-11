using System.Windows;
using System.Windows.Media.Animation;
using APISwitcher.ViewModels;
using System.ComponentModel;

namespace APISwitcher;

public partial class MainWindow : Window
{
    private readonly MainViewModel _viewModel;
    private const double CollapsedHeight = 460;
    private const double ExpandedHeight = 670;

    public MainWindow(MainViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        DataContext = viewModel;

        // 监听 ShowSubscriptionPanel 属性变化
        _viewModel.PropertyChanged += OnViewModelPropertyChanged;

        Loaded += async (s, e) =>
        {
            await viewModel.InitializeAsync();
            // 初始化时根据 ShowSubscriptionPanel 设置窗体高度（不需要动画）
            Height = _viewModel.ShowSubscriptionPanel ? ExpandedHeight : CollapsedHeight;
        };
        Activated += async (s, e) => await viewModel.OnWindowActivatedAsync();
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(MainViewModel.ShowSubscriptionPanel))
        {
            AnimateSubscriptionPanel(_viewModel.ShowSubscriptionPanel);
        }
    }

    private void AnimateSubscriptionPanel(bool show)
    {
        var duration = TimeSpan.FromMilliseconds(300);
        var easingFunction = new CubicEase { EasingMode = EasingMode.EaseInOut };

        if (show)
        {
            // 展开：先显示面板，然后执行动画
            SubscriptionPanel.Visibility = Visibility.Visible;

            // 窗体高度动画
            var heightAnimation = new DoubleAnimation
            {
                To = ExpandedHeight,
                Duration = duration,
                EasingFunction = easingFunction
            };
            BeginAnimation(HeightProperty, heightAnimation);

            // 面板缩放动画
            var scaleAnimation = new DoubleAnimation
            {
                To = 1,
                Duration = duration,
                EasingFunction = easingFunction
            };
            var scaleTransform = (System.Windows.Media.ScaleTransform)SubscriptionPanel.RenderTransform;
            scaleTransform.BeginAnimation(System.Windows.Media.ScaleTransform.ScaleYProperty, scaleAnimation);

            // 面板透明度动画
            var opacityAnimation = new DoubleAnimation
            {
                To = 1,
                Duration = duration,
                EasingFunction = easingFunction
            };
            SubscriptionPanel.BeginAnimation(OpacityProperty, opacityAnimation);
        }
        else
        {
            // 折叠：先执行动画，然后隐藏面板
            // 窗体高度动画
            var heightAnimation = new DoubleAnimation
            {
                To = CollapsedHeight,
                Duration = duration,
                EasingFunction = easingFunction
            };
            BeginAnimation(HeightProperty, heightAnimation);

            // 面板缩放动画
            var scaleAnimation = new DoubleAnimation
            {
                To = 0,
                Duration = duration,
                EasingFunction = easingFunction
            };
            var scaleTransform = (System.Windows.Media.ScaleTransform)SubscriptionPanel.RenderTransform;
            scaleTransform.BeginAnimation(System.Windows.Media.ScaleTransform.ScaleYProperty, scaleAnimation);

            // 面板透明度动画
            var opacityAnimation = new DoubleAnimation
            {
                To = 0,
                Duration = duration,
                EasingFunction = easingFunction
            };
            // 动画完成后隐藏面板
            opacityAnimation.Completed += (s, e) => SubscriptionPanel.Visibility = Visibility.Collapsed;
            SubscriptionPanel.BeginAnimation(OpacityProperty, opacityAnimation);
        }
    }
}