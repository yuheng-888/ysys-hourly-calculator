using AutoSoundTimeV3.Models;
using AutoSoundTimeV3.Services;

namespace AutoSoundTimeV3.ViewModels;

public class SettingsViewModel : ObservableObject
{
    private readonly AppSettings _settings;

    public SettingsViewModel()
    {
        _settings = StorageService.Load("settings.json", new AppSettings());
    }

    public AppSettings Model => _settings;

    public bool ShowAutoMode
    {
        get => _settings.ShowAutoMode;
        set { if (_settings.ShowAutoMode == value) return; _settings.ShowAutoMode = value; Save(); RaisePropertyChanged(); }
    }

    public bool ShowManualMode
    {
        get => _settings.ShowManualMode;
        set { if (_settings.ShowManualMode == value) return; _settings.ShowManualMode = value; Save(); RaisePropertyChanged(); }
    }

    public bool ShowTeamMode
    {
        get => _settings.ShowTeamMode;
        set { if (_settings.ShowTeamMode == value) return; _settings.ShowTeamMode = value; Save(); RaisePropertyChanged(); }
    }

    public bool EnableSmartInput
    {
        get => _settings.EnableSmartInput;
        set { if (_settings.EnableSmartInput == value) return; _settings.EnableSmartInput = value; Save(); RaisePropertyChanged(); }
    }

    public bool ShowDurationInSeconds
    {
        get => _settings.ShowDurationInSeconds;
        set { if (_settings.ShowDurationInSeconds == value) return; _settings.ShowDurationInSeconds = value; Save(); RaisePropertyChanged(); }
    }

    public string LastHourlyRate
    {
        get => _settings.LastHourlyRate;
        set { if (_settings.LastHourlyRate == value) return; _settings.LastHourlyRate = value; Save(); RaisePropertyChanged(); }
    }

    public string LastMinuteRate
    {
        get => _settings.LastMinuteRate;
        set { if (_settings.LastMinuteRate == value) return; _settings.LastMinuteRate = value; Save(); RaisePropertyChanged(); }
    }

    public AppTab SelectedTab
    {
        get => _settings.SelectedTab;
        set { if (_settings.SelectedTab == value) return; _settings.SelectedTab = value; Save(); RaisePropertyChanged(); }
    }

    public void Save() => StorageService.Save("settings.json", _settings);
}
