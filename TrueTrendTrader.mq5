//+------------------------------------------------------------------+
//|                                                MTFClustering.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
sinput double   LOTS = 0.01;
sinput int      MAGIC = 20220830;
sinput int      SLIPPAGE = 10;

#define PERIOD  PERIOD_H1
const int       BARS = 3 * PeriodSeconds(PERIOD_MN1) / PeriodSeconds(PERIOD);

const double    ENTRY_TREND = 0.035;
const double    RISK_REWARD_RATIO = 2.0;
const double    ACCOUNT_SL = 1000000000;
const double    ACCOUNT_TP = RISK_REWARD_RATIO * ACCOUNT_SL;
const double    SL_PRICE_PERCENTAGE = 5.0;
const double    TIME_SPAN = 3 * PeriodSeconds(PERIOD_MN1);

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"
#include "TrueTrend.mqh"

class CTrueTrendTrader : private MQL45 {
public:
    CTrueTrendTrader() { }
    bool Initialize(string symbol) {
        m_symbol = symbol;
        m_max_profit = -FLT_MAX;
        return true;
    }

    string OnTick() {
        datetime t = TimeCurrent();

        double lots[2];
        m_profit = GetPositionCount(lots);

        R = iTrueTrend(m_symbol, PERIOD, 1.0, BARS) * 100.0;

        if (R <= 0 && lots[0] > 0) {
            CloseLimitPosition(+1);
        }
    
        if (R >= 0 && lots[1] > 0) {
            CloseLimitPosition(-1);
        }

        if (m_profit < -ACCOUNT_SL) {
            ClosePositionAll(StringFormat("SL(%+.0f)", m_profit));
            return StringFormat("%s R:%+.3f L:%+.2f S:%+.2f\n", m_symbol, R, lots[0], lots[1]);
        }
    
        m_max_profit = MathMax(m_max_profit, m_profit);
        if (m_profit > +ACCOUNT_TP && m_profit < 0.50 * m_max_profit) {
            ClosePositionAll(StringFormat("TP(%+.0f)", m_profit));
            return StringFormat("%s R:%+.3f L:%+.2f S:%+.2f\n", m_symbol, R, lots[0], lots[1]);
        }

        long current_minute = t / 60;
        if (current_minute > m_prev_minute) {
            m_prev_minute = current_minute;
            TrailingStop();
        }
    
        long interval = PeriodSeconds(PERIOD);
        if (m_profit > 0 /*&& m_profit > m_max_profit*/) {
            interval /= 12;
        }
        long current_fraction = (TimeCurrent() - PeriodSeconds(PERIOD_H1)) % interval;
        if (current_fraction == 0) {
            Trade(lots);
        }

        return StringFormat("%s R:%+07.3f L:%5.2f S:%5.2f %10s\n", m_symbol, R, lots[0], lots[1], ActiveLabel::FormatComma(m_profit, 0));
    }

    //+------------------------------------------------------------------+
    //| Trade function                                                   |
    //+------------------------------------------------------------------+
    void Trade(const double& lots[])
    {
        if (m_profit < 0) {
            return;
        }

        int entry = Sgn(R);
        static int prev_entry = 0;
        if (entry != prev_entry) {
            ClosePositionAll(StringFormat("E(%+.3f:%+.0f)", R, m_profit));
            prev_entry = entry;
        }
    
        if (MathAbs(R) < ENTRY_TREND) {
            return;
        }

        double ask = MarketInfo(m_symbol, MODE_ASK);
        double bid = MarketInfo(m_symbol, MODE_ASK);
        m_StopLoss = SL_PRICE_PERCENTAGE * ask / 100.0;
        int digits = (int)MarketInfo(m_symbol, MODE_DIGITS);

        string comment = StringFormat("R(%+.3f:%.0f)", R, RemainingBalance());
        if (entry > 0) {
            double sl = m_StopLoss > 0 ? NormalizeDouble(bid - m_StopLoss, digits) : 0;
            if (!OrderSend(m_symbol, OP_BUY, LOTS, Ask, SLIPPAGE, sl, 0, comment, MAGIC, 0, clrBlue)) {
                Alert(StringFormat("ERROR: OrderSend(OP_BUY) FAILED: %d", GetLastError()));
            }
        } else if (entry < 0) {
            double sl = m_StopLoss > 0 ? NormalizeDouble(ask + m_StopLoss, digits) : 0;
            if (!OrderSend(m_symbol, OP_SELL, LOTS, Bid, SLIPPAGE, sl, 0, comment, MAGIC, 0, clrRed)) {
                Alert(StringFormat("ERROR: OrderSend(OP_BUY) FAILED: %d", GetLastError()));
            }
        }
    }

