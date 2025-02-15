namespace TradeTransmitterServer;

public static class ServerLogger
{
    private static string _path = @"..\log\" + DateTime.Now.ToString("yyyyMMdd-HHmm") + ".log";
    private static StreamWriter? _writer = null;
    public static void WriteLine(string message)
    {
        if (!Directory.Exists(@"..\log"))
        {
            Directory.CreateDirectory(@"..\log");
        }
        if (_writer == null)
        {
            _writer = new StreamWriter(_path, true);
        }
        var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff ");
        _writer.WriteLine($"{timestamp} {message}");
        _writer.Flush();
        Console.Error.WriteLine($"{timestamp} {message}");
    }
}
