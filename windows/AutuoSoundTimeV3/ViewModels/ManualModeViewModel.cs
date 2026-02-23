using System;
using System.Collections.ObjectModel;
using System.Globalization;
using AutoSoundTimeV3.Models;
using AutoSoundTimeV3.Services;

namespace AutoSoundTimeV3.ViewModels;

public class ManualModeViewModel : ObservableObject
{
    private readonly SettingsViewModel _settings;

    public ObservableCollection<TimeEntryModel> Entries { get; } = new();

    private string _hours = "";
    public string Hours { get => _hours; set => SetProperty(ref _hours, value); }

    private string _minutes = "";
    public string Minutes { get => _minutes; set => SetProperty(ref _minutes, value); }

    private string _seconds = "";
    public string Seconds { get => _seconds; set => SetProperty(ref _seconds, value); }

    private string _smartInput = "";
    public string SmartInput
    {
        get => _smartInput;
        set
        {
            if (!SetProperty(ref _smartInput, value)) return;
            if (_settings.EnableSmartInput)
            {
                var parsed = SmartTimeParser.Parse(value);
                Hours = parsed.hours;
                Minutes = parsed.minutes;
                Seconds = parsed.seconds;
            }
        }
    }

    private string _rate = "";
    public string Rate { get => _rate; set => SetProperty(ref _rate, value); }

    private string _manualAmount = "";
    public string ManualAmount { get => _manualAmount; set => SetProperty(ref _manualAmount, value); }

    private CalculationMethod _method = CalculationMethod.Hourly;
    public CalculationMethod Method { get => _method; set => SetProperty(ref _method, value); }

    private double _totalAmount;
    public double TotalAmount
    {
        get => _totalAmount;
        private set { if (SetProperty(ref _totalAmount, value)) RaisePropertyChanged(nameof(TotalAmountText)); }
    }

    public string TotalAmountText => TotalAmount.ToString("0.00", CultureInfo.InvariantCulture);

    public RelayCommand AddEntryCommand { get; }
    public RelayCommand ClearCommand { get; }

    public ManualModeViewModel(SettingsViewModel settings)
    {
        _settings = settings;
        Rate = settings.LastHourlyRate;

        AddEntryCommand = new RelayCommand(_ => AddEntry());
        ClearCommand = new RelayCommand(_ => Clear());
    }

    private void AddEntry()
    {
        if (Method == CalculationMethod.Manual)
        {
            if (!double.TryParse(ManualAmount, out double manualAmount)) return;
            Entries.Add(new TimeEntryModel
            {
                Unit = DurationUnit.Minute,
                Rate = 0,
                Salary = manualAmount,
                TotalDuration = TimeSpan.Zero
            });
            RecalculateTotals();
            return;
        }

        double.TryParse(Hours, out double h);
        double.TryParse(Minutes, out double m);
        double.TryParse(Seconds, out double s);
        double.TryParse(Rate, out double rate);

        TimeSpan duration = TimeSpan.FromSeconds(h * 3600 + m * 60 + s);
        double salary = Method == CalculationMethod.Hourly
            ? duration.TotalHours * rate
            : duration.TotalMinutes * rate;

        Entries.Add(new TimeEntryModel
        {
            Hours = h,
            Minutes = m,
            Seconds = s,
            Unit = Method == CalculationMethod.Hourly ? DurationUnit.Hour : DurationUnit.Minute,
            Rate = rate,
            Salary = salary,
            TotalDuration = duration
        });

        RecalculateTotals();
    }

    private void Clear()
    {
        Entries.Clear();
        TotalAmount = 0;
    }

    private void RecalculateTotals()
    {
        TotalAmount = 0;
        foreach (var entry in Entries)
        {
            TotalAmount += entry.Salary;
        }
    }
}
