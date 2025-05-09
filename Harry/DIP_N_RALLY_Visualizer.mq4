//+------------------------------------------------------------------+
//|                                       DIP_N_RALLY_Visualizer.mq4 |
//|                                                     iLogix, LLC. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "iLogix, LLC."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#ifdef __MQL5__
#include "MQL45/MQL45.mqh"
#define COLOR_NONE clrNONE
#else
enum MQL45_TIMEFRAMES {
    TIMEFRAME_M1 = PERIOD_M1, // 1分間
    TIMEFRAME_M5 = PERIOD_M5, // 5分間
    TIMEFRAME_M15 = PERIOD_M15, // 15分間
    TIMEFRAME_M30 = PERIOD_M30, // 30分間
    TIMEFRAME_H1 = PERIOD_H1, // 1時間
    TIMEFRAME_H4 = PERIOD_H4, // 4時間
    TIMEFRAME_D1 = PERIOD_D1, // 1日
    TIMEFRAME_W1 = PERIOD_W1, // 1週間
    TIMEFRAME_MN1 = PERIOD_MN1, // 1か月
};
#define COLOR_NONE CLR_NONE
#endif

#property indicator_separate_window
#property indicator_buffers 42
#property indicator_plots   4

//--- plot "DIP N RALLY Visualizer"
#property indicator_label1  "DIP N RALLY Visualizer"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  5

//--- plot "Up"
#property indicator_label2  "Up"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrLime
#property indicator_style2  STYLE_SOLID
#property indicator_width2  5

//--- plot "Down"
#property indicator_label3  "Down"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  5

//--- plot "Trend Change"
#property indicator_label4  "Trend Change"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  5

#property indicator_color5  COLOR_NONE
#property indicator_color6  COLOR_NONE
#property indicator_color7  COLOR_NONE
#property indicator_color8  COLOR_NONE
#property indicator_color9  COLOR_NONE
#property indicator_color10 COLOR_NONE
#property indicator_color11 COLOR_NONE
#property indicator_color12 COLOR_NONE
#property indicator_color13 COLOR_NONE
#property indicator_color14 COLOR_NONE
#property indicator_color15 COLOR_NONE
#property indicator_color16 COLOR_NONE
#property indicator_color17 COLOR_NONE
#property indicator_color18 COLOR_NONE
#property indicator_color19 COLOR_NONE
#property indicator_color20 COLOR_NONE
#property indicator_color21 COLOR_NONE
#property indicator_color22 COLOR_NONE
#property indicator_color23 COLOR_NONE
#property indicator_color24 COLOR_NONE
#property indicator_color25 COLOR_NONE
#property indicator_color26 COLOR_NONE
#property indicator_color27 COLOR_NONE
#property indicator_color28 COLOR_NONE
#property indicator_color29 COLOR_NONE
#property indicator_color30 COLOR_NONE
#property indicator_color31 COLOR_NONE
#property indicator_color32 COLOR_NONE
#property indicator_color33 COLOR_NONE
#property indicator_color34 COLOR_NONE
#property indicator_color35 COLOR_NONE
#property indicator_color36 COLOR_NONE
#property indicator_color37 COLOR_NONE
#property indicator_color38 COLOR_NONE
#property indicator_color39 COLOR_NONE
#property indicator_color40 COLOR_NONE
#property indicator_color41 COLOR_NONE
#property indicator_color42 COLOR_NONE

//--- input parameters
sinput string  ST = "";                     // Find TREND on chart
input int      lenw = 100;                  // ├ Extent of Caution Zone
input int      len = 7;                     // ├ OnCart Trend Length
input int      mult = 1;                    // ├ Factor
input color    colup = clrLime;             // ├ Up
input color    coldn = clrRed;              // ├ Down
input int      width = 1;                   // ├ line width
input double   adjust_factor = 0.0;         // └ scale adjust factor (F1)
sinput string  adjust_factor_comment = "";  // 　 画面左下F1の数値を参考に入力(小数点可), 0なら自動

