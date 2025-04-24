﻿using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using System.Diagnostics;

public class CertificateRenewService : IHostedService
{
    private readonly string _appPath;
    private readonly string _appName;
    private Process? _appProcess;

    public CertificateRenewService(IConfiguration configuration)
    {
        _appPath = configuration["Certification:Path"] ?? throw new ArgumentException("Certification:Path が設定されていません");
        _appName = configuration["Certification:Name"] ?? throw new ArgumentException("Certification:Name が設定されていません");

        var mode = configuration["Logger:Mode"] ?? "Console";
        Logger.SetMode(mode);
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        try
        {
            Logger.Log(Color.GREEN, $"証明書を更新します: {_appName} を起動しました。");
            _appProcess = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = _appPath,
                    Arguments = "--renew",
                    WorkingDirectory = Path.GetDirectoryName(_appPath),
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                }
            };
            _appProcess.Start();

            // 出力受信用のイベントハンドラを登録
            _appProcess.OutputDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                    Logger.Log(Color.BLUE, $"{e.Data}");
            };

            _appProcess.ErrorDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                    Logger.Log(Color.RED, $"{e.Data}");
            };

            _appProcess.Start();

            // 非同期で出力を読み始める
            _appProcess.BeginOutputReadLine();
            _appProcess.BeginErrorReadLine();

            _appProcess.WaitForExitAsync(cancellationToken);  // .NET 5 以降
        }
        catch (Exception ex)
        {
            Logger.Log(Color.RED, $"{_appName} 起動失敗: {ex.Message}");
        }

        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        try
        {
            if (_appProcess != null && !_appProcess.HasExited)
            {
                _appProcess.Kill(true);
                _appProcess.WaitForExit();
                Logger.Log(Color.YELLOW, $"{_appName} を終了しました。");
            }
        }
        catch (Exception ex)
        {
            Logger.Log(Color.RED, $"{_appName} 終了失敗: {ex.Message}");
        }

        return Task.CompletedTask;
    }
}
