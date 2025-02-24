//+------------------------------------------------------------------+
//|                                    MQL45_TechnicalIndicators.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iAC(string symbol, int timeframe, int shift)
{
    double buffer[1];
    int handle = ::iAC(symbol, IntegerToTimeframe(timeframe));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iAD(string symbol, int timeframe, int shift)
{
    double buffer[1];
    int handle = ::iAD(symbol, IntegerToTimeframe(timeframe), VOLUME_TICK);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iADX(string symbol, int timeframe, int period, int applied_price, int mode, int shift)
{
    double buffer[1];
    int handle = ::iADX(symbol, IntegerToTimeframe(timeframe), period);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iAlligator(string symbol, int timeframe, int jaw_period, int jaw_shift, int teeth_period, int teeth_shift, int lips_period, int lips_shift, int ma_method, int applied_price, int mode, int shift)
{
    double buffer[1];
    int handle = ::iAlligator(symbol, IntegerToTimeframe(timeframe), jaw_period, jaw_shift, teeth_period, teeth_shift, lips_period, lips_shift, IntegerToMAMethod(ma_method), IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iAO(string symbol, int timeframe, int shift)
{
    double buffer[1];
    int handle = ::iAO(symbol, IntegerToTimeframe(timeframe));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iATR(string symbol, int timeframe, int period, int shift)
{
    double buffer[1];
    int handle = ::iATR(symbol, IntegerToTimeframe(timeframe), period);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iBearsPower(string symbol, int timeframe, int period, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iBearsPower(symbol, IntegerToTimeframe(timeframe), period);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iBands(string symbol, int timeframe, int period, double deviation, int bands_shift, int applied_price, int mode, int shift)
{
    double buffer[1];
    int handle = ::iBands(symbol, IntegerToTimeframe(timeframe), period, bands_shift, deviation, IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iBullsPower(string symbol, int timeframe, int period, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iBullsPower(symbol, IntegerToTimeframe(timeframe), period);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iCCI(string symbol, int timeframe, int period, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iCCI(symbol, IntegerToTimeframe(timeframe), period, IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iDeMarker(string symbol, int timeframe, int period, int shift)
{
    double buffer[1];
    int handle = ::iDeMarker(symbol, IntegerToTimeframe(timeframe), period);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iEnvelopes(string symbol, int timeframe, int ma_period, int ma_method, int ma_shift, int applied_price, double deviation, int mode, int shift)
{
    if(mode == 0) {
        return(MQL45::iMA(symbol, timeframe, ma_period, ma_shift, ma_method, applied_price, shift));
    }

    double buffer[1];
    int handle = ::iEnvelopes(symbol, IntegerToTimeframe(timeframe), ma_period, ma_shift, IntegerToMAMethod(ma_method), IntegerToAppliedPrice(applied_price), deviation);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode - 1, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iForce(string symbol, int timeframe, int period, int ma_method, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iForce(symbol, IntegerToTimeframe(timeframe), period, IntegerToMAMethod(ma_method), VOLUME_TICK);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iFractals(string symbol, int timeframe, int mode, int shift)
{
    double buffer[1];
    int handle = ::iFractals(symbol, IntegerToTimeframe(timeframe));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iGator(string symbol, int timeframe, int jaw_period, int jaw_shift, int teeth_period, int teeth_shift, int lips_period, int lips_shift, int ma_method, int applied_price, int mode, int shift)
{
    double buffer[1];
    int handle = ::iGator(symbol, IntegerToTimeframe(timeframe), jaw_period, jaw_shift, teeth_period, teeth_shift, lips_period, lips_shift, IntegerToMAMethod(ma_method), IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iIchimoku(string symbol, int timeframe, int tenkan_sen, int kijun_sen, int senkou_span_b, int mode, int shift)
{
    double buffer[1];
    int handle = ::iIchimoku(symbol, IntegerToTimeframe(timeframe), tenkan_sen, kijun_sen, senkou_span_b);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode - 1, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iBWMFI(string symbol, int timeframe, int shift)
{
    double buffer[1];
    int handle = ::iBWMFI(symbol, IntegerToTimeframe(timeframe), VOLUME_TICK);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iMomentum(string symbol, int timeframe, int period, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iMomentum(symbol, IntegerToTimeframe(timeframe), period, IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iMFI(string symbol, int timeframe, int period, int shift)
{
    double buffer[1];
    int handle = ::iMFI(symbol, IntegerToTimeframe(timeframe), period, VOLUME_TICK);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iMA(string symbol, int timeframe, int ma_period, int ma_shift, int ma_method, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iMA(symbol, IntegerToTimeframe(timeframe), ma_period, ma_shift, IntegerToMAMethod(ma_method), IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iMAOnArray(const double& array[], int total, int period, int ma_shift, int ma_method, int shift)
{
    double buf[], arr[];
    if(total == 0) total = ArraySize(array);
    if(total > 0 && total <= period) {
        //DebugBreak();
        return 0;
    }
    if(shift > total - period - ma_shift) {
        //DebugBreak();
        return 0;
    }

    switch(ma_method) {
    case MODE_SMA : {
        total = ArrayCopy(arr, array, 0, shift + ma_shift, period);
        if(ArrayResize(buf, total) < 0) return(0);
        double sum = 0;
        int    i, pos = total - 1;
        for(i = 1; i < period; i++, pos--)
            sum += arr[pos];
        while(pos >= 0) {
            sum += arr[pos];
            buf[pos] = sum / period;
            sum -= arr[pos + period - 1];
            pos--;
        }
        return(buf[0]);
    }
    case MODE_EMA : {
        if(ArrayResize(buf, total) < 0) return(0);
        double pr = 2.0 / (period + 1);
        int    pos = total - 2;
        while(pos >= 0) {
            if(pos == total - 2) buf[pos + 1] = array[pos + 1];
            buf[pos] = array[pos] * pr + buf[pos + 1] * (1 - pr);
            pos--;
        }
        return(buf[shift + ma_shift]);
    }
    case MODE_SMMA : {
        if(ArrayResize(buf, total) < 0) return(0);
        double sum = 0;
        int    i, k, pos;
        pos = total - period;
        while(pos >= 0) {
            if(pos == total - period) {
                for(i = 0, k = pos; i < period; i++, k++) {
                    sum += array[k];
                    buf[k] = 0;
                }
            } else sum = buf[pos + 1] * (period - 1) + array[pos];
            buf[pos] = sum / period;
            pos--;
        }
        return(buf[shift + ma_shift]);
    }
    case MODE_LWMA : {
        if(ArrayResize(buf, total) < 0) return(0);
        double sum = 0.0, lsum = 0.0;
        double price;
        int    i, weight = 0, pos = total - 1;
        for(i = 1; i <= period; i++, pos--) {
            price = array[pos];
            sum += price * i;
            lsum += price;
            weight += i;
        }
        pos++;
        i = pos + period;
        while(pos >= 0) {
            buf[pos] = sum / weight;
            if(pos == 0) break;
            pos--;
            i--;
            price = array[pos];
            sum = sum - lsum + price * period;
            lsum -= array[i];
            lsum += price;
        }
        return(buf[shift + ma_shift]);
    }
    default:
        //DebugBreak();
        return(0);
    }

    //DebugBreak();
    return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iOsMA(string symbol, int timeframe, int fast_ma_period, int slow_ma_period, int signal_period, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iOsMA(symbol, IntegerToTimeframe(timeframe), fast_ma_period, slow_ma_period, signal_period, IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iMACD(string symbol, int timeframe, int fast_ma_period, int slow_ma_period, int signal_period, int applied_price, int mode, int shift)
{
    double buffer[1];
    int handle = ::iMACD(symbol, IntegerToTimeframe(timeframe), fast_ma_period, slow_ma_period, signal_period, IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iOBV(string symbol, int timeframe, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iOBV(symbol, IntegerToTimeframe(timeframe), VOLUME_TICK);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iSAR(string symbol, int timeframe, double step, double maximum, int shift)
{
    double buffer[1];
    int handle = ::iSAR(symbol, IntegerToTimeframe(timeframe), step, maximum);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iRSI(string symbol, int timeframe, int period, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iRSI(symbol, IntegerToTimeframe(timeframe), period, IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iRVI(string symbol, int timeframe, int period, int mode, int shift)
{
    double buffer[1];
    int handle = ::iRVI(symbol, IntegerToTimeframe(timeframe), period);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iStdDev(string symbol, int timeframe, int ma_period, int ma_shift, int ma_method, int applied_price, int shift)
{
    double buffer[1];
    int handle = ::iStdDev(symbol, IntegerToTimeframe(timeframe), ma_period, ma_shift, IntegerToMAMethod(ma_method), IntegerToAppliedPrice(applied_price));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iStdDevOnArray(const double& array[], int toral, int ma_period, int ma_shift, int ma_method, int shift)
{
    double sum_xx = 0;
    double sum_x = 0;
    int n = ma_period;
    for (int i = 0; i < n; ++i) {
        double x = array[shift + i];
        sum_xx += x * x;
        sum_x += x;
    }
    double avr_x = sum_x / n;
    double var_x = sum_xx / n - avr_x * avr_x;
    double sd_x = MathSqrt(var_x);
    return sd_x;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iStochastic(string symbol, int timeframe, int Kperiod, int Dperiod, int slowing, int method, int price_filed, int mode, int shift)
{
    double buffer[1];
    int handle = ::iStochastic(symbol, IntegerToTimeframe(timeframe), Kperiod, Dperiod, slowing, IntegerToMAMethod(method), IntegerToStoPrice(price_filed));

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, mode, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iWPR(string symbol, int timeframe, int period, int shift)
{
    double buffer[1];
    int handle = ::iWPR(symbol, IntegerToTimeframe(timeframe), period);

    if (handle == INVALID_HANDLE) {
        return(0);
    }

    if(CopyBuffer(handle, 0, shift, 1, buffer) < 0) {
        return(0);
    }
    return(buffer[0]);
}
