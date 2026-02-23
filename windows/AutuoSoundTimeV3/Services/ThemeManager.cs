using System;
using System.Linq;
using System.Windows;
using AutoSoundTimeV3.Models;

namespace AutoSoundTimeV3.Services;

public static class ThemeManager
{
    public static void ApplyTheme(AppTheme theme)
    {
        Application? app = Application.Current;
        if (app == null) return;

        string name = theme.ToString();
        var dict = new ResourceDictionary
        {
            Source = new Uri($"Assets/Themes/{name}.xaml", UriKind.Relative)
        };

        var existing = app.Resources.MergedDictionaries
            .FirstOrDefault(d => d.Source != null && d.Source.OriginalString.Contains("Assets/Themes/"));

        if (existing != null)
        {
            app.Resources.MergedDictionaries.Remove(existing);
        }

        app.Resources.MergedDictionaries.Insert(0, dict);
    }
}
