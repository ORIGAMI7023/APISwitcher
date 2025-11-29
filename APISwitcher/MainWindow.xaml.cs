using System.Windows;
using APISwitcher.ViewModels;

namespace APISwitcher;

public partial class MainWindow : Window
{
    private readonly MainViewModel _viewModel;

    public MainWindow(MainViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        DataContext = viewModel;

        Loaded += async (s, e) => await viewModel.InitializeAsync();
        Activated += async (s, e) => await viewModel.OnWindowActivatedAsync();
    }
}