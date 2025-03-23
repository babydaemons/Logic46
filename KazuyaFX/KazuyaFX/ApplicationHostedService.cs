﻿using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using System.Diagnostics;

public class ApplicationHostedService : IHostedService
{
    private readonly string _appPath;
    private readonly string _appName;
    private Process? _appProcess;

    public ApplicationHostedService(IConfiguration configuration)
    {
        _appPath = configuration["Application:Path"] ?? throw new ArgumentException("Application:Path が設定されていません");
        _appName = configuration["Application:Name"] ?? throw new ArgumentException("Application:Name が設定されていません");

        var mode = configuration["Logger:Mode"] ?? "Console";
        Logger.SetMode(mode);
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        try
        {
            _appProcess = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = _appPath,
                    WorkingDirectory = Path.GetDirectoryName(_appPath),
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };
            _appProcess.Start();
            Logger.Log(Color.GREEN, $"{_appName} を起動しました。");
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
