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
                // �����̃��O�v���o�C�_�[���N���A
                logging.ClearProviders();

                // Kestrel (Microsoft.*) ���O���t�@�C���ɏo��
                logging.AddFilter("Microsoft", LogLevel.Information); // Microsoft �n�̃��O���x����ݒ�
                logging.AddFile("Logs/kestrel-{Date}.log", LogLevel.Information); // �t�@�C���ɏo��

                // �A�v���P�[�V�����ŗL�̃��O���R���\�[���ɏo��
                logging.AddFilter("TradeTransmitter", LogLevel.Information); // �A�v�����Ńt�B���^�����O
                logging.AddConsole(configure => configure.TimestampFormat = "[yyyy-MM-dd HH:mm:ss] ");
            })
            .ConfigureWebHostDefaults(webBuilder =>
            {
                // Web�A�v���P�[�V�����̐ݒ�
                webBuilder.Configure(app =>
                {
                    app.UseRouting();
                    logger = app.ApplicationServices.GetService<ILogger<Program>>();
                    logger?.LogInformation($"�g���[�h��M�T�[�o�[���N�����܂����B");
                    app.Run(async context =>
                    {
                        logger?.LogInformation("HTTP request received at {Time}", DateTime.Now);
                        await context.Response.WriteAsync("Hello, World!");
                    });
                });
            })
            .Build();

        // �T�[�o�[��񓯊��Ŏ��s
        var task = host.RunAsync();

        // ���̒��{�̏T���̐[��2�����v�Z
        var targetTime = GetNextMidMonthWeekendMidnight();

        // �w�莞���܂ł̎c�莞�Ԃ��v�Z
        var delay = targetTime - DateTime.Now;
        if (delay < TimeSpan.Zero)
        {
            logger?.LogInformation("�w�肵�������͂��łɉ߂��Ă��܂��B");
            return;
        }

        logger?.LogInformation($"�g���[�h��M�T�[�o�[�� {targetTime} �ɏI�����܂��B");

        // �w�莞���܂őҋ@
        await Task.Delay(delay);

        // �T�[�o�[���~
        logger?.LogInformation("�T�[�o�[���I�����܂�...");
        task.Wait();

        // certbot.exe �����s
        logger?.LogInformation("Certbot �����s��...");
        var certbotExitCode = RunCertbot();
        if (certbotExitCode != 0)
        {
            logger?.LogInformation($"Certbot ���s���ɃG���[���������܂����B�I���R�[�h: {certbotExitCode}");
            return;
        }
        logger?.LogInformation("Certbot �̎��s���������܂����B");

        // OS ���ċN��
        logger?.LogInformation("OS ���ċN�����܂�...");
        RestartOS();
    }

    // ���̒��{�̏T���̐[��2�����擾
    private static DateTime GetNextMidMonthWeekendMidnight()
    {
        var now = DateTime.Now;
        var today = now.Date;

        // ���{�̒�`�i15���`25���j
        var isMidMonth = today.Day >= 15 && today.Day <= 25;

        // ���������{�̏T���̏ꍇ�A���̓����g��
        if (isMidMonth && (today.DayOfWeek == DayOfWeek.Saturday || today.DayOfWeek == DayOfWeek.Sunday))
        {
            return today.AddHours(26); // �[��2��
        }

        // ���̌����܂߂��u���{�̏T���v��T��
        for (var date = today.AddDays(1); ; date = date.AddDays(1))
        {
            var isNextMidMonth = date.Day >= 10 && date.Day <= 20;
            var isWeekend = date.DayOfWeek == DayOfWeek.Saturday || date.DayOfWeek == DayOfWeek.Sunday;

            if (isNextMidMonth && isWeekend)
            {
                return date.AddHours(26); // �[��2��
            }
        }
    }

    // certbot.exe �����s����
    private static int RunCertbot()
    {
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = @"C:\Certbot\bin\certbot.exe",
                    Arguments = "renew", // �K�v�ɉ����Ĉ������w��
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.Start();

            // �o�͂��擾���ĕ\��
            string output = process.StandardOutput.ReadToEnd();
            string error = process.StandardError.ReadToEnd();
            Console.WriteLine(output);
            Console.Error.WriteLine(error);

            process.WaitForExit(); // �v���Z�X�I����ҋ@
            return process.ExitCode; // �I���R�[�h��Ԃ�
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Certbot ���s���ɃG���[: {ex.Message}");
            return -1; // �ُ�I���R�[�h��Ԃ�
        }
    }

    // OS ���ċN������
    private static void RestartOS()
    {
        try
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "shutdown",
                    Arguments = "/r /t 0", // �����ċN��
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.Start();
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"OS �ċN�����ɃG���[: {ex.Message}");
        }
    }
}
