using System.Diagnostics;

public static class MTFFitting
{
    public static string Execute(string module, string args)
    {
        // 第1引数がコマンド、第2引数がコマンドの引数
        var processStartInfo = new ProcessStartInfo(module, args)
        {
            // ウィンドウを表示しない
            CreateNoWindow = true,
            UseShellExecute = false,

            // 標準出力、標準エラー出力を取得できるようにする
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };

        // コマンド実行
        var process = Process.Start(processStartInfo);
        process.WaitForExit();

        var result =  process.StandardError.ReadToEnd();
        process.Close();

        return result;
    }
}
