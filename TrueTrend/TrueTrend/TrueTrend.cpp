#include <math.h>

extern "C" {
    __declspec(dllexport) double _stdcall ArrayTrueTrend(const double value[], int periodseconds, double power, double spread, int N);
    __declspec(dllexport) double _stdcall ArrayTrend(const double value[], int periodseconds, double spread, int N);
    __declspec(dllexport) double _stdcall ArrayCorrelation(const double value[], int periodseconds, double spread, int N);
    __declspec(dllexport) double _stdcall iSMA(const double value[], int N);
}

__declspec(dllexport) double _stdcall ArrayTrueTrend(const double value[], int periodseconds, double power, double spread, int N)
{
    double trend = ArrayTrend(value, periodseconds, spread, N);
    double r = ArrayCorrelation(value, periodseconds, spread, N);
    return fabs(pow(r, power)) * trend;
}

__declspec(dllexport) double _stdcall ArrayTrend(const double value[], int periodseconds, double spread, int N)
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    double days = periodseconds / (24.0 * 3600.0);
    for (int i = 0; i < N; ++i) {
        double x = i * days;
        double y = value[i];
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double trend = diff_xy / diff_xx;
    return trend / spread;
}

__declspec(dllexport) double _stdcall ArrayCorrelation(const double value[], int periodseconds, double spread, int N)
{
    double sum_y = 0;
    double sum_x = 0;
    double days = periodseconds / (24.0 * 3600.0);
    for (int i = 0; i < N; ++i) {
        double x = i * days;
        double y = value[i];
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double dx = (i * days) - avr_x;
        double dy = value[i] - avr_y;
        sum_xy += dx * dy;
        sum_xx += dx * dx;
        sum_yy += dy * dy;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / sqrt(sum_xx * sum_yy);
    return r;
}

__declspec(dllexport) double _stdcall iSMA(const double value[], int N)
{
    double sum_y = 0;
    for (int i = 0; i < N; ++i) {
        double y = value[i];
        sum_y += y;
    }
    double avr_y = sum_y / N;
    return avr_y;
}
