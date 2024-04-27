using System.Diagnostics;

public static class PyForexLibrary
{
    private static Process _process = null;

    public static void CreateProcess(string commandLine, string commonFolder)
    {
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = $"{commandLine} {commonFolder}";
        _process = Process.Start(startInfo);
    }

    public static void TerminateProcess()
    {
        _process.Close();
        _process.Dispose();
        _process = null;
    }
}
