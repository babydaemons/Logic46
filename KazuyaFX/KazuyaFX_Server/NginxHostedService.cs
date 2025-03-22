using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Diagnostics;

public class NginxHostedService : IHostedService
{
    private readonly ILogger<NginxHostedService> _logger;
    private readonly string _nginxPath;
    private Process? _nginxProcess;

    public NginxHostedService(ILogger<NginxHostedService> logger, IConfiguration configuration)
    {
        _logger = logger;
        _nginxPath = configuration["NginxPath"] ?? throw new ArgumentException("NginxPath が設定されていません");
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        try
        {
            _nginxProcess = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = _nginxPath,
                    WorkingDirectory = Path.GetDirectoryName(_nginxPath),
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };
            _nginxProcess.Start();
            _logger.LogInformation("nginx を起動しました。");
        }
        catch (Exception ex)
        {
            _logger.LogError($"nginx 起動失敗: {ex.Message}");
        }

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        try
        {
            if (_nginxProcess != null && !_nginxProcess.HasExited)
            {
                _nginxProcess.Kill(true);
                _nginxProcess.WaitForExit();
                _logger.LogInformation("nginx を終了しました。");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError($"nginx 終了失敗: {ex.Message}");
        }

        return Task.CompletedTask;
    }
}
