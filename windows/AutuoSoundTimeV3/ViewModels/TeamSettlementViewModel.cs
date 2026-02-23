using System;
using System.Collections.ObjectModel;
using System.Globalization;
using AutoSoundTimeV3.Models;
using AutoSoundTimeV3.Services;

namespace AutoSoundTimeV3.ViewModels;

public class TeamSettlementViewModel : ObservableObject
{
    private readonly TeamSettlementStore _store;

    public ObservableCollection<SettlementEntry> Entries => _store.Entries;

    private SettlementEntry? _selectedEntry;
    public SettlementEntry? SelectedEntry
    {
        get => _selectedEntry;
        set => SetProperty(ref _selectedEntry, value);
    }

    private string _projectName = string.Empty;
    public string ProjectName { get => _projectName; set => SetProperty(ref _projectName, value); }

    private string _producer = string.Empty;
    public string Producer { get => _producer; set => SetProperty(ref _producer, value); }

    private DateTime _date = DateTime.Today;
    public DateTime Date { get => _date; set => SetProperty(ref _date, value); }

    private string _hours = "";
    public string Hours { get => _hours; set => SetProperty(ref _hours, value); }

    private string _minutes = "";
    public string Minutes { get => _minutes; set => SetProperty(ref _minutes, value); }

    private string _seconds = "";
    public string Seconds { get => _seconds; set => SetProperty(ref _seconds, value); }

    private string _amount = "";
    public string Amount { get => _amount; set => SetProperty(ref _amount, value); }

    private CalculationMethod _method = CalculationMethod.Hourly;
    public CalculationMethod Method { get => _method; set => SetProperty(ref _method, value); }

    public RelayCommand AddEntryCommand { get; }
    public RelayCommand RemoveEntryCommand { get; }

    public TeamSettlementViewModel(TeamSettlementStore store)
    {
        _store = store;
        AddEntryCommand = new RelayCommand(_ => AddEntry());
        RemoveEntryCommand = new RelayCommand(_ => RemoveEntry());
    }

    private void AddEntry()
    {
        double.TryParse(Hours, out double h);
        double.TryParse(Minutes, out double m);
        double.TryParse(Seconds, out double s);
        double.TryParse(Amount, NumberStyles.Any, CultureInfo.InvariantCulture, out double amount);

        TimeSpan duration = TimeSpan.FromSeconds(h * 3600 + m * 60 + s);

        SettlementEntry entry = new()
        {
            ProjectName = ProjectName,
            Producer = Producer,
            Date = Date,
            Duration = duration,
            Amount = amount,
            CalculationMethod = Method
        };

        _store.Entries.Add(entry);
    }

    private void RemoveEntry()
    {
        if (SelectedEntry == null) return;
        _store.Entries.Remove(SelectedEntry);
    }
}
