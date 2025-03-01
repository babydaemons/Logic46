using System;
using System.Diagnostics;

public static class Installer
{
    public const string ESCAPE = "\x1b";
    public const string RESET = ESCAPE + "[0m";
    public const string GREEN = ESCAPE + "[32m";
    public const string YELLOW = ESCAPE + "[33m";
    public const string RED = ESCAPE + "[31m";
    public const string CYAN = ESCAPE + "[36m";
    public const string BLUE = ESCAPE + "[34m";

    private static DateTime startAt = DateTime.Now;
    private static Stopwatch stopwatch = Stopwatch.StartNew();

    public static string GetTimestamp() => (startAt + stopwatch.Elapsed).ToString("yyyy-MM-dd HH:mm:ss.fffffff");

    public static void SetupFirewallRule()
    {
        // ポート80,443用のルールを追加 (TCP)
        AddFirewallRule("HTTP Port 80", 80, "TCP");
        AddFirewallRule("HTTPS Port 443", 443, "TCP");
    }

    /// <summary>
    /// netsh を呼び出して、指定したポートのインバウンド通信を許可するルールを追加する
    /// </summary>
    /// <param name="ruleName">ルール名</param>
    /// <param name="port">許可したいポート番号</param>
    /// <param name="protocol">プロトコル(TCP/UDPなど)</param>
    public static void AddFirewallRule(string ruleName, int port, string protocol)
    {
        // 例: netsh advfirewall firewall add rule name="HTTP Port 80" dir=in action=allow protocol=TCP localport=80
        var arguments = $"advfirewall firewall add rule name=\"{ruleName}\" " +
                        $"dir=in action=allow protocol={protocol} localport={port}";

        Console.WriteLine($"{BLUE}[{GetTimestamp()}] ファイアウォールの規則を追加しています: '{arguments}'{RESET}");

        // netsh を外部プロセスとして起動
        var startInfo = new ProcessStartInfo
        {
            FileName = "netsh",
            Arguments = arguments,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };

        // 実行
        using (var process = Process.Start(startInfo))
        {
            if (process == null)
            {
                Console.WriteLine($"{RED}[{GetTimestamp()}] Failed to start netsh process.{RESET}");
                Environment.Exit(1);
            }

            // 終了まで待機して出力を読み取る
            process.WaitForExit();
            var output = process.StandardOutput.ReadToEnd();
            var error = process.StandardError.ReadToEnd();

            // 結果を表示
            if (process.ExitCode == 0)
            {
                Console.WriteLine($"{BLUE}[{GetTimestamp()}] ファイアウォールの規則を追加しました: '{ruleName}': {output.Trim()}{RESET}");
            }
            else
            {
                Console.WriteLine($"{RED}[{GetTimestamp()}] Failed to add rule '{ruleName}'. ExitCode: {process.ExitCode}{RESET}");
                if (!string.IsNullOrWhiteSpace(error))
                {
                    Console.WriteLine($"{RED}[{GetTimestamp()}] {error}{RESET}");
                }
                Environment.Exit(1);
            }
        }
    }
}
