using System.Diagnostics;

public static class Installer
{
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

        Logger.Log(Color.BLUE, $"ファイアウォールの規則を追加しています: '{arguments}'");

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
                Logger.Log(Color.RED, "Failed to start netsh process.");
                Environment.Exit(1);
            }

            // 終了まで待機して出力を読み取る
            process.WaitForExit();
            var output = process.StandardOutput.ReadToEnd();
            var error = process.StandardError.ReadToEnd();

            // 結果を表示
            if (process.ExitCode == 0)
            {
                Logger.Log(Color.BLUE, $"ファイアウォールの規則を追加しました: '{ruleName}': {output.Trim()}");
            }
            else
            {
                Logger.Log(Color.RED, $"ファイアウォールの規則を追加しました: '{ruleName}'. ExitCode: {process.ExitCode}");
                if (!string.IsNullOrWhiteSpace(error))
                {
                    Logger.Log(Color.RED, $"{error}");
                }
                Environment.Exit(1);
            }
        }
    }
}
