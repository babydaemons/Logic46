using System.Diagnostics;
using TradeTransmitterServer;
namespace TradeTransmitter;

class Program
{
    static async Task Main(string[] args)
    {
        ServerLogger.WriteLine($"�g���[�h��M�T�[�o�[���N�����܂����B");

        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddControllers();

        var app = builder.Build();

        app.UseRouting();

        app.MapControllers();

        // �T�[�o�[��񓯊��Ŏ��s
        var hostTask = app.RunAsync();

        // ���̒��{�̏T���̐[��2�����v�Z
        var targetTime = GetNextMidMonthWeekendMidnight();

        // �w�莞���܂ł̎c�莞�Ԃ��v�Z
        var delay = targetTime - DateTime.Now;
        if (delay < TimeSpan.Zero)
        {
            ServerLogger.WriteLine("�w�肵�������͂��łɉ߂��Ă��܂��B");
            return;
        }

        Console.WriteLine($"�g���[�h��M�T�[�o�[�� {targetTime} �ɏI�����܂��B");

        // �w�莞���܂őҋ@
        await Task.Delay(delay);

        // �T�[�o�[���~
        ServerLogger.WriteLine("�T�[�o�[���I�����܂�...");
        await app.StopAsync();

        // �T�[�o�[�^�X�N��ҋ@���Ċ��S�ɏI��
        await hostTask;

        // certbot.exe �����s
        Console.WriteLine("Certbot �����s��...");
        var certbotExitCode = RunCertbot();
        if (certbotExitCode != 0)
        {
            Console.WriteLine($"Certbot ���s���ɃG���[���������܂����B�I���R�[�h: {certbotExitCode}");
            return;
        }
        Console.WriteLine("Certbot �̎��s���������܂����B");

        // OS ���ċN��
        Console.WriteLine("OS ���ċN�����܂�...");
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
