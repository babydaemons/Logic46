//+------------------------------------------------------------------+
//|                                                        MQL45.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#ifdef __MQL5__
#include "MQL45_Trade.mqh"
#include "MQL45_Defines.mqh"
#endif /*__MQL5__*/

#ifndef __MQL45_INCLUDED
#define __MQL45_INCLUDED

//#define __DEBUG_TIMEFRAMES

#ifdef __MQL5__

#define MQL45_TIMEFRAMES ENUM_TIMEFRAMES

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MQL45
{
public:
    static double Ask;
    static double Bid;
    static double Close[];
    static double High[];
    static double Low[];
    static double Open[];
    static datetime Time[];
    static long Volume[];
    static int Bars;
    static int Digits;

    static void RefreshRates();
    static ENUM_TIMEFRAMES IntegerToTimeframe(int value);
    static ENUM_APPLIED_PRICE IntegerToAppliedPrice(int value);
    static ENUM_MA_METHOD IntegerToMAMethod(int value);
    static ENUM_STO_PRICE IntegerToStoPrice(int value);
    static ENUM_ORDER_TYPE IntegerToOrderType(int value);
    static int OrderTypeToInteger(ENUM_ORDER_TYPE type);
    static int PositionTypeToInteger(ENUM_POSITION_TYPE type);
    static ENUM_OBJECT IntegerToObject(int value);

public:
    static double AccountBalance();
    static double AccountCredit();
    static string AccountCompany();
    static string AccountCurrency();
    static double AccountEquity();
    static double AccountFreeMargin();
    static int AccountLeverage();
    static double AccountMargin();
    static double AccountFreeMarginCheck(string symbol, int cmd, double volume);
    static string AccountName();
    static int AccountNumber();
    static double AccountProfit();
    static string AccountServer();
    static int AccountStopoutLevel();
    static int AccountStopoutMode();

public:
    template<typename T>
    static bool ArraySort(T &array[], int count = WHOLE_ARRAY, int start = 0, int direction = MODE_ASCEND)
    {
        bool flag = (direction == MODE_DESCEND) ? false : true;

        ArraySetAsSeries(array, flag);
        return(ArraySort(array));
    }

    static int ArrayCopyRates(MqlRates &rates_array[], string symbol = NULL, int timeframe = 0);

    template<typename T>
    static int ArrayCopyRates(T &dest_array[], string symbol = NULL, int timeframe = 0)
    {
        int count = Bars(symbol, IntegerToTimeframe(timeframe));

        double open[], low[], high[], close[];
        long tick_volume[];
        datetime time[];

        CopyOpen(symbol, IntegerToTimeframe(timeframe), 0, count, open);
        CopyLow(symbol, IntegerToTimeframe(timeframe), 0, count, low);
        CopyHigh(symbol, IntegerToTimeframe(timeframe), 0, count, high);
        CopyClose(symbol, IntegerToTimeframe(timeframe), 0, count, close);
        CopyTickVolume(symbol, IntegerToTimeframe(timeframe), 0, count, tick_volume);
        CopyTime(symbol, IntegerToTimeframe(timeframe), 0, count, time);

        for(int i = 0; i < count; i++) {
            dest_array[i][0] = time[i];
            dest_array[i][1] = open[i];
            dest_array[i][2] = low[i];
            dest_array[i][3] = high[i];
            dest_array[i][4] = close[i];
            dest_array[i][5] = tick_volume[i];
        }

        return(count);
    }

    template<typename T>
    static int ArrayCopySeries(T &array[], int series_index, string symbol = NULL, int timeframe = 0)
    {
        int count = Bars(symbol, IntegerToTimeframe(timeframe));

        switch(series_index) {
        case 0: // MODE_OPEN
            return(CopyOpen(symbol, IntegerToTimeframe(timeframe), 0, count, array));
        case 1: // MODE_LOW
            return(CopyLow(symbol, IntegerToTimeframe(timeframe), 0, count, array));
        case 2: // MODE_HIGH
            return(CopyHigh(symbol, IntegerToTimeframe(timeframe), 0, count, array));
        case 3: // MODE_CLOSE
            return(CopyClose(symbol, IntegerToTimeframe(timeframe), 0, count, array));
        case 5: // MODE_TIME
            return(CopyTime(symbol, IntegerToTimeframe(timeframe), 0, count, array));
        }

        return(-1);
    }

public:
    static bool IsConnected();
    static bool IsDemo();
    static bool IsDllsAllowed();
    static bool IsExpertEnabled();
    static bool IsLibrariesAllowed();
    static bool IsOptimization();
    static bool IsTesting();
    static bool IsTradeAllowed();
    static bool IsTradeContextBusy();
    static bool IsVisualMode();
    static string TerminalCompany();
    static string TerminalName();
    static string TerminalPath();

public:
    static string CharToStr(uchar char_code);
    static string DoubleToStr(double value, int digits);
    static double StrToDouble(string value);
    static int StrToInteger(string value);
    static datetime StrToDatetime(string value);
    static datetime StrToTime(string value);
    static string TimeToStr(datetime value, int mode = TIME_DATE | TIME_MINUTES);

public:
    static void IndicatorDigits(int digits);
    static void IndicatorShortName(string name);
    static void SetIndexArrow(int index, int code);
    static void SetIndexDrawBegin(int index, int begin);
    static void SetIndexEmptyValue(int index, double value);
    static void SetIndexLabel(int index, string text);
    static void SetIndexShift(int index, int shift);
    static void SetIndexStyle(int index, int type, int style = EMPTY, int width = EMPTY, color clr = clrNONE);
    static void SetLevelStyle(int draw_style, int line_width, color clr);
    static void SetLevelValue(int level, double value);

public:
    static int WindowBarsPerChart();
    static string WindowExpertName();
    static int WindowFind(string name);
    static int WindowFirstVisibleBar();
    static int WindowHandle(string symbol, int timeframe);
    static bool WindowIsVisible(int index);
    static int WindowOnDropped();
    static double WindowPriceMax(int index = 0);
    static double WindowPriceMin(int index = 0);
    static double WindowPriceOnDropped();
    static void WindowRedraw();
    static bool WindowScreenShot(string filename, int size_x, int size_y, int start_bar = -1, int chart_scale = -1, int chart_mode = -1);
    static datetime WindowTimeOnDropped();
    static int WindowsTotal();
    static int WindowXOnDropped();
    static int WindowYOnDropped();
    static void HideTestIndicators(bool hide);

public:
    static int Day();
    static int DayOfWeek();
    static int DayOfYear();
    static int Hour();
    static int Minute();
    static int Month();
    static int Seconds();
    static int TimeDay(datetime date);
    static int TimeDayOfWeek(datetime date);
    static int TimeDayOfYear(datetime date);
    static int TimeHour(datetime date);
    static int TimeMinute(datetime date);
    static int TimeMonth(datetime date);
    static int TimeSeconds(datetime date);
    static int TimeYear(datetime date);
    static int Year();

public:
    static double MarketInfo(string symbol, int type);

public:
    static bool ObjectCreate(string object_name, ENUM_OBJECT object_type, int sub_window, datetime time1, double price1, datetime time2 = 0, double price2 = 0, datetime time3 = 0, double price3 = 0);
    static bool ObjectCreate(string object_name, int object_type, int sub_window, datetime time1, double price1, datetime time2 = 0, double price2 = 0, datetime time3 = 0, double price3 = 0);
    static string ObjectName(int object_index);
    static bool ObjectDelete(string object_name);
    static int ObjectsDeleteAll(int sub_window = EMPTY, int object_type = EMPTY);
    static int ObjectFind(string object_name);
    static bool ObjectMove(string object_name, int point_index, datetime time, double price);
    static int ObjectsTotal(int type = EMPTY);
    static string ObjectDescription(string object_name);
    static double ObjectGet(string object_name, int index);
    static string ObjectGetFiboDescription(string object_name, int index);
    static int ObjectGetShiftByValue(string object_name, int value);
    static double ObjectGetValueByShift(string object_name, int shift);
    static bool ObjectSet(string object_name, int index, double value);
    static bool ObjectSet(string object_name, ENUM_OBJECT_PROPERTY_INTEGER object_property, long value);
    static bool ObjectSet(string object_name, ENUM_OBJECT_PROPERTY_DOUBLE object_property, double value);
    static bool ObjectSet(string object_name, ENUM_OBJECT_PROPERTY_STRING object_property, string value);
    static bool ObjectSetFiboDescription(string object_name, int index, string text);
    static bool ObjectSetText(string object_name, string text, int font_size = 0, string font_name = NULL, color text_color = clrNONE);
    static int ObjectType(string object_name);

public:
    static int iBars(string symbol, int timeframe);
    static int iBarShift(string symbol, int timeframe, datetime time, bool exact = true);
    static double iClose(string symbol, int timeframe, int shift);
    static double iHigh(string symbol, int timeframe, int shift);
    static int iHighest(string symbol, int timeframe, int type, int count, int start);
    static double iLow(string symbol, int timeframe, int shift);
    static int iLowest(string symbol, int timeframe, int type, int count, int start);
    static double iOpen(string symbol, int timeframe, int shift);
    static datetime iTime(string symbol, int timeframe, int shift);
    static long iVolume(string symbol, int timeframe, int shift);

public:
    static CTrade _MQL45_trader;
    static ulong last_selected_position_ticket;
    static ulong last_selected_order_ticket;
    static ulong last_selected_history_ticket;
    static int positions_total;
    static int orders_total;
    static string order_close_comment;

    static void OrderCloseComment(string comment);
    static bool OrderClose(int ticket, double lots, double price, int slippage, color arrow_color);
    static bool OrderCloseBy(int ticket, int opposite, color arrow_color);
    static ENUM_ORDER_TYPE_FILLING SelectFillPolicy(string symbol);
    static bool OrderDelete(int ticket, color arrow_color);
    static bool OrderModify(int ticket, double price, double sl, double tp, int expiration, color arrow_color = clrRed);
    static int OrderSend(string symbol, int cmd, double volume, double price, int slippage, double sl, double tp, string comment = NULL, int magic = 0, datetime expiration = 0, color arrow = clrNONE);
    static int OrdersHistoryTotal();
    static int OrdersTotal();
    static bool OrderSelect(int index, int select, int mode = MODE_TRADES);
    static double OrderClosePrice();
    static datetime OrderCloseTime();
    static string OrderComment();
    static double OrderCommission();
    static double OrderExpiration();
    static double OrderLots();
    static int OrderMagicNumber();
    static double OrderOpenPrice();
    static datetime OrderOpenTime();
    static double OrderProfit();
    static double OrderStopLoss();
    static double OrderSwap();
    static string OrderSymbol();
    static double OrderTakeProfit();
    static int OrderTicket();
    static int OrderType();

public:
    static double iAC(string symbol, int timeframe, int shift);
    static double iAD(string symbol, int timeframe, int shift);
    static double iADX(string symbol, int timeframe, int period, int applied_price, int mode, int shift);
    static double iAlligator(string symbol, int timeframe, int jaw_period, int jaw_shift, int teeth_period, int teeth_shift, int lips_period, int lips_shift, int ma_method, int applied_price, int mode, int shift);
    static double iAO(string symbol, int timeframe, int shift);
    static double iATR(string symbol, int timeframe, int period, int shift);
    static double iBearsPower(string symbol, int timeframe, int period, int applied_price, int shift);
    static double iBands(string symbol, int timeframe, int period, double deviation, int bands_shift, int applied_price, int mode, int shift);
    static double iBullsPower(string symbol, int timeframe, int period, int applied_price, int shift);
    static double iCCI(string symbol, int timeframe, int period, int applied_price, int shift);
    static double iDeMarker(string symbol, int timeframe, int period, int shift);
    static double iEnvelopes(string symbol, int timeframe, int ma_period, int ma_method, int ma_shift, int applied_price, double deviation, int mode, int shift);
    static double iForce(string symbol, int timeframe, int period, int ma_method, int applied_price, int shift);
    static double iFractals(string symbol, int timeframe, int mode, int shift);
    static double iGator(string symbol, int timeframe, int jaw_period, int jaw_shift, int teeth_period, int teeth_shift, int lips_period, int lips_shift, int ma_method, int applied_price, int mode, int shift);
    static double iIchimoku(string symbol, int timeframe, int tenkan_sen, int kijun_sen, int senkou_span_b, int mode, int shift);
    static double iBWMFI(string symbol, int timeframe, int shift);
    static double iMomentum(string symbol, int timeframe, int period, int applied_price, int shift);
    static double iMFI(string symbol, int timeframe, int period, int shift);
    static double iMA(string symbol, int timeframe, int ma_period, int ma_shift, int ma_method, int applied_price, int shift);
    static double iMAOnArray(const double &array[], int total, int period, int ma_shift, int ma_method, int shift);
    static double iOsMA(string symbol, int timeframe, int fast_ma_period, int slow_ma_period, int signal_period, int applied_price, int shift);
    static double iMACD(string symbol, int timeframe, int fast_ma_period, int slow_ma_period, int signal_period, int applied_price, int mode, int shift);
    static double iOBV(string symbol, int timeframe, int applied_price, int shift);
    static double iSAR(string symbol, int timeframe, double step, double maximum, int shift);
    static double iRSI(string symbol, int timeframe, int period, int applied_price, int shift);
    static double iRVI(string symbol, int timeframe, int period, int mode, int shift);
    static double iStdDev(string symbol, int timeframe, int ma_period, int ma_shift, int ma_method, int applied_price, int shift);
    static double iStdDevOnArray(const double& array[], int toral, int ma_period, int ma_shift, int ma_method, int shift);
    static double iStochastic(string symbol, int timeframe, int Kperiod, int Dperiod, int slowing, int method, int price_filed, int mode, int shift);
    static double iWPR(string symbol, int timeframe, int period, int shift);

public:
    static int BarsPerWindow();
    static string ClientTerminalName();
    static datetime CurTime();
    static datetime CurTime(MqlDateTime& dt_struct);
    static string CompanyName();
    static int FirstVisibleBar();
    static double Highest(string symbol, int timeframe, int type, int count, int start);
    static int HistoryTotal();
    static datetime LocalTime();
    static datetime LocalTime(MqlDateTime& dt_struct);
    static double Lowest(string symbol, int timeframe, int type, int count, int start);
    static void ObjectsRedraw();
    static double PriceOnDropped();
    static bool ScreenShot(string filename, int size_x, int size_y, int start_bar = -1, int chart_scale = -1, int chart_mode = -1);
    static string ServerAddress();
    static datetime TimeOnDropped();

public:
    static string StringTrimLeft(const string text);
    static string StringTrimRight(const string text);
    static ushort StringGetChar(string string_value, int pos);
    static string StringSetChar(string string_var, int pos, ushort value);

public:
    static double SharpeRatioMonthly(double Balance);
};

