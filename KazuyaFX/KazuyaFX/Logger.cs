﻿using System.Diagnostics;
using System.IO;

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

    private static string _mode = "Console"; // または "File"
    private static readonly string _logFilePath = Path.Combine(AppContext.BaseDirectory, "log.txt");
    private static readonly object _lock = new();

    public static void SetMode(string mode)
    {
        _mode = mode;
    }

    public static void Log(Color color, string message)
    {
        string line = $"[{Timestamp}] {message}";

        if (_mode == "Console")
        {
            string ESCAPE = "\x1b";
            string RESET = ESCAPE + "[0m";
            Console.WriteLine($"{ESCAPE}[{(int)color}m{line}{RESET}");
        }
        else if (_mode == "File")
        {
            lock (_lock)
            {
                File.AppendAllText(_logFilePath, line + Environment.NewLine);
            }
        }
    }
}
