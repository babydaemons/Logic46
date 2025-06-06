//+------------------------------------------------------------------+
//|                                                    KuChartEA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"

#include "ActiveLabel.mqh"

enum ENUM_TF {
    TF_M01 = PERIOD_M1,
    TF_M05 = PERIOD_M5,
    TF_M15 = PERIOD_M15,
    TF_M30 = PERIOD_M30,
    TF_H01 = PERIOD_H1,
    TF_H04 = PERIOD_H4,
    TF_D01 = PERIOD_D1,
    TF_W01 = PERIOD_W1,
    TF_MN1 = PERIOD_MN1,
};

input ENUM_TF TF = TF_H01;
input double START_DAYS = 25;
input double BB_DAYS = 5;
input double TREND_DAYS = 1;
input double BB_STOPLOSS_RATIO = 1.0;
input double BB_TRAILING_START_RATIO = 0.3;
input double BB_TRAILING_STEP_RATIO = 0.5;
input double LOTS = 0.01;
input double ACCOUNT_TRAILING_RATIO = 0.025;
input double ACCOUNT_TAKEPROFIT_RATIO = 0.95;
input double ACCOUNT_STOPLOSS_RATIO = 0.20;

sinput double TRADE_STOP_PERCENTAGE = 10.0;

// 基本の6ペア
sinput string sEURUSD = "EURUSD";
sinput string sUSDJPY = "USDJPY";
sinput string sUSDCHF = "USDCHF";
sinput string sGBPUSD = "GBPUSD";
sinput string sAUDUSD = "AUDUSD";
sinput string sUSDCAD = "USDCAD";
sinput string sNZDUSD = "NZDUSD";

sinput int MAGIC = 20220806;
sinput int SLIPPAGE = 10;

#define PERIOD ((ENUM_TIMEFRAMES)TF)
#define START_BARS (int)(24 * 3600 * START_DAYS / PeriodSeconds(PERIOD))
#define BB_BARS (int)(24 * 3600 * BB_DAYS / PeriodSeconds(PERIOD))
#define TREND_BARS (int)(24 * 3600 * TREND_DAYS / PeriodSeconds(PERIOD))

enum SYMBOL_INDEX { EUR, USD, JPY, CHF, GBP, AUD, CAD, NZD, MAX_SYMBOLS };
const string SYMBOL_NAMES[] = { "EUR", "USD", "JPY", "CHF", "GBP", "AUD", "CAD", "NZD" };

struct SYMBOL_INFO {
    SYMBOL_INDEX Index;
    string Name;
    double Power[];
    double Trend;

    static void Sort(SYMBOL_INFO& array[]) {
        int array_size = ArraySize(array);
        for (int i = 0; i < array_size - 1; i++){
            for (int j = array_size - 1; j >= i + 1; j--){   //　右から左に操作
                if (array[j].Trend > array[j - 1].Trend) {
                    SYMBOL_INFO temp = array[j];
                    array[j] = array[j - 1];
                    array[j - 1] = temp;
                }
            }
        }
    }
};

MQL45_APPLICATION_START()