#include "MQL45_Converter.mqh"
#include "MQL45_AccountInformation.mqh"
#include "MQL45_ArrayFunctions.mqh"
#include "MQL45_ChartOperations.mqh"
#include "MQL45_ConversionFunctions.mqh"
#include "MQL45_CustomIndicators.mqh"
#include "MQL45_DateAndTime.mqh"
#include "MQL45_MarketInfo.mqh"
#include "MQL45_ObjectFunctions.mqh"
#include "MQL45_ObsoleteFunctions.mqh"
#include "MQL45_StringFunctions.mqh"
#include "MQL45_TechnicalIndicators.mqh"
#include "MQL45_TimeseriesAndIndicatorsAccess.mqh"
#include "MQL45_TradeFunctions.mqh"
#include "MQL45_Checkup.mqh"

#define MQL45_DERIVERED : public MQL45

#else  /*__MQL4__*/

#define MQL45_TIMEFRAMES int

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MQL45
{
public:
    MQL45() { }

    static void RefreshRates() { }

    static void OrderCloseComment(string comment) { }

    static bool OrderCalcMargin(ENUM_ORDER_TYPE action, string symbol, double volume, double price, double& margin)
    {
        margin = volume * MarketInfo(symbol, MODE_MARGININIT);
        return true;
    }

    static double SharpeRatioMonthly(double Balance);
};

