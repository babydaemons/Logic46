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
        _logger.LogInformation("�T�[�r�X���J�n���܂����B");

        // EXE���N��
        StartProcesses();

        while (!stoppingToken.IsCancellationRequested)
        {
            // �v���Z�X�̊Ď�
            CheckProcesses();

            await Task.Delay(5000, stoppingToken); // 5�b���ƂɃ`�F�b�N
        }

        _logger.LogInformation("�T�[�r�X���~���Ă��܂�...");
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
            _logger.LogInformation($"�v���Z�X {path} ���N�����܂����B");
            return process;
        }
        catch (Exception ex)
        {
            _logger.LogError($"�v���Z�X {path} �̋N���Ɏ��s: {ex.Message}");
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
            _logger.LogInformation($"�v���Z�X {process.StartInfo.FileName} ���I�����܂����B");
        }
    }

    private void CheckProcesses()
    {
        if (_process1 == null || _process1.HasExited)
        {
            _logger.LogWarning($"{App1Path} ���I�����܂����B�ċN�����܂�...");
            _process1 = StartProcess(App2Path);
        }

        if (_process2 == null || _process2.HasExited)
        {
            _logger.LogWarning($"{App2Path} ���I�����܂����B�ċN�����܂�...");
            _process2 = StartProcess(App2Path);
        }
    }

    public override void Dispose()
    {
        StopProcesses();
        base.Dispose();
    }
}
