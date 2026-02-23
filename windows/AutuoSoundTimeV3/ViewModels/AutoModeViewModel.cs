using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using Microsoft.Win32;
using AutoSoundTimeV3.Models;
using AutoSoundTimeV3.Services;

namespace AutoSoundTimeV3.ViewModels;

public class AutoModeViewModel : ObservableObject
{
    private readonly SettingsViewModel _settings;
    private readonly TeamSettlementStore _store;

    public ObservableCollection<AudioFileItem> AudioFiles { get; } = new();

    private TimeSpan _totalDuration = TimeSpan.Zero;
    public TimeSpan TotalDuration
    {
        get => _totalDuration;
        private set { if (SetProperty(ref _totalDuration, value)) RaisePropertyChanged(nameof(TotalDurationText)); }
    }

    public string TotalDurationText => TotalDuration.ToString(TotalDuration.TotalHours >= 1 ? @"hh\:mm\:ss" : @"mm\:ss");

    private string _hourlyRate;
    public string HourlyRate
    {
        get => _hourlyRate;
        set { if (SetProperty(ref _hourlyRate, value)) { _settings.LastHourlyRate = value; UpdateSalary(); } }
    }

    private string _minuteRate;
    public string MinuteRate
    {
        get => _minuteRate;
        set { if (SetProperty(ref _minuteRate, value)) { _settings.LastMinuteRate = value; UpdateSalary(); } }
    }

    private DurationUnit _selectedUnit = DurationUnit.Minute;
    public DurationUnit SelectedUnit
    {
        get => _selectedUnit;
        set { if (SetProperty(ref _selectedUnit, value)) UpdateSalary(); }
    }

    private double _calculatedSalary;
    public double CalculatedSalary
    {
        get => _calculatedSalary;
        private set { if (SetProperty(ref _calculatedSalary, value)) RaisePropertyChanged(nameof(CalculatedSalaryText)); }
    }

    public string CalculatedSalaryText => CalculatedSalary.ToString("0.00");

    private bool _isCalculating;
    public bool IsCalculating
    {
        get => _isCalculating;
        private set => SetProperty(ref _isCalculating, value);
    }

    private string _projectName = string.Empty;
    public string ProjectName
    {
        get => _projectName;
        set => SetProperty(ref _projectName, value);
    }

    private string _producer = string.Empty;
    public string Producer
    {
        get => _producer;
        set => SetProperty(ref _producer, value);
    }

    private DateTime _calculationDate = DateTime.Today;
    public DateTime CalculationDate
    {
        get => _calculationDate;
        set => SetProperty(ref _calculationDate, value);
    }

    public RelayCommand AddFilesCommand { get; }
    public RelayCommand ClearFilesCommand { get; }
    public RelayCommand AddToTeamCommand { get; }

    public AutoModeViewModel(SettingsViewModel settings, TeamSettlementStore store)
    {
        _settings = settings;
        _store = store;
        _hourlyRate = settings.LastHourlyRate;
        _minuteRate = settings.LastMinuteRate;

        AddFilesCommand = new RelayCommand(async _ => await AddFilesAsync());
        ClearFilesCommand = new RelayCommand(_ => ClearFiles());
        AddToTeamCommand = new RelayCommand(_ => AddToTeam());
    }

    private async Task AddFilesAsync()
    {
        OpenFileDialog dialog = new()
        {
            Multiselect = true,
            Filter = "Audio Files|*.wav;*.mp3;*.aiff;*.aif;*.m4a;*.flac;*.aac|All Files|*.*"
        };

        if (dialog.ShowDialog() != true) return;

        IsCalculating = true;
        foreach (string file in dialog.FileNames)
        {
            if (!File.Exists(file)) continue;
            AudioFileItem item = new(file);
            AudioFiles.Add(item);
            TimeSpan duration = await AudioDurationService.GetDurationAsync(file);
            item.Duration = duration;
            item.IsProcessed = true;
        }
        IsCalculating = false;

        RecalculateTotals();
    }

    private void ClearFiles()
    {
        AudioFiles.Clear();
        TotalDuration = TimeSpan.Zero;
        CalculatedSalary = 0;
    }

    private void RecalculateTotals()
    {
        TotalDuration = TimeSpan.FromSeconds(AudioFiles.Sum(f => f.Duration.TotalSeconds));
        UpdateSalary();
    }

    private void UpdateSalary()
    {
        double rate = 0;
        if (SelectedUnit == DurationUnit.Hour)
        {
            double.TryParse(HourlyRate, out rate);
            CalculatedSalary = TotalDuration.TotalHours * rate;
        }
        else
        {
            double.TryParse(MinuteRate, out rate);
            CalculatedSalary = TotalDuration.TotalMinutes * rate;
        }
    }

    private void AddToTeam()
    {
        if (TotalDuration.TotalSeconds <= 0 || CalculatedSalary <= 0) return;

        CalculationMethod method = SelectedUnit == DurationUnit.Hour ? CalculationMethod.Hourly : CalculationMethod.Minute;
        SettlementEntry entry = new()
        {
            ProjectName = ProjectName,
            Producer = Producer,
            Date = CalculationDate,
            Duration = TotalDuration,
            Amount = CalculatedSalary,
            CalculationMethod = method
        };

        _store.Entries.Add(entry);
    }
}