sinput string  STM = "";                    // Find TREND on MTF
input bool     ures = true;                 // ├ Show Cutsom Resolution DR Visualizer
#ifdef __MQL5__
input MQL45_TIMEFRAMES res = PERIOD_H1;     // ├ Time Frame DR Visualizer
#else
input MQL45_TIMEFRAMES res = TIMEFRAME_H1;  // ├ Time Frame DR Visualizer
#endif
input int      lenw_m = 100;                // ├ Extent of Caution Zone
input int      len_m = 7;                   // ├ MTF Trend Length
input int      mult_m = 1;                  // ├ Factor
input color    colup_m = clrLime;           // ├ Up
input color    coldn_m = clrRed;            // ├ Down
input int      mid_line_width = 3;          // ├ mid line width
input double   adjust_factor_m = 0.0;       // └ scale adjust factor (F1)
sinput string  adjust_factor_comment_m = "";// 　 画面左下F2の数値を参考に入力(小数点可), 0なら自動

sinput string  gr_wt = "";                  // Find Small Waves
input int      n1 = 5;                      // ├ Length, Channel
input int      n2 = 10;                     // ├ Average
input color    col_wt = clrBlue;            // ├ color
input int      obLevel1 = 60;               // ├ Over Bought Level 1
input int      obLevel2 = 53;               // ├ Over Bought Level 2
input int      osLevel1 = -60;              // ├ Over Sold Level 1
input int      osLevel2 = -53;              // └ Over Sold Level 2

#ifdef __MQL5__
#define NA EMPTY_VALUE
#else
#define NA 0.0
#endif

//--- indicator buffers
double          wt[];
double          lvlup[];
double          lvldn[];
double          lvl[];
double          u0[];
double          lvlu[];
double          x0[];
double          lvlx[];

double          ap[];
double          esa[];
double          d0[];
double          d[];
double          ci[];
double          tci[];
double          wt1[];
double          wt2[];
double          stc[];
double          tdc[];
double          stm[];
double          tdm[];
double          stu[];
double          tdu[];
double          clsu[];
double          stu2[];
double          tdu2[];
double          clsu2[];
double          cls[];
double          lvlu2[];
double          wt_h[];
double          lvl_h[];
double          lvlu_h[];
double          f1_0[];
double          f2_0[];
double          f1_1[];
double          f2_1[];
double          f1[];
double          f2[];
double          adjust_factor_x[];
double          adjust_factor_m_x[];
double          matr_0[];
double          matr[];
double          tdup[];
double          tddn[];

int ChartStartIndex;

#ifdef __MQL5__
MQL45_INDICATOR_START()
#endif

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
    int i = 0;
    SetIndexBuffer(i++, wt);
    SetIndexBuffer(i++, lvlup);
    SetIndexBuffer(i++, lvldn);
    SetIndexBuffer(i++, lvl);
    SetIndexBuffer(i++, u0);
    SetIndexBuffer(i++, lvlu);
    SetIndexBuffer(i++, x0);
    SetIndexBuffer(i++, lvlx);

    SetIndexBuffer(i++, ap);
    SetIndexBuffer(i++, esa);
    SetIndexBuffer(i++, d);
    SetIndexBuffer(i++, d0);
    SetIndexBuffer(i++, ci);
    SetIndexBuffer(i++, tci);
    SetIndexBuffer(i++, wt1);
    SetIndexBuffer(i++, wt2);
    SetIndexBuffer(i++, stc);
    SetIndexBuffer(i++, tdc);
    SetIndexBuffer(i++, stm);
    SetIndexBuffer(i++, tdm);
    SetIndexBuffer(i++, stu);
    SetIndexBuffer(i++, tdu);
    SetIndexBuffer(i++, clsu);
    SetIndexBuffer(i++, stu2);
    SetIndexBuffer(i++, tdu2);
    SetIndexBuffer(i++, clsu2);
    SetIndexBuffer(i++, cls);
    SetIndexBuffer(i++, lvlu2);
    SetIndexBuffer(i++, wt_h);
    SetIndexBuffer(i++, lvl_h);
    SetIndexBuffer(i++, lvlu_h);
    SetIndexBuffer(i++, f1_0);
    SetIndexBuffer(i++, f2_0);
    SetIndexBuffer(i++, f1_1);
    SetIndexBuffer(i++, f2_1);
    SetIndexBuffer(i++, f1);
    SetIndexBuffer(i++, f2);
    SetIndexBuffer(i++, adjust_factor_x);
    SetIndexBuffer(i++, adjust_factor_m_x);
    SetIndexBuffer(i++, matr_0);
    SetIndexBuffer(i++, matr);
    SetIndexBuffer(i++, tdup);
    SetIndexBuffer(i++, tddn);

    ChartStartIndex = 2 * (n1 > n2 ? n1 : n2);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
    if (rates_total < ChartStartIndex) {
        return 0;
    }

