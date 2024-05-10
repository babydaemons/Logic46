using System;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class PyForexLibrary
{
    private static Process _process = null;
    private static NamedPipeClientStream _pipeStream = null;

    public static void CreateProcess(string commandLine, string commonFolderPath, string pipeName)
    {
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = commandLine;
        startInfo.Arguments = $"{commonFolderPath} {pipeName}";
        Console.WriteLine(startInfo.Arguments);
        _process = Process.Start(startInfo);

        var pipeFullPath = $"\\\\.\\pipe\\pyforex_{pipeName}";
        while (true)
        {
            try
            {
                _pipeStream = new NamedPipeClientStream(pipeFullPath);
                _pipeStream.Connect();
                break;
            }
            catch (Exception)
            {

            }
        }
    }

    public static string HandshakeOnce(string request_text, int N, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] double[] values)
    {
        var requests = request_text.Split(',');
        string request = requests[0];
        var command = new StreamString(_pipeStream);
        command.WriteString($"{request},{N * 8}\n");

        var stream = new MemoryStream();
        foreach (var value in values)
        {
            stream.Write(BitConverter.GetBytes(value), 0, 8);
        }
        _pipeStream.Write(stream.ToArray(), 0, (int)stream.Length);

        string response;
        using (var reader = new StreamReader(_pipeStream)) 
        {
            response = reader.ReadLine();
            while (response.StartsWith("KEEP_ALIVE"))
            {
                Thread.Sleep(10);
                continue;
            }
        }
        return "";
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

// MSサンプルそのまま(streamに文字列を読み書きしてくれるクラス)
internal class StreamString
{
    private Stream ioStream;
    private UnicodeEncoding streamEncoding;

    public StreamString(Stream ioStream)
    {
        this.ioStream = ioStream;
        streamEncoding = new UnicodeEncoding();
    }

    public string ReadString()
    {
        int len = 0;

        len = ioStream.ReadByte() * 256;
        len += ioStream.ReadByte();
        byte[] inBuffer = new byte[len];
        ioStream.Read(inBuffer, 0, len);

        return streamEncoding.GetString(inBuffer);
    }

    public int WriteString(string outString)
    {
        byte[] outBuffer = streamEncoding.GetBytes(outString);
        int len = outBuffer.Length;
        if (len > UInt16.MaxValue)
        {
            len = (int)UInt16.MaxValue;
        }
        ioStream.WriteByte((byte)(len / 256));
        ioStream.WriteByte((byte)(len & 255));
        ioStream.Write(outBuffer, 0, len);
        ioStream.Flush();

        return outBuffer.Length + 2;
    }
}
