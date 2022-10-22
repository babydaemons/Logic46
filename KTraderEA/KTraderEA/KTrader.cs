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

    public static int CopyCorrelation(int N, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] double[] x0, int N0, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 4)] double[] r1, int N1)
    {
        int n = 0;
        for (int i = 0; i < N1; i++)
        {
            r1[i] = Correlation(N, x0, N0, i);
            if (r1[i] >= -1.0)
            {
                n++;
                continue;
            }
            return (int)r1[i];
        }
        return n;
    }

    private static double Correlation(int N, double[] x0, int N0, int k)
    {
        double sum_y = 0.0;
        double sum_x = 0.0;
        for (int i = k; i < N + k; i++)
        {
            if (i >= N0)
            {
                return -2.0;
            }
            double x = i;
            double y = x0[i];
            if (y == 0.0)
            {
                return -3.0;
            }
            sum_y += y;
            sum_x += x;
        }

        double mean_y = sum_y / (double)N;
        double mean_x = sum_x / (double)N;
        double sum_xy = 0.0;
        double sum_xx = 0.0;
        double sum_yy = 0.0;
        for (int i = k; i < N + k; i++)
        {
            double dx = (double)i - mean_x;
            double dy = x0[i] - mean_y;
            sum_xy += dx * dy;
            sum_xx += dx * dx;
            sum_yy += dy * dy;
        }
        if (sum_xx * sum_yy != 0.0)
        {
            return sum_xy / Math.Sqrt(sum_xx * sum_yy);
        }
        return 0.0;
    }

    public static int CopyComplexCorrelation(int N, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] double[] x0, int N0, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 4)] double[] x1, int N1, [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 6)] double[] r2, int N2)
    {
        int n = 0;
        for (int i = 0; i < N1; i++)
        {
            r2[i] = ComplexCorrelation(N, x0, N0, x1, N1, i);
            if (r2[i] >= -1.0)
            {
                n++;
                continue;
            }
            return (int)r2[i];
        }
        return n;
    }

    private static double ComplexCorrelation(int N, double[] x0, int N0, double[] y0, int N1, int k)
    {
        double sum_y = 0.0;
        double sum_x = 0.0;
        for (int i = k; i < N + k; i++)
        {
            if (i >= N0)
            {
                return -2.0;
            }
            if (i >= N1)
            {
                return -2.0;
            }
            double x = x0[i];
            double y = y0[i];
            if (y == 0.0)
            {
                return -3.0;
            }
            sum_y += y;
            sum_x += x;
        }

        double mean_y = sum_y / (double)N;
        double mean_x = sum_x / (double)N;
        double sum_xy = 0.0;
        double sum_xx = 0.0;
        double sum_yy = 0.0;
        for (int i = k; i < N + k; i++)
        {
            double dx = x0[i] - mean_x;
            double dy = y0[i] - mean_y;
            sum_xy += dx * dy;
            sum_xx += dx * dx;
            sum_yy += dy * dy;
        }
        if (sum_xx * sum_yy != 0.0)
        {
            return sum_xy / Math.Sqrt(sum_xx * sum_yy);
        }

        return 0.0;
    }
}