#define MQL45_DERIVERED /*nothing*/

#endif  /*__MQL4__*/

//+------------------------------------------------------------------+
//| https://qiita.com/LitopsQ/items/494be412b3f96d26784b             |
//+------------------------------------------------------------------+
double MQL45::SharpeRatioMonthly(double Balance)
{
    int CalcMonth = 0;
    int TradeMonths = 0;
    double MonthlyProfit[];
    int i;

    for(i = 0; i < OrdersHistoryTotal(); i++) {
        if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) break;

        int CloseMonth = TimeMonth(OrderCloseTime());
        if(CalcMonth != CloseMonth) {
            CalcMonth = CloseMonth;
            TradeMonths++;
            ArrayResize(MonthlyProfit, TradeMonths);
        }
        MonthlyProfit[TradeMonths - 1] += OrderProfit();
    }

    double MonthlyEarningRate[];
    ArrayResize(MonthlyEarningRate, ArraySize(MonthlyProfit));
    double SumMER = 0;

    for(i = 0; i < ArraySize(MonthlyProfit); i++) {
        MonthlyEarningRate[i] = MonthlyProfit[i] / Balance;
        SumMER += MonthlyEarningRate[i];
        Balance += MonthlyProfit[i];
    }

    double MER_Average = SumMER / TradeMonths;
    double MER_SD = iStdDevOnArray(MonthlyEarningRate, 0, TradeMonths, 0, 0, 0);
    double SR = 1;
    if(MER_SD != 0) SR = MER_Average / MER_SD; // ゼロ割を回避

    return SR;
}

