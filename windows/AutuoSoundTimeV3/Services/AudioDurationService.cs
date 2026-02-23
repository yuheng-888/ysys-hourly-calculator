using System;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;

namespace AutoSoundTimeV3.Services;

public static class AudioDurationService
{
    public static Task<TimeSpan> GetDurationAsync(string filePath)
    {
        var tcs = new TaskCompletionSource<TimeSpan>();

        Application.Current.Dispatcher.InvokeAsync(() =>
        {
            MediaPlayer player = new();
            player.MediaOpened += (s, e) =>
            {
                TimeSpan duration = player.NaturalDuration.HasTimeSpan
                    ? player.NaturalDuration.TimeSpan
                    : TimeSpan.Zero;
                player.Close();
                tcs.TrySetResult(duration);
            };
            player.MediaFailed += (s, e) =>
            {
                player.Close();
                tcs.TrySetResult(TimeSpan.Zero);
            };
            player.Open(new Uri(filePath));
        });

        return tcs.Task;
    }
}
