using System;
using System.Windows;
using AutoSoundTimeV3.Models;
using AutoSoundTimeV3.Services;
using AutoSoundTimeV3.Views;

namespace AutoSoundTimeV3.ViewModels;

public class MainViewModel : ObservableObject
{
    private readonly TeamSettlementStore _store;

    public SettingsViewModel Settings { get; }
    public AutoModeViewModel AutoMode { get; }
    public ManualModeViewModel ManualMode { get; }
    public TeamSettlementViewModel TeamMode { get; }

    private AppTab _selectedTab;
    public AppTab SelectedTab
    {
        get => _selectedTab;
        set
        {
            if (SetProperty(ref _selectedTab, value))
            {
                Settings.SelectedTab = value;
                RaisePropertyChanged(nameof(CurrentViewModel));
            }
        }
    }

    public object CurrentViewModel => SelectedTab switch
    {
        AppTab.Manual => ManualMode,
        AppTab.Team => TeamMode,
        _ => AutoMode
    };

    public RelayCommand SelectTabCommand { get; }
    public RelayCommand OpenSettingsCommand { get; }

    public MainViewModel()
    {
        _store = new TeamSettlementStore();
        Settings = new SettingsViewModel();
        AutoMode = new AutoModeViewModel(Settings, _store);
        ManualMode = new ManualModeViewModel(Settings);
        TeamMode = new TeamSettlementViewModel(_store);

        _selectedTab = Settings.SelectedTab;

        SelectTabCommand = new RelayCommand(param =>
        {
            if (param is string s && Enum.TryParse<AppTab>(s, out var tab))
            {
                SelectedTab = tab;
            }
        });

        OpenSettingsCommand = new RelayCommand(_ => OpenSettings());
    }

    private void OpenSettings()
    {
        SettingsWindow win = new()
        {
            DataContext = Settings,
            Owner = Application.Current.MainWindow
        };
        win.ShowDialog();
    }
}
