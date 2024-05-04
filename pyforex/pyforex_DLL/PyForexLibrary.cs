using System;
using System.Diagnostics;
using System.Threading;

public static class PyForexLibrary
{
    private static Process _process = null;

    public static void CreateProcess(string commandLine, string commonFolderPath, string pipeName)
    {
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = commandLine;
        startInfo.Arguments = $"{commonFolderPath} {pipeName}";
        Console.WriteLine(startInfo.Arguments);
        _process = Process.Start(startInfo);
    }

    public static void TerminateProcess()
    {
        _process.Close();
        _process.Dispose();
        _process = null;
    }

    public static void Sleep(int milliseconds)
    {
        Thread.Sleep(milliseconds);
    }
}