#define MQL45_APPLICATION_START() \
    class MQL45App : public MQL45 { \
    public: \
        MQL45App() { }

#define MQL45_APPLICATION_END() \
    }; \
    MQL45App cMQL45AppInstance; \
    int OnInit() { \
        return cMQL45AppInstance.OnInit(); \
    } \
    void OnTick() { \
        MQL45::RefreshRates(); \
        cMQL45AppInstance.OnTick(); \
    } \
    void OnTimer() { \
        cMQL45AppInstance.OnTimer(); \
    } \
    double OnTester() { \
        return cMQL45AppInstance.OnTester(); \
    }

#define MQL45_INDICATOR_START() \
    class MQL45App : public MQL45 { \
    public: \
        MQL45App() { }

#define MQL45_INDICATOR_END() \
    }; \
    MQL45App cMQL45AppInstance; \
    int OnInit() { \
        return cMQL45AppInstance.OnInit(); \
    } \
    void OnTick() { \
        MQL45::RefreshRates(); \
        cMQL45AppInstance.OnTick(); \
    } \
    void OnTimer() { \
        cMQL45AppInstance.OnTimer(); \
    } \
    int OnCalculate(const int rates_total, \
                    const int prev_calculated, \
                    const datetime &time[], \
                    const double &open[], \
                    const double &high[], \
                    const double &low[], \
                    const double &close[], \
                    const long &tick_volume[], \
                    const long &volume[], \
                    const int &spread[]) \
    { \
        return cMQL45AppInstance.OnCalculate(rates_total, prev_calculated, time, open, high,low, close, tick_volume, volume, spread); \
    }

#endif /*__MQL45_INCLUDED*/
