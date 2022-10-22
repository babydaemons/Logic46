using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public static class KTrader
{
    public static string Execute(string module, string args, bool hideConsole)
    {
        Process process = Process.Start(new ProcessStartInfo(module, args)
        {
            CreateNoWindow = hideConsole,
            UseShellExecute = false,
            RedirectStandardOutput = false,
            RedirectStandardError = false
        });
        process.WaitForExit();
        process.Close();
        return "OK";
    }

    public static int CopyCorrelation(int N, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] double[] x0, int N0, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 4)] double[] x1, int N1)
    {
        int num = 0;
        for (int k = 0; k < N1; ++k)
        {
            x1[k] = KTrader.iCorrelation(N, x0, N0, k);
            if (x1[k] == 0.0)
                return (int)x1[k];
            ++num;
        }
        return num;
    }

    private static double iCorrelation(int N, double[] x0, int N0, int k)
    {
        double num1 = 0.0;
        double num2 = 0.0;
        for (int index = k; index < N + k; ++index)
        {
            if (index >= N0)
                return -1.0;
            double num3 = (double)index;
            double num4 = x0[index];
            if (num4 == 0.0)
                return -2.0;
            num1 += num4;
            num2 += num3;
        }
        double num5 = num1 / (double)N;
        double num6 = num2 / (double)N;
        double num7 = 0.0;
        double num8 = 0.0;
        double num9 = 0.0;
        for (int index = k; index < N + k; ++index)
        {
            double num10 = (double)index - num6;
            double num11 = x0[index] - num5;
            num7 += num10 * num11;
            num8 += num10 * num10;
            num9 += num11 * num11;
        }
        return num8 * num9 != 0.0 ? num7 / Math.Sqrt(num8 * num9) : 0.0;
    }
}
