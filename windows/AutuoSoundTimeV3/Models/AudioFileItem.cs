using System;
using System.IO;

namespace AutoSoundTimeV3.Models;

public class AudioFileItem
{
    public string FilePath { get; }
    public string FileName => Path.GetFileName(FilePath);
    public long FileSize { get; }
    public TimeSpan Duration { get; set; }
    public bool IsProcessed { get; set; }

    public string DurationText => Duration.ToString(Duration.TotalHours >= 1 ? @"hh\:mm\:ss" : @"mm\:ss");

    public AudioFileItem(string filePath)
    {
        FilePath = filePath;
        if (File.Exists(filePath))
        {
            FileInfo fi = new(filePath);
            FileSize = fi.Length;
        }
    }
}
