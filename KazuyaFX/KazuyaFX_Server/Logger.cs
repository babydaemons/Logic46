using System.Diagnostics;

public enum Color
{
    RED = 31,
    GREEN = 32,
    YELLOW = 33,
    BLUE = 34,
    CYAN = 36,
}

public static class Logger
{
    private static DateTime startAt = DateTime.Now;
    private static Stopwatch stopwatch = Stopwatch.StartNew();
    private static string Timestamp => (startAt + stopwatch.Elapsed).ToString("yyyy-MM-dd HH:mm:ss.fffffff");


    public static void Log(Color color, string message)
    {
        string ESCAPE = "\x1b";
        string RESET = ESCAPE + "[0m";
        Console.WriteLine($"{ESCAPE}[{(int)color}m[{Timestamp}] {message}{RESET}");
    }
}