    //+------------------------------------------------------------------+
    //| ポジション数のカウント                                           |
    //+------------------------------------------------------------------+
    double GetPositionCount(double& lots[])
    {
        double profit = 0;
        lots[0] = lots[1] = 0;
        for (int i = OrdersTotal() - 1; i >= 0; --i) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                continue;
            }
            if (OrderMagicNumber() != MAGIC) {
                continue;
            }
            if (OrderSymbol() != m_symbol) {
                continue;
            }
            lots[OrderType() == OP_BUY ? 0 : 1] += OrderLots();
            profit += OrderProfit() + OrderSwap();
        }
/*
        if (lots[0] + lots[1] > 0) {
            profit /= lots[0] + lots[1];
        }
*/
        return profit;
    }

    //+------------------------------------------------------------------+
    //| トレーリングストップ                                             |
    //+------------------------------------------------------------------+
    void TrailingStop()
    {
        datetime t = TimeCurrent();
        long minute = (t / 60) % 60;
        for (int i = OrdersTotal() - 1; i >= 0; --i) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                continue;
            }
            if (OrderMagicNumber() != MAGIC) {
                continue;
            }
            if (OrderSymbol() != m_symbol) {
                continue;
            }
    
            int ticket = OrderTicket();
            if ((ticket % 60) != minute) {
                continue;
            }

            double ask = MarketInfo(m_symbol, MODE_ASK);
            double bid = MarketInfo(m_symbol, MODE_BID);

            int type = OrderType();
            double entry = OrderOpenPrice();
            double price = type == OP_BUY ? bid : ask;
            double profit_price = type == OP_BUY ? price - entry : entry - price;

            double time_ratio = (TIME_SPAN - (t - OrderOpenTime())) / TIME_SPAN;
            if (time_ratio < 0) {
                time_ratio = 0;
            }
            double SL = time_ratio * m_StopLoss;
            double TRAILING_START = m_StopLoss * 1.5;
            double TRAILING_FIX = TRAILING_START / 3.0;
            double TRAILING_STEP = 0.5 * profit_price;
            if (TRAILING_STEP < TRAILING_FIX) {
                TRAILING_STEP = TRAILING_FIX;
            } 
            color arrow = type == OP_BUY ? clrRed : clrBlue;
            int digits = (int)MarketInfo(m_symbol, MODE_DIGITS);
            if (profit_price > TRAILING_START) {
                if (type == OP_BUY) {
                    double sl = NormalizeDouble(price - TRAILING_STEP, digits);
                    double tp = 0;
                    if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                        printf("ERROR(%d): OrderModify(#%d) FAILED: %d", __LINE__, ticket, GetLastError());
                    }
                }
                if (type == OP_SELL) {
                    double sl = NormalizeDouble(price + TRAILING_STEP, digits);
                    double tp = 0;
                    if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                        printf("ERROR(%d): OrderModify(#%d) FAILED: %d", __LINE__, ticket, GetLastError());
                    }
                }
            }
        }
    }

    //+------------------------------------------------------------------+
    //| 全ポジションクローズ                                             |
    //+------------------------------------------------------------------+
    bool CloseLimitPosition(int entry)
    {
        double min_profit = +FLT_MAX;
        int min_ticket = -1;
        int type = entry > 0 ? OP_BUY : OP_SELL;
    
        for (int i = OrdersTotal() - 1; i >= 0; --i) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                continue;
            }
            if (OrderMagicNumber() != MAGIC) {
                continue;
            }
            if (OrderSymbol() != m_symbol) {
                continue;
            }
    
            if (OrderType() == type) {
                continue;
            }
    
            double profit = OrderProfit();
            if (profit < min_profit) {
                min_profit = profit;
                min_ticket = OrderTicket();
            }
        }
    
        if (min_ticket != -1 && OrderSelect(min_ticket, SELECT_BY_TICKET, MODE_TRADES)) {
            int ticket = OrderTicket();
            double price = OrderType() == OP_BUY ? Bid : Ask;
            double lots = OrderLots();
            color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
            if (!OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
                printf("ERROR(%d): OrderClose(#%d) FAILED: %d", __LINE__, ticket, GetLastError());
            }
            return true;
        }
    
        return false;
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
            if (OrderSymbol() != m_symbol) {
                continue;
            }
    
            int ticket = OrderTicket();
            double price = OrderType() == OP_BUY ? Bid : Ask;
            double lots = OrderLots();
            color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
            double profit = OrderProfit() + OrderSwap();
            OrderCloseComment(reason);
            if (!OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
                printf("ERROR(%d): OrderClose(#%d) FAILED: %d", __LINE__, ticket, GetLastError());
            }
        }
    
        m_max_profit = -FLT_MAX;
    }

    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
    static double RemainingMargin()
    {
        return AccountBalance() + AccountCredit() + AccountProfit();
    }
    
    //+------------------------------------------------------------------+
    //|                                                                  |
    //+------------------------------------------------------------------+
    static double RemainingBalance()
    {
        return AccountBalance() + AccountCredit();
    }

