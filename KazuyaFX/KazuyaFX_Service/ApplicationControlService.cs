using System.Diagnostics;

namespace KazuyaFX_Service;

public class ApplicationControlService : BackgroundService
{
    private readonly ILogger<ApplicationControlService> _logger;
    private readonly string _appPath;
    private Process? _process;

    public ApplicationControlService(ILogger<ApplicationControlService> logger, string appPath)
    {
        _logger = logger;
        _appPath = appPath;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation($"アプリ {_appPath} の監視サービスを開始します。");

        await StartProcessAsync();

        while (!stoppingToken.IsCancellationRequested)
        {
            if (_process == null || _process.HasExited)
            {
                _logger.LogWarning($"{_appPath} が終了しました。再起動します...");
                await StartProcessAsync();
            }

            await Task.Delay(5000, stoppingToken);
        }

        _logger.LogInformation($"{_appPath} のサービスを停止しています...");
        StopProcess();
    }

    private async Task StartProcessAsync()
    {
        await Task.Run(() =>
        {
            try
            {
                _process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = _appPath,
                        WorkingDirectory = Path.GetDirectoryName(_appPath),
                        UseShellExecute = false,
                        CreateNoWindow = true
                    }
                };
                _process.Start();
                _logger.LogInformation($"プロセス {_appPath} を起動しました。");
            }
            catch (Exception ex)
            {
                _logger.LogError($"プロセス {_appPath} の起動に失敗: {ex.Message}");
            }
        });
    }

    private void StopProcess()
    {
        if (_process != null && !_process.HasExited)
        {
            _process.Kill();
            _process.WaitForExit();
            _logger.LogInformation($"プロセス {_appPath} を終了しました。");
        }
    }

    public override void Dispose()
    {
        StopProcess();
        base.Dispose();
    }
}