double InitMargin;
string CurrentSymbol;
int CurrentSign;
int CurrentCount;
double PositionLots;
int LastEntryType;
double ExpertAdviserProfit;
double MaxExpertAdviserProfit;
double MinPositionProfit;
datetime LastEntryDate;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    InitMargin = RemainingMargin();
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    double margin_percentage = 100.0 * RemainingMargin() / InitMargin;
    if (margin_percentage < TRADE_STOP_PERCENTAGE) {
        ExpertRemove();
    }

    static long prev_trailing_bar = 0;
    long current_trailing_bar = TimeCurrent() / PeriodSeconds(PERIOD_M1);
    if (current_trailing_bar > prev_trailing_bar) {
        TrailingStop();
        prev_trailing_bar = current_trailing_bar;

        if (PositionLots != 0) {
            int sign = PositionLots > 0 ? +1 : -1;
            double trend0 = sign * iTrend(CurrentSymbol, PERIOD, TREND_BARS * 1);
            double trend1 = sign * iTrend(CurrentSymbol, PERIOD, TREND_BARS * 5);
        
            double TrailingStartProfit = RemainingMargin() * ACCOUNT_TRAILING_RATIO;
            if (trend0 < 0 && TrailingStartProfit < ExpertAdviserProfit && ExpertAdviserProfit < ACCOUNT_TAKEPROFIT_RATIO * MaxExpertAdviserProfit) {
                ClosePositionAll("takeprofit");
            }
            if (ExpertAdviserProfit < -ACCOUNT_STOPLOSS_RATIO * RemainingMargin()) {
                ClosePositionAll("stoploss");
            }
        }
    }

    if (PeriodSeconds(PERIOD) < 24 * 60 * 60) {
        static long prev_trade_bar = 0;
        long current_trade_bar = TimeCurrent() / PeriodSeconds(PERIOD);
        if (current_trade_bar <= prev_trade_bar) {
            return;
        }
        else {
            prev_trade_bar = current_trade_bar;
        }
    
        long T0 = ::iTime(Symbol(), PERIOD_H1, 0) - ::iTime(Symbol(), PERIOD_D1, 0);
        if (T0 < 3600) {
            return;
        }
    }

    int T = START_BARS;
    SYMBOL_INFO Symbols[MAX_SYMBOLS];
    for (int i = 0; i < MAX_SYMBOLS; ++i) {
        Symbols[i].Index = (SYMBOL_INDEX)i;
        Symbols[i].Name = SYMBOL_NAMES[i];
        ArrayResize(Symbols[i].Power, T);
    }

    for (int t = 0; t < T; ++t) {
        double EURUSD = GetVal(sEURUSD, t, T);
        double USDJPY = GetVal(sUSDJPY, t, T);
        double USDCHF = GetVal(sUSDCHF, t, T);
        double GBPUSD = GetVal(sGBPUSD, t, T);
        double AUDUSD = GetVal(sAUDUSD, t, T);
        double USDCAD = GetVal(sUSDCAD, t, T);
        double NZDUSD = GetVal(sNZDUSD, t, T);

        double EURJPY = GetValM(sEURUSD, sUSDJPY, t, T);
        double EURCHF = GetValM(sEURUSD, sUSDCHF, t, T);
        double EURGBP = GetValD(sEURUSD, sGBPUSD, t, T);
        double CHFJPY = GetValD(sUSDJPY, sUSDCHF, t, T);
        double GBPCHF = GetValM(sGBPUSD, sUSDCHF, t, T);
        double GBPJPY = GetValM(sGBPUSD, sUSDJPY, t, T);
        double AUDCHF = GetValM(sAUDUSD, sUSDCHF, t, T);
        double AUDJPY = GetValM(sAUDUSD, sUSDJPY, t, T);
        double AUDCAD = GetValM(sAUDUSD, sUSDCAD, t, T);
        double EURCAD = GetValM(sEURUSD, sUSDCAD, t, T);
        double GBPCAD = GetValM(sGBPUSD, sUSDCAD, t, T);
        double GBPAUD = GetValD(sGBPUSD, sAUDUSD, t, T);
        double EURAUD = GetValD(sEURUSD, sAUDUSD, t, T);
        double CADCHF = GetValD(sUSDCHF, sUSDCAD, t, T);
        double CADJPY = GetValD(sUSDJPY, sUSDCAD, t, T);

        double AUDNZD = GetValD(sAUDUSD, sNZDUSD, t, T);
        double EURNZD = GetValD(sEURUSD, sNZDUSD, t, T);
        double GBPNZD = GetValD(sGBPUSD, sNZDUSD, t, T);
        double NZDCAD = GetValM(sNZDUSD, sUSDCAD, t, T);
        double NZDCHF = GetValM(sNZDUSD, sUSDCHF, t, T);
        double NZDJPY = GetValM(sNZDUSD, sUSDJPY, t, T);

        Symbols[EUR].Power[t] = ( EURUSD+EURJPY+EURCHF+EURGBP+EURAUD+EURCAD+EURNZD) / MAX_SYMBOLS;
        Symbols[USD].Power[t] = (-EURUSD+USDJPY+USDCHF-GBPUSD-AUDUSD+USDCAD-NZDUSD) / MAX_SYMBOLS;
        Symbols[JPY].Power[t] = (-EURJPY-USDJPY-CHFJPY-GBPJPY-AUDJPY-CADJPY-NZDJPY) / MAX_SYMBOLS;
        Symbols[CHF].Power[t] = (-EURCHF-USDCHF+CHFJPY-GBPCHF-AUDCHF-CADCHF-NZDCHF) / MAX_SYMBOLS;
        Symbols[GBP].Power[t] = (-EURGBP+GBPUSD+GBPCHF+GBPJPY+GBPAUD+GBPCAD+GBPNZD) / MAX_SYMBOLS;

        Symbols[AUD].Power[t] = (-EURAUD+AUDUSD+AUDJPY+AUDCHF-GBPAUD+AUDCAD+AUDNZD) / MAX_SYMBOLS;
        Symbols[CAD].Power[t] = (-EURCAD-USDCAD+CADJPY+CADCHF-GBPCAD-AUDCAD-NZDCAD) / MAX_SYMBOLS;
        Symbols[NZD].Power[t] = (-EURNZD+NZDUSD+NZDJPY+NZDCHF-GBPNZD+NZDCAD-AUDNZD) / MAX_SYMBOLS;
    }

    for (int i = 0; i < MAX_SYMBOLS; ++i) {
        Symbols[i].Trend = iCorrelation(Symbols[i].Power, TREND_BARS);
    }

    SYMBOL_INFO::Sort(Symbols);

    string symbol = Symbols[0].Name + Symbols[MAX_SYMBOLS - 1].Name;
    int type = OP_BUY;
    double price = MarketInfo(symbol, MODE_ASK);
    int sign = +1;
    if (price == 0) {
        symbol = Symbols[MAX_SYMBOLS - 1].Name + Symbols[0].Name;
        type = OP_SELL;
        price = MarketInfo(symbol, MODE_BID);
        sign = -1;
    }

    if (MinPositionProfit > 0) {
        symbol = CurrentSymbol;
        sign = CurrentSign;
    }
    double trend0 = sign * iCorrelation(symbol, PERIOD, TREND_BARS * 1);
    double trend1 = sign * iCorrelation(symbol, PERIOD, TREND_BARS * 2);

    string comment = TimeToString(TimeCurrent()) + " \n";
    comment += StringFormat("%.0f %+.0f %.2f%% \n", AccountBalance(), AccountProfit(), AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
    comment += StringFormat("%s %+.2f %+.0f \n", symbol, PositionLots, MinPositionProfit);
    comment += StringFormat("Trend %+.3f %+.3f \n", trend0, trend1);
    for (int i = 0; i < MAX_SYMBOLS; ++i) {
        comment += StringFormat("(%d) %s %+.6f \n", i + 1, Symbols[i].Name, Symbols[i].Trend);
    }
    ActiveLabel::Comment(comment);

    if (price > 0) {
        if (trend0 > trend1 && MinPositionProfit >= 0) {
            if (symbol != CurrentSymbol && MinPositionProfit < 0) {
                ClosePositionAll("symbol");
            }
    
            double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
            if (0 < margin_level && margin_level < 1500) {
                printf("WARNING: margin level = %.2f%%", margin_level);
            }
            else if (trend0 > 2 * trend1 && trend1 > 0) {
                int digits = (int)MarketInfo(symbol, MODE_DIGITS);
                double stop_level = MarketInfo(symbol, MODE_STOPLEVEL);
                double point = MarketInfo(symbol, MODE_POINT);
                double BB = iStdDev(symbol, PERIOD, BB_BARS, 0, MODE_SMA, PRICE_OPEN, 0);
                if (BB == 0) {
                    return;
                }
                price = sign == +1 ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
    
                double SL = MathMax(BB_STOPLOSS_RATIO * BB, stop_level * point);
                double sl = NormalizeDouble(type == OP_BUY ? price - SL : price + SL, digits);
                double tp = 0;
                double compound_interest = RemainingMargin() / InitMargin;
                double lots = LOTS;
                lots *= MathMax(MathFloor(MathPow(CurrentCount, 0.0) * compound_interest), 1.0);
                if (OrderSend(symbol, type, lots, price, SLIPPAGE, sl, tp, DoubleToString(margin_level, 2), MAGIC) == -1) {
                    printf("ERROR: OrderSend() FAILED: %d", GetLastError());
                }
                else {
                    CurrentSymbol = symbol;
                    CurrentSign = sign;
                    ++CurrentCount;
                }
            }
        }
    }
    else if (trend0 < 0) {
        ClosePositionAll("trend");
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
    double profit = TesterStatistics(STAT_PROFIT);
    double win_ratio = TesterStatistics(STAT_TRADES) > 0 ? TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES) : 0.0;
    double draw_down = (100.0 - TesterStatistics(STAT_BALANCE_DDREL_PERCENT)) / 100.0;
    double tester_result = profit * win_ratio * draw_down;
    return tester_result;
}

