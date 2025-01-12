using System.Diagnostics;
using TradeTransmitterServer;
namespace TradeTransmitter;

class Program
{
    static async Task Main(string[] args)
    {
        ServerLogger.WriteLine($"トレード受信サーバーが起動しました。");

        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddControllers();

        var app = builder.Build();

        app.UseRouting();

        app.MapControllers();

        // サーバーを非同期で実行
        var hostTask = app.RunAsync();

        // 次の中旬の週末の深夜2時を計算
        var targetTime = GetNextMidMonthWeekendMidnight();

        // 指定時刻までの残り時間を計算
        var delay = targetTime - DateTime.Now;
        if (delay < TimeSpan.Zero)
        {
            ServerLogger.WriteLine("指定した時刻はすでに過ぎています。");
            return;
        }

        Console.WriteLine($"トレード受信サーバーは {targetTime} に終了します。");

        // 指定時刻まで待機
        await Task.Delay(delay);

        // サーバーを停止
        ServerLogger.WriteLine("サーバーを終了します...");
        await app.StopAsync();

        // サーバータスクを待機して完全に終了
        await hostTask;

        // certbot.exe を実行
        Console.WriteLine("Certbot を実行中...");
        var certbotExitCode = RunCertbot();
        if (certbotExitCode != 0)
        {
            Console.WriteLine($"Certbot 実行中にエラーが発生しました。終了コード: {certbotExitCode}");
            return;
        }
        Console.WriteLine("Certbot の実行が完了しました。");

        // OS を再起動
        Console.WriteLine("OS を再起動します...");
        RestartOS();
    }

    // 次の中旬の週末の深夜2時を取得
    private static DateTime GetNextMidMonthWeekendMidnight()
    {
        var now = DateTime.Now;
        var today = now.Date;

        // 中旬の定義（15日～25日）
        var isMidMonth = today.Day >= 15 && today.Day <= 25;

        // 今日が中旬の週末の場合、その日を使う
        if (isMidMonth && (today.DayOfWeek == DayOfWeek.Saturday || today.DayOfWeek == DayOfWeek.Sunday))
        {
            return today.AddHours(26); // 深夜2時
        }

        // 次の月を含めた「中旬の週末」を探す
        for (var date = today.AddDays(1); ; date = date.AddDays(1))
        {
            var isNextMidMonth = date.Day >= 10 && date.Day <= 20;
            var isWeekend = date.DayOfWeek == DayOfWeek.Saturday || date.DayOfWeek == DayOfWeek.Sunday;

            if (isNextMidMonth && isWeekend)
            {
                return date.AddHours(26); // 深夜2時
            }
        }
    }

    // certbot.exe を実行する
    private static int RunCertbot()
    {
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = @"C:\Certbot\bin\certbot.exe",
                    Arguments = "renew", // 必要に応じて引数を指定
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.Start();

            // 出力を取得して表示
            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();
            Console.WriteLine(output);
            Console.Error.WriteLine(error);

            process.WaitForExit(); // プロセス終了を待機
            return process.ExitCode; // 終了コードを返す
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Certbot 実行中にエラー: {ex.Message}");
            return -1; // 異常終了コードを返す
        }
    }

    // OS を再起動する
    private static void RestartOS()
    {
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "shutdown",
                    Arguments = "/r /t 0", // 即時再起動
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.Start();
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"OS 再起動中にエラー: {ex.Message}");
        }
    }
}
