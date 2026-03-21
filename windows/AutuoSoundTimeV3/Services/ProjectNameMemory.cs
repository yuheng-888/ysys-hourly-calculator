namespace AutoSoundTimeV3.Services;

public static class ProjectNameMemory
{
    public static string PrefilledProjectName(string currentInput, string rememberedProjectName)
    {
        return RememberedProjectName(currentInput)
            ?? RememberedProjectName(rememberedProjectName)
            ?? string.Empty;
    }

    public static string? RememberedProjectName(string projectName)
    {
        string trimmedProjectName = projectName.Trim();
        return trimmedProjectName.Length == 0 ? null : trimmedProjectName;
    }
}
