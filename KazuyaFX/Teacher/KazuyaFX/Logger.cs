﻿using System.Diagnostics;
using System.IO;
using Microsoft.Extensions.Configuration;

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

    private static string _mode = "Both"; // Console / File / Both
    private static string? _logFilePath;
    private static readonly object _lock = new();

    public static void Configure(IConfiguration config)
    {
        _mode = config["Logger:Mode"] ?? "Both";

        if (_mode is "File" or "Both")
        {
            var logDir = config["Logger:Directory"] ?? Path.Combine(AppContext.BaseDirectory, "logs");
            Directory.CreateDirectory(logDir);

            var time = DateTime.Now.ToString("yyyyMMdd-HHmm");
            var fileName = $"KazuyaFX-{time}.log";
            _logFilePath = Path.Combine(logDir, fileName);
        }
    }

    public static void SetMode(string mode) => _mode = mode;

    public static void Log(Color color, string message)
    {
        string line = $"[{Timestamp}] {message}";

        if (_mode is "Console" or "Both")
        {
            string ESCAPE = "\x1b";
            string RESET = ESCAPE + "[0m";
            Console.WriteLine($"{ESCAPE}[{(int)color}m{line}{RESET}");
        }

        if ((_mode is "File" or "Both") && _logFilePath != null)
        {
            lock (_lock)
            {
                File.AppendAllText(_logFilePath, line + Environment.NewLine);
            }
        }
    }
}
