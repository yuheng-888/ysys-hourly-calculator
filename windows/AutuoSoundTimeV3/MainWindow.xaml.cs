using System.Windows;
using AutoSoundTimeV3.ViewModels;

namespace AutoSoundTimeV3;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        DataContext = new MainViewModel();
    }
}
