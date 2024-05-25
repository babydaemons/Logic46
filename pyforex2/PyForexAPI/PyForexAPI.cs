using System;
using System.Diagnostics;
using System.Threading;

public class PyForexAPI
{
    private static Process _process = null;

    /// <summary>
    /// プロセスを起動します
    /// </summary>
    /// <param name="commandLine">プロセスのフルパス</param>
    /// <param name="commonFolderPath">commonフォルダのフルパス</param>
    /// <param name="pipeName">名前付きパイプ名</param>
    /// <param name="predictMinutes">予測する未来の時間幅</param>
    /// <param name="barCount">予測に使う過去のバーの本数</param>
    public static void CreateProcess(string commandLine, string commonFolderPath, string pipeName, int predictMinutes, int barCount)
    {
        if (_process != null)
        {
            TerminateProcess();
        }
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = commandLine;
        startInfo.Arguments = $"{commonFolderPath} {pipeName} {predictMinutes} {barCount}";
        Console.WriteLine(startInfo.Arguments);
        _process = Process.Start(startInfo);
    }

    public static void TerminateProcess()
    {
        if (_process != null)
        {
            _process.Kill();
            _process.Dispose();
            _process = null;
        }
    }

    public static void Sleep(int milliseconds)
    {
        Thread.Sleep(milliseconds);
    }
}
