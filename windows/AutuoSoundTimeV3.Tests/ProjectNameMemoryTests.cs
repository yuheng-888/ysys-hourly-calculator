using AutoSoundTimeV3.Services;

namespace AutoSoundTimeV3.Tests;

public class ProjectNameMemoryTests
{
    [Fact]
    public void PrefilledProjectNameFallsBackToRememberedValueWhenCurrentInputIsBlank()
    {
        string resolved = ProjectNameMemory.PrefilledProjectName("   ", "有声书A");

        Assert.Equal("有声书A", resolved);
    }

    [Fact]
    public void PrefilledProjectNameKeepsCurrentInputWhenPresent()
    {
        string resolved = ProjectNameMemory.PrefilledProjectName("新项目", "旧项目");

        Assert.Equal("新项目", resolved);
    }

    [Fact]
    public void RememberedProjectNameTrimsWhitespaceAndRejectsBlankValues()
    {
        string? remembered = ProjectNameMemory.RememberedProjectName("  新项目  ");
        string? ignored = ProjectNameMemory.RememberedProjectName("   ");

        Assert.Equal("新项目", remembered);
        Assert.Null(ignored);
    }
}