//+------------------------------------------------------------------+
//| 有効証拠金を返す                                                 |
//+------------------------------------------------------------------+
double RemainingMargin()
{
    return AccountBalance() + AccountCredit() + AccountProfit();
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
void ClosePositionAll(string reason)
{
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        int ticket = OrderTicket();
        double lots = OrderLots();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        string comment = StringFormat("%s %+.0f %.2f%%", reason, OrderProfit(), AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
        OrderCloseComment(comment);
        if (!OrderClose(ticket, lots, price, 10, arrow)) {
            printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
    }
    MaxExpertAdviserProfit = ExpertAdviserProfit = 0;
    CurrentCount = 1;
    CurrentSign = 0;
}

//+------------------------------------------------------------------+
//| トレーリングストップ                                             |
//+------------------------------------------------------------------+
void TrailingStop()
{
    static double min_position_profit = 0;

    GetPositionLots();
    if (min_position_profit == MinPositionProfit) { return; }
    min_position_profit = MinPositionProfit;

    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }

        string symbol = OrderSymbol();
        double point = MarketInfo(symbol, MODE_POINT);
        int digits = (int)MarketInfo(symbol, MODE_DIGITS);
        double stop_level = MarketInfo(symbol, MODE_STOPLEVEL);
        double BB = iStdDev(symbol, PERIOD, BB_BARS, 0, MODE_SMA, PRICE_OPEN, 0);
        double SL0 = BB_STOPLOSS_RATIO * BB;
        double TRAILING_START = BB_TRAILING_START_RATIO * SL0;
        double TRAILING_STEP = BB_TRAILING_STEP_RATIO * TRAILING_START;
        double SL = MathMax(TRAILING_STEP, stop_level * point);

        int ticket = OrderTicket();
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = MarketInfo(symbol, type == OP_BUY ? MODE_BID : MODE_ASK);
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        if (profit_price == 0.0) { continue; }
        double stoploss_price = OrderStopLoss();
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        if (profit_price > TRAILING_START) {
            if (type == OP_BUY) {
                double sl = NormalizeDouble(price - SL, digits);
                double tp = 0;
                if (sl > stoploss_price && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            } else if (type == OP_SELL) {
                double sl = NormalizeDouble(price + SL, digits);
                double tp = 0;
                if (sl < stoploss_price && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            }
        }
    }
    
    if (ExpertAdviserProfit > MaxExpertAdviserProfit) {
        MaxExpertAdviserProfit = ExpertAdviserProfit;
    }

    GetPositionLots();
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
void GetPositionLots()
{
    PositionLots = 0;
    LastEntryType = 0;
    ExpertAdviserProfit = 0;
    MinPositionProfit = OrdersTotal() == 0 ? 0.0 : +9999999999999.0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        
        datetime entry_date = OrderOpenTime();
        if (entry_date > LastEntryDate) {
            LastEntryDate = entry_date;
        }

        double lots = OrderLots();
        double profit = OrderProfit();
        double point = MarketInfo(OrderSymbol(), MODE_POINT);
        LastEntryType = OrderType() == OP_BUY ? +1 : -1;
        PositionLots += LastEntryType * lots;
        ExpertAdviserProfit += profit;
        MinPositionProfit = MathMin(profit / (lots / 0.01) / point, MinPositionProfit);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetVal(string sym1, int t1, int t2)
{
    double v1 = ::iOpen(sym1, PERIOD, t1);
    double v2 = ::iOpen(sym1, PERIOD, t2);

    if (v2 == 0) return 0;
    return MathLog(v1 / v2) * 1000;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetValM(string sym1, string sym2, int t1, int t2)
{
    double v1 = ::iOpen(sym1, PERIOD, t1);
    double v2 = ::iOpen(sym1, PERIOD, t2);

    v1 *= ::iOpen(sym2, PERIOD, t1);
    v2 *= ::iOpen(sym2, PERIOD, t2);

    if (v2 == 0) return 0;
    return MathLog(v1 / v2) * 1000;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetValD(string sym1, string sym2, int t1, int t2)
{
    double v1 = ::iOpen(sym1, PERIOD, t1);
    double v2 = ::iOpen(sym1, PERIOD, t2);
    double v3 = ::iOpen(sym2, PERIOD, t1);
    double v4 = ::iOpen(sym2, PERIOD, t2);
    if (v3 == 0) return 0;
    if (v4 == 0) return 0;

    v1 /= v3;
    v2 /= v4;

    if (v2 == 0) return 0;
    return MathLog(v1 / v2) * 1000;
}

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrend(const double& value[], int N = 0)
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    if (N < 1) { N = ArraySize(value); }
    for (int i = 0; i < N; ++i) {
        double x = -i;
        double y = value[i];
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double power = diff_xy / diff_xx;
    return power;
}

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrend(string symbol, ENUM_TIMEFRAMES tf, int N)
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    double y1 = 0;
    int minutes = PeriodSeconds(tf) / 60;
    for (int i = 0; i < N; ++i) {
        double x = -i * minutes;
        double y = ::iOpen(symbol, tf, i);
        if (y == 0.0) { return 0.0; }
        if (i == N - 1) { y1 = y; }
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double trend = diff_xy / diff_xx;
    return trend / y1 * 10000;
}

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(const double& value[], int N = 0)
{
    if (N < 1) { N = ArraySize(value); }
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = -i;
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
        double x = (-i) - avr_x;
        double y = value[i] - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(string symbol, ENUM_TIMEFRAMES tf, int N)
{
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = -i;
        double y = ::iOpen(symbol, tf, i);
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double x = (-i) - avr_x;
        double y = ::iOpen(symbol, tf, i) - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

MQL45_APPLICATION_END()
