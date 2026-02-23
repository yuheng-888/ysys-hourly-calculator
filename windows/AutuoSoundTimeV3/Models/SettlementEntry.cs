using System;

namespace AutoSoundTimeV3.Models;

public class SettlementEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid Cid { get; set; } = Guid.NewGuid();
    public string ProjectName { get; set; } = string.Empty;
    public string Producer { get; set; } = string.Empty;
    public DateTime Date { get; set; } = DateTime.Today;
    public TimeSpan Duration { get; set; } = TimeSpan.Zero;
    public double Amount { get; set; }
    public CalculationMethod CalculationMethod { get; set; } = CalculationMethod.Hourly;

    public string FormattedDate => Date.ToString("yyyy-MM-dd");
    public string FormattedDuration => Duration.ToString(Duration.TotalHours >= 1 ? @"hh\:mm\:ss" : @"mm\:ss");
}
