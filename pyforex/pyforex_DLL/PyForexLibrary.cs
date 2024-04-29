using System.Diagnostics;
using System.IO;
using System.Threading;

public static class PyForexLibrary
{
    private static Process _process = null;
    private static string _commonFolder = string.Empty;

    public static void CreateProcess(string commandLine, string commonFolder)
    {
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = commandLine;
        startInfo.Arguments = commonFolder;
        _process = Process.Start(startInfo);
        _commonFolder = commonFolder + "\\Files\\pyforex";
    }

    public static void Learning(double[] values)
    {
        var request_path = _commonFolder + "\\pyforex-learning.bin";
        using (var stream = new FileStream(request_path, FileMode.Create))
        {
            using (var writer = new BinaryWriter(stream))
            {
                foreach (var value in values)
                {
                    writer.Write(value);
                }
            }
        }

        while (File.Exists(request_path))
        {
            Thread.Sleep(100);
        }
    }

    public static double Predict(double[] values)
    {
        var request_path = _commonFolder + "\\pyforex-predict.bin";
        using (var stream = new FileStream(request_path, FileMode.Create))
        {
            using (var writer = new BinaryWriter(stream))
            {
                foreach (var value in values)
                {
                    writer.Write(value);
                }
            }
        }

        var response_path = _commonFolder + "\\pyforex-result.txt";
        while (!File.Exists(response_path))
        {
            Thread.Sleep(10);
        }

        double predict_value;
        using (var reader = new StreamReader(response_path))
        {
            var line = reader.ReadLine();
            double.TryParse(line, out predict_value);
        }

        File.Delete(response_path);

        return predict_value;
    }

    public static void TerminateProcess()
    {
        _process.Close();
        _process.Dispose();
        _process = null;
    }
}
