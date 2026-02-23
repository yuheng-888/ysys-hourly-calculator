using System;

namespace AutoSoundTimeV3.Models;

public class TimeEntryModel
{
    public Guid Id { get; } = Guid.NewGuid();
    public double Hours { get; set; }
    public double Minutes { get; set; }
    public double Seconds { get; set; }
    public DurationUnit Unit { get; set; }
    public double Rate { get; set; }
    public double Salary { get; set; }
    public TimeSpan TotalDuration { get; set; }

    public string FormattedTime => TotalDuration.ToString(TotalDuration.TotalHours >= 1 ? @"hh\:mm\:ss" : @"mm\:ss");
}