//--- starting calculation
    int pos = prev_calculated > 1 ? prev_calculated - 1 : 0;
    int endIndex = RallyVisualize(pos, rates_total, time, high, low, close);

//--- return value of prev_calculated for next call
    return endIndex;
}

int RallyVisualize(int startIndex, int endIndex,
                   const datetime& time[],
                   const double& high[],
                   const double& low[],
                   const double& close[])
{
    for (int i = startIndex; i < endIndex; ++i) {
        ap[i] = (high[i] + low[i] + close[i]) / 3.0;
        esa[i] = iMA(Symbol(), res, n1, 0, MODE_EMA, PRICE_TYPICAL, i);
        d0[i] = MathAbs(ap[i] - esa[i]);
    }

    int endIndex1 = endIndex - n1;
    for (int i = startIndex; i < endIndex1; ++i) {
        d[i] = iMAOnArray(d0, endIndex, n1, 0, MODE_EMA, i);
    }

    for (int i = startIndex; i < endIndex1; ++i) {
        ci[i] = (ap[i] - esa[i]) / (0.015 * d[i]);
    }

    int endIndex2 = endIndex1 - n2;
    for (int i = startIndex; i < endIndex2; ++i) {
        tci[i] = iMAOnArray(ci, endIndex, n2, 0, MODE_EMA, i);
    }

    ArrayCopy(wt1, tci);

    const int n3 = 4;
    int endIndex3 = endIndex2 - n3;
    for (int i = startIndex; i < endIndex3; ++i) {
        wt2[i] = iMAOnArray(wt1, endIndex, n3, 0, MODE_SMA, i);
    }
    for (int i = startIndex; i < endIndex3; ++i) {
        wt[i] = wt1[i] - wt2[i];
    }

    for (int i = startIndex; i < endIndex3; ++i) {
        stc[i] = iSuperTrend(high, low, close, mult, len, i, tdc[i]);
    }
    for (int i = startIndex; i < endIndex3; ++i) {
        stm[i] = iSuperTrend(high, low, close, mult_m, len_m, i, tdm[i]);
    }

    for (int i = startIndex; i < endIndex3; ++i) {
        cls[i] = close[i];
#ifdef __MQL5__
        stu[i] = iClose(Symbol(), res, (endIndex3 - startIndex) * PeriodSeconds(res) / PeriodSeconds(PERIOD_M1));
#else
        stu[i] = iClose(Symbol(), res, (endIndex3 - startIndex) * res);
#endif
    }
    for (int i = startIndex; i < endIndex3; ++i) {
        lvl[i] = cls[i] - stu[i];
    }
    for (int i = startIndex; i < endIndex3; ++i) {
        lvlu2[i] = clsu2[i] - stu2[i];
    }

    if (!ures) {
        ArrayFill(lvlu, 0, ArraySize(lvlu), 0.0);
    }
    if (!ures) {
        ArrayFill(lvlu2, 0, ArraySize(lvlu2), 0.0);
    }
 
    const int ARRAY_SCAN_RANGE = 500;
    int endIndex4 = endIndex3 - ARRAY_SCAN_RANGE;
    for (int i = startIndex; i < endIndex4; ++i) {
        wt_h[i + ARRAY_SCAN_RANGE] = ArrayMaximum(wt, endIndex4, ARRAY_SCAN_RANGE);
        lvl_h[i + ARRAY_SCAN_RANGE] = ArrayMaximum(lvl, endIndex4, ARRAY_SCAN_RANGE);
        lvlu_h[i + ARRAY_SCAN_RANGE] = ArrayMaximum(lvlu, endIndex4, ARRAY_SCAN_RANGE);

        f1_0[i + ARRAY_SCAN_RANGE] = MathAbs(wt_h[i] / lvl_h[i]);
        f2_0[i + ARRAY_SCAN_RANGE] = MathAbs(wt_h[i] / lvlu_h[i]);
    }
    
    for (int i = startIndex; i < endIndex4; ++i) {
        f1_1[i + ARRAY_SCAN_RANGE] = ArrayMaximum(f1_0, endIndex4, ARRAY_SCAN_RANGE) * 1.5;
        f2_1[i + ARRAY_SCAN_RANGE] = ArrayMaximum(f2_0, endIndex4, ARRAY_SCAN_RANGE) * 1.75;
    }

    for (int i = startIndex; i < endIndex4; ++i) {
        f1[i] = MathFloor(MathRound(f1_1[i] / 50)) * 50 / 100;
        f2[i] = MathFloor(MathRound(f2_1[i] / 50)) * 50 / 100;
    }

    if (endIndex < 10000 && lvlu2[endIndex - 1] != 0.0) {
        if (adjust_factor == 0.0) {
            for (int i = startIndex; i < endIndex4; ++i) {
                adjust_factor_x[i] = f1[i];
            }
        }
        if (adjust_factor_m == 0.0) {
            for (int i = startIndex; i < endIndex4; ++i) {
                adjust_factor_m_x[i] = f2[i];
            }
        }
    }

    for (int i = startIndex; i < endIndex4; ++i) {
        lvl[i]   = lvl[i]   * adjust_factor_x[i]   * 100;
        lvlu[i]  = lvlu[i]  * adjust_factor_m_x[i] * 100;
        lvlu2[i] = lvlu2[i] * adjust_factor_m_x[i] * 100;
    }

    for (int i = startIndex; i < endIndex4; ++i) {
        matr_0[i] = MathAbs(lvl[i]);
    }

    for (int i = startIndex; i < endIndex4; ++i) {
        matr[i] = iMAOnArray(matr_0, endIndex, lenw, 0, MODE_SMA, i);
        lvlup[i] = tdc[i] == -1 ? lvl[i] : NA;
        lvldn[i] = tdc[i] == +1 ? lvl[i] : NA;
        tdup[i] = (tdc[i - 1] == -1) && (tdc[i] == +1) ? 1 : 0;
        tddn[i] = (tdc[i - 1] == +1) && (tdc[i] == -1) ? 1 : 0;
    }

    return endIndex3;
}

