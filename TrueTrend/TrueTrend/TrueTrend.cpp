#include <math.h>
#include <time.h>

typedef unsigned int uint;
typedef unsigned long long ulong;

struct MqlTick
{
    time_t time; // 最新の価格更新の時間 
    double bid; // 現在のBid価格 
    double ask; // 現在のAsk価格 
    double last; // 最後の取引の現在価格(Last) 
    ulong volume; // 現在のLast価格の数量 
    time_t time_msc; // ミリ秒単位の最新の価格更新の時間 
    uint flags; // ティックフラグ 
    double volume_real; // 現在のLast価格のより正確な数量 
};

extern "C" {
    __declspec(dllexport) double _stdcall iArrayTickTrend(const MqlTick value[], int N);
    __declspec(dllexport) double _stdcall iArrayTickCorrelation(const MqlTick value[], int N);
    __declspec(dllexport) double _stdcall iArrayTrueTrend(const double value[], int periodseconds, double power, double spread, int N);
    __declspec(dllexport) double _stdcall iArrayTrend(const double value[], int periodseconds, double spread, int N);
    __declspec(dllexport) double _stdcall iArrayCorrelation(const double value[], int periodseconds, double spread, int N);
    __declspec(dllexport) double _stdcall iArraySMA(const double value[], int N);
}

__declspec(dllexport) double _stdcall iArrayTickTrueTrend(const MqlTick value[], double power, int N)
{
    double trend = iArrayTickTrend(value, N);
    double r = iArrayTickCorrelation(value, N);
    return fabs(pow(r, power)) * trend;
}

__declspec(dllexport) double _stdcall iArrayTickTrend(const MqlTick value[], int N)
{
    double periodseconds = 0.001;
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    double minutes = 60.0 * periodseconds;
    for (int i = 0; i < N; ++i) {
        double x = i * minutes;
        double y = value[i].last;
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double trend = diff_xy / diff_xx;
    double spread = value[N - 1].ask - value[N - 1].bid;
    return trend / spread;
}

__declspec(dllexport) double _stdcall iArrayTickCorrelation(const MqlTick value[], int N)
{
    double periodseconds = 0.001;
    double sum_y = 0;
    double sum_x = 0;
    double minutes = 60.0 * periodseconds;
    for (int i = 0; i < N; ++i) {
        double x = i * minutes;
        double y = value[i].last;
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double dx = (i * minutes) - avr_x;
        double dy = value[i].last - avr_y;
        sum_xy += dx * dy;
        sum_xx += dx * dx;
        sum_yy += dy * dy;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / sqrt(sum_xx * sum_yy);
    return r;
}

__declspec(dllexport) double _stdcall iArrayTrueTrend(const double value[], int periodseconds, double power, double spread, int N)
{
    double trend = iArrayTrend(value, periodseconds, spread, N);
    double r = iArrayCorrelation(value, periodseconds, spread, N);
    return fabs(pow(r, power)) * trend;
}

__declspec(dllexport) double _stdcall iArrayTrend(const double value[], int periodseconds, double spread, int N)
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

__declspec(dllexport) double _stdcall iArrayCorrelation(const double value[], int periodseconds, double spread, int N)
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

__declspec(dllexport) double _stdcall iArraySMA(const double value[], int N)
{
    double sum_y = 0;
    for (int i = 0; i < N; ++i) {
        double y = value[i];
        sum_y += y;
    }
    double avr_y = sum_y / N;
    return avr_y;
}