private:
    string m_symbol;
    double m_profit;
    double m_max_profit;
    long m_prev_minute;
    double m_StopLoss;
    double R;
};

CTrueTrendTrader traders[];

MQL45_APPLICATION_START()

enum SYMBOLS { USD, JPY, EUR, GBP, AUD, NZD, CAD, CHF, MAX_SYMBOLS };

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    ActiveLabel::POSITION_X = 440;
    ActiveLabel::FONT_SIZE = 14;

    string symbols[];
    for (int i = 0; i < MAX_SYMBOLS; ++i) {
        for (int j = 0; j < MAX_SYMBOLS; ++j) {
            string symbol1 = EnumToString((SYMBOLS)i);
            string symbol2 = EnumToString((SYMBOLS)j);
            string symbol = symbol1 + symbol2;
            double ask1 = MarketInfo(symbol, MODE_ASK);
            if (ask1 == 0.0) {
                symbol = symbol2 + symbol1;
                double ask2 = MarketInfo(symbol, MODE_ASK);
                if (ask2 == 0.0) {
                    continue;
                }
                int N = ArraySize(symbols);
                ArrayResize(symbols, N + 1);
                symbols[N] = symbol;
            }
        }
    }

    ArrayResize(traders, ArraySize(symbols));
    for (int i = 0; i < ArraySize(traders); ++i) {
        traders[i].Initialize(symbols[i]);
    }

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
    datetime t = TimeCurrent();

    string msg = "";
    string wdays[] = { "日", "月", "火", "水", "木", "金", "土" };

    msg += TimeToString(t, TIME_DATE) + "(" + wdays[TimeDayOfWeek(t)] + ") " + TimeToString(t, TIME_SECONDS) + "\n";
    msg += StringFormat("残高       %s\n", ActiveLabel::FormatComma(AccountBalance(), 0));
    msg += StringFormat("損益       %s\n", ActiveLabel::FormatComma(AccountProfit(), 0));
    msg += StringFormat("証拠金     %s\n", ActiveLabel::FormatComma(CTrueTrendTrader::RemainingMargin(), 0));
    msg += StringFormat("維持率     %.2f%%\n", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));

    for (int i = 0; i < ArraySize(traders); ++i) {
        msg += traders[i].OnTick();
    }

    ActiveLabel::Comment(msg);

    if (CTrueTrendTrader::RemainingMargin() < 10000) {
        ExpertRemove();
        return;
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
    return 0.0;
}

MQL45_APPLICATION_END()

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(const double& value[])
{
    int N = ArraySize(value);
    if (N == 0) { return 0; }

    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = i;
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
        double x = i - avr_x;
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
double iComplexCorrelation(const double& value1[], const double& value2[])
{
    int N = ArraySize(value1);
    if (N == 0) {
        return 0.0;
    }
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = value1[i];
        double y = value2[i];
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double x = value1[i] - avr_x;
        double y = value2[i] - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Sgn(double x)
{
    if (x > 0) {
        return +1;
    }
    if (x < 0) {
        return -1;
    }
    return 0;
}
