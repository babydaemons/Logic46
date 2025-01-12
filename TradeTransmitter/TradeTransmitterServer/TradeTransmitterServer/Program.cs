using System.Diagnostics;
namespace TradeTransmitterServer;

public class Program
{
    [Obsolete]
    public static async Task Main(string[] args)
    {
        ILogger<Program>? logger = null;
        var host = Host.CreateDefaultBuilder(args)
            .ConfigureLogging(logging =>
            {
                // 既存のログプロバイダーをクリア
                logging.ClearProviders();

                // Kestrel (Microsoft.*) ログをファイルに出力
                logging.AddFilter("Microsoft", LogLevel.Information); // Microsoft 系のログレベルを設定
                logging.AddFile("Logs/kestrel-{Date}.log", LogLevel.Information); // ファイルに出力

                // アプリケーション固有のログをコンソールに出力
                logging.AddFilter("TradeTransmitter", LogLevel.Information); // アプリ名でフィルタリング
                logging.AddConsole(configure => configure.TimestampFormat = "[yyyy-MM-dd HH:mm:ss] ");
            })
            .ConfigureWebHostDefaults(webBuilder =>
            {
                // Webアプリケーションの設定
                webBuilder.Configure(app =>
                {
                    app.UseRouting();
                    logger = app.ApplicationServices.GetService<ILogger<Program>>();
                    logger?.LogInformation($"トレード受信サーバーが起動しました。");
                    app.Run(async context =>
                    {
                        logger?.LogInformation("HTTP request received at {Time}", DateTime.Now);
                        await context.Response.WriteAsync("Hello, World!");
                    });
                });
            })
            .Build();

        // サーバーを非同期で実行
        var task = host.RunAsync();

        // 次の中旬の週末の深夜2時を計算
        var targetTime = GetNextMidMonthWeekendMidnight();

        // 指定時刻までの残り時間を計算
        var delay = targetTime - DateTime.Now;
        if (delay < TimeSpan.Zero)
        {
            logger?.LogInformation("指定した時刻はすでに過ぎています。");
            return;
        }

        logger?.LogInformation($"トレード受信サーバーは {targetTime} に終了します。");

        // 指定時刻まで待機
        await Task.Delay(delay);

        // サーバーを停止
        logger?.LogInformation("サーバーを終了します...");
        task.Wait();

        // certbot.exe を実行
        logger?.LogInformation("Certbot を実行中...");
        var certbotExitCode = RunCertbot();
        if (certbotExitCode != 0)
        {
            logger?.LogInformation($"Certbot 実行中にエラーが発生しました。終了コード: {certbotExitCode}");
            return;
        }
        logger?.LogInformation("Certbot の実行が完了しました。");

        // OS を再起動
        logger?.LogInformation("OS を再起動します...");
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
