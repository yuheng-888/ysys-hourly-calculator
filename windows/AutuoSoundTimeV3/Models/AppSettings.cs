namespace AutoSoundTimeV3.Models;

public class AppSettings
{
    public bool ShowAutoMode { get; set; } = true;
    public bool ShowManualMode { get; set; } = true;
    public bool ShowTeamMode { get; set; } = true;
    public bool EnableSmartInput { get; set; } = true;
    public bool ShowDurationInSeconds { get; set; } = true;
    public string LastHourlyRate { get; set; } = string.Empty;
    public string LastMinuteRate { get; set; } = string.Empty;
    public AppTab SelectedTab { get; set; } = AppTab.Auto;
}
