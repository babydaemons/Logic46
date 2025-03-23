﻿using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using System.Diagnostics;

public class NginxHostedService : IHostedService
{
    private readonly string _nginxPath;
    private Process? _nginxProcess;

    public NginxHostedService(IConfiguration configuration)
    {
        _nginxPath = configuration["NginxPath"] ?? throw new ArgumentException("NginxPath が設定されていません");

        var mode = configuration["Logger:Mode"] ?? "Console";
        Logger.SetMode(mode);
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
            Logger.Log(Color.GREEN, "nginx を起動しました。");
        }
        catch (Exception ex)
        {
            Logger.Log(Color.RED, $"nginx 起動失敗: {ex.Message}");
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
                Logger.Log(Color.YELLOW, "nginx を終了しました。");
            }
        }
        catch (Exception ex)
        {
            Logger.Log(Color.RED, $"nginx 終了失敗: {ex.Message}");
        }

        return Task.CompletedTask;
    }
}
