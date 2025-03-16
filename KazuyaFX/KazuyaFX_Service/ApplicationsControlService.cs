using System.Diagnostics;

namespace KazuyaFX_Service;

public class ApplicationsControlService : BackgroundService
{
    public const string App1Path = @"C:\KazuyaFX\nginx\nginx.exe";
    public const string App2Path = @"C:\KazuyaFX\kestrel\KzauyaFX_Server.exe";

    private readonly ILogger<ApplicationsControlService> _logger;
    private Process? _process1;
    private Process? _process2;

    public ApplicationsControlService(ILogger<ApplicationsControlService> logger)
    {
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("サービスを開始しました。");

        // EXEを起動
        StartProcesses();

        while (!stoppingToken.IsCancellationRequested)
        {
            // プロセスの監視
            CheckProcesses();

            await Task.Delay(5000, stoppingToken); // 5秒ごとにチェック
        }

        _logger.LogInformation("サービスを停止しています...");
        StopProcesses();
    }

    private void StartProcesses()
    {
        _process2 = StartProcess(App1Path);
        _process1 = StartProcess(App2Path);
    }

    private Process? StartProcess(string path)
    {
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = path,
                    WorkingDirectory = Path.GetDirectoryName(path),
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };
            process.Start();
            _logger.LogInformation($"プロセス {path} を起動しました。");
            return process;
        }
        catch (Exception ex)
        {
            _logger.LogError($"プロセス {path} の起動に失敗: {ex.Message}");
            return null;
        }
    }

    private void StopProcesses()
    {
        if (_process1 != null)
        {
            StopProcess(_process1);
        }
        if (_process2 != null)
        {
            StopProcess(_process2);
        }
    }

    private void StopProcess(Process? process)
    {
        if (process != null && !process.HasExited)
        {
            process.Kill();
            process.WaitForExit();
            _logger.LogInformation($"プロセス {process.StartInfo.FileName} を終了しました。");
        }
    }

    private void CheckProcesses()
    {
        if (_process1 == null || _process1.HasExited)
        {
            _logger.LogWarning($"{App1Path} が終了しました。再起動します...");
            _process1 = StartProcess(App2Path);
        }

        if (_process2 == null || _process2.HasExited)
        {
            _logger.LogWarning($"{App2Path} が終了しました。再起動します...");
            _process2 = StartProcess(App2Path);
        }
    }

    public override void Dispose()
    {
        StopProcesses();
        base.Dispose();
    }
}
