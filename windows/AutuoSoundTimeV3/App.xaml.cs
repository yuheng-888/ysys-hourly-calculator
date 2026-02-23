using System.Windows;
using AutoSoundTimeV3.Models;
using AutoSoundTimeV3.Services;

namespace AutoSoundTimeV3;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        var settings = StorageService.Load("settings.json", new AppSettings());
        ThemeManager.ApplyTheme(settings.Theme);
    }
}
