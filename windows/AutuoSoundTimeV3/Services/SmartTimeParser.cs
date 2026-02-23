using System.Linq;

namespace AutoSoundTimeV3.Services;

public static class SmartTimeParser
{
    public static (string hours, string minutes, string seconds) Parse(string input)
    {
        string digits = new(input.Where(char.IsDigit).ToArray());
        if (string.IsNullOrEmpty(digits)) return ("", "", "");

        string h = "", m = "", s = "";

        switch (digits.Length)
        {
            case 1:
            case 2:
                s = digits;
                m = "0";
                h = "0";
                break;
            case 3:
                m = digits[..1];
                s = digits[1..];
                h = "0";
                break;
            case 4:
                m = digits[..2];
                s = digits[2..];
                h = "0";
                break;
            case 5:
                h = digits[..1];
                m = digits[1..3];
                s = digits[3..];
                break;
            default:
                int hLen = digits.Length - 4;
                h = digits[..hLen];
                m = digits[hLen..(hLen + 2)];
                s = digits[(hLen + 2)..];
                break;
        }

        return (h, m, s);
    }
}