//+------------------------------------------------------------------+
//| Pine Script Supertreand                                          |
//+------------------------------------------------------------------+
double iSuperTrend(const double& high[],
                   const double& low[],
                   const double& close[],
                   double factor,
                   int period,
                   int shift,
                   double& direction)
{
    double src[2] = {};
    double atr[2] = {};
    double upperBand[2] = {};
    double lowerBand[2] = {};
    for (int i = 0; i < 2; ++i) {
        src[i] = (high[i] + low[i] + close[i]) / 3.0;
        atr[i] = iATR(Symbol(), Period(), period, shift + i);
        upperBand[i] = src[i] + factor * atr[i];
        lowerBand[i] = src[i] - factor * atr[i];
    }
    double prevLowerBand = lowerBand[1];
    double prevUpperBand = upperBand[1];
    double LowerBand = ((lowerBand[0] > prevLowerBand) || (close[1] < prevLowerBand)) ? lowerBand[0] : prevLowerBand;
    double UpperBand = ((upperBand[0] < prevUpperBand) || (close[1] > prevUpperBand)) ? upperBand[0] : prevUpperBand;

    direction = 0;
    static double superTrend[2] = {};
    double prevSuperTrend = superTrend[1];
    if (atr[0] == 0) {
        direction = 1;
    }
    else if (prevSuperTrend == prevUpperBand) {
        direction = close[0] > upperBand[0] ? -1 : +1;
    }
    else {
        direction = close[0] < lowerBand[0] ? +1 : -1;
    }
    superTrend[1] = superTrend[0] = direction == -1 ? lowerBand[0] : upperBand[0];
    return superTrend[0];
}

#ifdef __MQL5__
MQL45_INDICATOR_END()
#endif
