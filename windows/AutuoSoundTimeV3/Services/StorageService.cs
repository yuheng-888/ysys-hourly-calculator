using System;
using System.IO;
using System.Text.Json;

namespace AutoSoundTimeV3.Services;

public static class StorageService
{
    private static readonly string BaseDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "Ysys",
        "AutoSoundTimeV3");

    public static T Load<T>(string fileName, T fallback) where T : class
    {
        try
        {
            string path = Path.Combine(BaseDir, fileName);
            if (!File.Exists(path)) return fallback;
            string json = File.ReadAllText(path);
            T? obj = JsonSerializer.Deserialize<T>(json);
            return obj ?? fallback;
        }
        catch
        {
            return fallback;
        }
    }

    public static void Save<T>(string fileName, T data)
    {
        Directory.CreateDirectory(BaseDir);
        string path = Path.Combine(BaseDir, fileName);
        string json = JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(path, json);
    }
}
