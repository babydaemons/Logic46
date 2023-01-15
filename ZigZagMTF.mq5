//+------------------------------------------------------------------+
//|                                           ParabolicTraderEA1.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#import "kernel32.dll"
uint SleepEx(uint dwMilliseconds, int bAlertable);
#import

#include "MQL45/MQL45_Trade.mqh"

const int ZIGZAG_DEPTH = 12;
const int ZIGZAG_DEVIATION = 5;
const int ZIGZAG_BACKSTEP = 3;
const int ZIGZAG_MULTIPLY = 5;
const int ZIGZAG_SCANBARS = 12 * 24 * 5;
sinput double LOTS = 0.01;
sinput int SLIPPAGE = 10;
sinput int MAGIC = 20230105;

#define ZIGZAG_DEPTH1       (1 * ZIGZAG_DEPTH)
#define ZIGZAG_DEVIATION1   (1 * ZIGZAG_DEVIATION)
#define ZIGZAG_BACKSTEP1    (1 * ZIGZAG_BACKSTEP)

#define ZIGZAG_DEPTH2       (ZIGZAG_MULTIPLY * ZIGZAG_DEPTH)
#define ZIGZAG_DEVIATION2   (ZIGZAG_MULTIPLY * ZIGZAG_DEVIATION)
#define ZIGZAG_BACKSTEP2    (ZIGZAG_MULTIPLY * ZIGZAG_BACKSTEP)

CTrade trader;

enum ENUM_SYMBOL {
    //XAU, XAG, USD, EUR, JPY, GBP, CHF, AUD, NZD, MAX_SYMBOL
    CHF, JPY, MAX_SYMBOL
};

enum ENUM_TREND_TYPE {
    TREND_NONE,
    LONG_EXPANSION,
    SHORT_EXPANSION,
    LONG_CHANGED,
    SHORT_CHANGED,
    LONG_STOPLOSS1,
    SHORT_STOPLOSS1,
    LONG_STOPLOSS2,
    SHORT_STOPLOSS2,
};

struct ZIGZAG {
    double Peek;
    datetime Time;
};

class SymbolTrader {
  public:
    SymbolTrader() : m_symbol(""), TrendType(TREND_NONE), PrevZigZag2(0), entry_type(0), prev_bar(0) {
        time[0] = time[1] = 0;
        bid[0] = bid[1] = +FLT_MAX;
        ask[0] = ask[1] = -FLT_MAX;
    }

    bool Initialize(string symbol) {
        m_symbol = symbol;
        if (StringFind(m_symbol, "XA") != -1) {
            m_lots = LOTS;
        } else {
            m_lots = 10 * LOTS;
        }
        hZigZag1 = iCustom(m_symbol, Period(), "Examples\\ZigZag", ZIGZAG_DEPTH1, ZIGZAG_DEVIATION1, ZIGZAG_BACKSTEP1);
        if (hZigZag1 == INVALID_HANDLE) {
            return false;
        }
        hZigZag2 = iCustom(m_symbol, Period(), "Examples\\ZigZag", ZIGZAG_DEPTH2, ZIGZAG_DEVIATION2, ZIGZAG_BACKSTEP2);
        if (hZigZag1 == INVALID_HANDLE) {
            return false;
        }
        return true;
    }

    void TrailingStop() {
        ticket = GetTicket();
        bid[0] = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        ask[0] = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        if (ticket != 0) {
            entry_type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? +1 : -1;
            int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
            double price = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entry = PositionGetDouble(POSITION_PRICE_OPEN);
            max_profit = MathMax(max_profit, entry_type * (price - entry));
            double stop = PositionGetDouble(POSITION_SL);
            double width = max_profit > TP ? max_profit * 0.5 : SL;
            double sl = NormalizeDouble(entry_type > 0 ? price - width : price + width, digits);
            double tp = 0; //NormalizeDouble(entry_type > 0 ? price + TP : price - TP, digits);
            if (entry_type > 0) {
                if (sl > stop) {
                    trader.PositionModify(ticket, sl, tp);
                }
            }
            else {
                if (sl < stop) {
                    trader.PositionModify(ticket, sl, tp);
                }
            }
        }
        else {
            entry_type = 0;
        }
    }

    void Trade() {
        ticket = GetTicket();

        time[0] = TimeCurrent();

        if (ticket == 0) {
            int entry = GetEntrySignal();
            if (entry > 0) {
                EntryLong();
            }
            else if (entry < 0) {
                EntryShort();
            }
        }

/*
        else if (PositionSelectByTicket(ticket)) {
            int exit = GetExitSignal();
            if (entry_type > 0) {
                if (exit < 0) {
                    ExitPositions();
                    EntryShort();
                }
            }
            else if (entry_type < 0) {
                if (exit > 0) {
                    ExitPositions();
                    EntryLong();
                }
            }
        }
*/

        long current_bar = time[0] / PeriodSeconds();
        if (current_bar > prev_bar) {
            bid[1] = bid[0];
            ask[1] = ask[0];
            prev_bar = current_bar;
        }
    }

    ulong GetTicket() {
        int N = PositionsTotal();
        for (int i = 0; i < N; ++i) {
            ticket = PositionGetTicket(i);
            if (PositionGetString(POSITION_SYMBOL) != m_symbol) {
                continue;
            }
            if (PositionGetInteger(POSITION_MAGIC) != MAGIC) {
                continue;
            }
            return ticket;
        }
        return ticket = 0;
    }


    int GetEntrySignal() {
        datetime Time[];
        CopyTime(m_symbol, Period(), 0, ZIGZAG_SCANBARS, Time);

        // データは、一番古い要素が配列に割り当てられた物理メモリの先頭に配置されるように複製されます。
        double Signal[];
        CopyBuffer(hZigZag1, MAIN_LINE, 0, ZIGZAG_SCANBARS, Signal);
        ScanPeek(6, ZigZag1, Signal, Time);

        CopyBuffer(hZigZag2, MAIN_LINE, 0, ZIGZAG_SCANBARS, Signal);
        ScanPeek(2, ZigZag2, Signal, Time);
        
        int signal = GetSignal();
        if (ArraySize(ZigZag1) > 5) {
            SL = MathAbs(ZigZag1[5].Peek - ZigZag1[0].Peek);
            TP = 2 * SL;
        }

        PrevZigZag2 = ZigZag2[0].Peek;

        return signal;
    }

    int GetExitSignal() {
/*
        datetime Time[];
        CopyTime(m_symbol, Period(), 0, ZIGZAG_SCANBARS, Time);

        // データは、一番古い要素が配列に割り当てられた物理メモリの先頭に配置されるように複製されます。
        double Signal[];
        CopyBuffer(hZigZag1, MAIN_LINE, 0, ZIGZAG_SCANBARS, Signal);
        ScanPeek(2, ZigZag1, Signal, Time);

        CopyBuffer(hZigZag2, MAIN_LINE, 0, ZIGZAG_SCANBARS, Signal);
        ScanPeek(2, ZigZag2, Signal, Time);

        if (ArraySize(ZigZag2) >= 2 && ArraySize(ZigZag1) >= 2) {
            if (ZigZag2[0].Peek > ZigZag2[1].Peek) {
                if (ZigZag1[0].Peek < ZigZag1[1].Peek) {
                    return -1;
                }
            }
            if (ZigZag2[0].Peek < ZigZag2[1].Peek) {
                if (ZigZag1[0].Peek > ZigZag1[1].Peek) {
                    return +1;
                }
            }
        }
        return 0;
*/
        return GetEntrySignal();
    }

    int GetSignal() {
        if (ArraySize(ZigZag2) >= 2 && ArraySize(ZigZag1) >= 6) {
            if (ZigZag2[0].Peek > ZigZag2[1].Peek &&
                ZigZag1[0].Peek == ZigZag2[0].Peek && ZigZag1[0].Time == ZigZag2[0].Time/* &&
                ZigZag1[1].Peek == ZigZag2[1].Peek && ZigZag1[1].Time == ZigZag2[1].Time*/)
            {
                if (TrendType != LONG_EXPANSION) {
                    TrendType = LONG_EXPANSION;
                    return +1;
                }
            }
            if (ZigZag2[0].Peek < ZigZag2[1].Peek &&
                ZigZag1[0].Peek == ZigZag2[0].Peek && ZigZag1[0].Time == ZigZag2[0].Time/* &&
                ZigZag1[1].Peek == ZigZag2[1].Peek && ZigZag1[1].Time == ZigZag2[1].Time*/)
            {
                if (TrendType != SHORT_EXPANSION) {
                    TrendType = SHORT_EXPANSION;
                    return -1;
                }
            }
/*
            if (ask[0] > ZigZag1[2].Peek &&
                ZigZag1[0].Peek > ZigZag1[2].Peek &&
                ZigZag1[1].Peek > ZigZag1[3].Peek &&
                ZigZag1[2].Peek > ZigZag1[4].Peek &&
                ZigZag1[3].Peek > ZigZag1[5].Peek)
            {
                if (TrendType != LONG_CHANGED) {
                    TrendType = LONG_CHANGED;
                    return +1;
                }
            }
            if (bid[0] < ZigZag1[2].Peek &&
                ZigZag1[0].Peek < ZigZag1[2].Peek &&
                ZigZag1[1].Peek < ZigZag1[3].Peek &&
                ZigZag1[2].Peek < ZigZag1[4].Peek &&
                ZigZag1[3].Peek < ZigZag1[5].Peek)
            {
                if (TrendType != SHORT_CHANGED) {
                    TrendType = SHORT_CHANGED;
                    return -1;
                }
            }
*/
/*
            if (entry_type < 0 &&
                ZigZag1[0].Peek > ZigZag1[2].Peek &&
                ZigZag1[1].Peek > ZigZag1[3].Peek &&
                ZigZag1[2].Peek > ZigZag1[4].Peek &&
                ZigZag1[3].Peek > ZigZag1[5].Peek)
            {
                if (TrendType != LONG_STOPLOSS1) {
                    TrendType = LONG_STOPLOSS1;
                    return +1;
                }
            }
            if (entry_type > 0 &&
                ZigZag1[0].Peek < ZigZag1[2].Peek &&
                ZigZag1[1].Peek < ZigZag1[3].Peek &&
                ZigZag1[2].Peek < ZigZag1[4].Peek &&
                ZigZag1[3].Peek < ZigZag1[5].Peek)
            {
                if (TrendType != SHORT_STOPLOSS1) {
                    TrendType = SHORT_STOPLOSS1;
                    return -1;
                }
            }
*/
/*
            if (PrevZigZag2 > 0 && entry_type < 0 && PrevZigZag2 < ZigZag2[0].Peek) {
                if (TrendType != LONG_STOPLOSS2) {
                    TrendType = LONG_STOPLOSS2;
                    return +1;
                }
            }
            if (PrevZigZag2 > 0 && entry_type > 0 && PrevZigZag2 > ZigZag2[0].Peek) {
                if (TrendType != SHORT_STOPLOSS2) {
                    TrendType = SHORT_STOPLOSS2;
                    return -1;
                }
            }
*/
        }
        return 0;
    }

    void ScanPeek(int N, ZIGZAG& ZigZag[], const double& Signal[], const datetime& Time[]) {
        int k = 0;
        for (int i = ArraySize(Signal) - 1; i >= 0; --i) {
            if (Signal[i] == 0) {
                continue;
            }
            ArrayResize(ZigZag, k + 1);
            ZigZag[k].Peek = Signal[i];
            ZigZag[k].Time = Time[i];
            if (++k == N) {
                return;
            }
        }
    }

    void EntryLong() {
        string comment = GetEntryComment();
        int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
        double sl = NormalizeDouble(bid[0] - SL, digits);
        double tp = 0; //NormalizeDouble(bid[0] + TP, digits);
        if (!trader.Buy(m_lots, m_symbol, 0, sl, tp, comment)) {
            Alert(StringFormat("Cannot Entry Buy %s %.2f", m_symbol, m_lots));
        }
        time[1] = time[0];
        max_profit = -999999999;
    }

    void EntryShort() {
        string comment = GetEntryComment();
        int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
        double sl = NormalizeDouble(ask[0] + SL, digits);
        double tp = 0; //NormalizeDouble(ask[0] - TP, digits);
        if (!trader.Sell(m_lots, m_symbol, 0, sl, tp, comment)) {
            Alert(StringFormat("Cannot Entry Exit %s %.2f", m_symbol, m_lots));
        }
        time[1] = time[0];
        max_profit = -999999999;
    }

    void ExitPositions() {
        string comment = GetExitComment();
        int N = PositionsTotal();
        for (int i = N - 1; i >= 0; --i) {
            if (PositionGetSymbol(i) != m_symbol) {
                continue;
            }
            if (PositionGetInteger(POSITION_MAGIC) != MAGIC) {
                continue;
            }

            ticket = PositionGetInteger(POSITION_TICKET);
            trader.PositionClose(ticket, -1, comment);
        }
        time[1] = time[0];
        ticket = 0;
    }

    string GetEntryComment() {
        return StringFormat("%s %.0f",
                EnumToString(TrendType),
                AccountInfoDouble(ACCOUNT_BALANCE) +
                AccountInfoDouble(ACCOUNT_CREDIT) +
                AccountInfoDouble(ACCOUNT_PROFIT));
    }

    string GetExitComment() {
        double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        return StringFormat("%+.0f", profit);
    }

private:
    string m_symbol;
    double m_lots;
    ENUM_TREND_TYPE TrendType;
    int hZigZag1;
    ZIGZAG ZigZag1[];
    int hZigZag2;
    ZIGZAG ZigZag2[];
    double PrevZigZag2;
    int entry_type;
    ulong ticket;
    double max_profit;
    int n;
    datetime time[2];
    double bid[2];
    double ask[2];
    long prev_bar;
    double SL;
    double TP;
};

SymbolTrader symbol_trader[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    trader.SetExpertMagicNumber(MAGIC);
    trader.LogLevel(LOG_LEVEL_NO);

    string symbols[];
    for (int i = 0; i < MAX_SYMBOL - 1; ++i) {
        for (int j = i + 1; j < MAX_SYMBOL; ++j) {
            string symbol = EnumToString((ENUM_SYMBOL)i) + EnumToString((ENUM_SYMBOL)j);
            if (SymbolInfoDouble(symbol, SYMBOL_ASK) == 0.0) {
                symbol = EnumToString((ENUM_SYMBOL)j) + EnumToString((ENUM_SYMBOL)i);
                if (SymbolInfoDouble(symbol, SYMBOL_ASK) == 0.0) {
                    continue;
                }
            }
            int n = ArraySize(symbols);
            ArrayResize(symbols, n + 1, n);
            symbols[n] = symbol;
        }
    }

    const int N = ArraySize(symbols);
    ArrayResize(symbol_trader, N);
    for (int i = 0; i < N; ++i) {
        if (!symbol_trader[i].Initialize(symbols[i])) {
            return INIT_FAILED;
        }
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    datetime T = TimeCurrent();

    double balance = AccountInfoDouble(ACCOUNT_BALANCE) + AccountInfoDouble(ACCOUNT_CREDIT);
    double profit = AccountInfoDouble(ACCOUNT_PROFIT);
    Comment(StringFormat("%s %.0f %.0f %+.0f %.0f%%",
        TimeToString(T), balance, balance + profit, profit, AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)));

    static long last_trailing = 0;
    long current_trailing = T / PeriodSeconds(PERIOD_M1);
    if (current_trailing > last_trailing) {
        const int N = ArraySize(symbol_trader);
        for (int i = 0; i < N; ++i) {
            symbol_trader[i].TrailingStop();
        }
        last_trailing = current_trailing;
    }

    static long last_trade = 0;
    long current_trade = T / PeriodSeconds(PERIOD_M1);
    if (current_trade > last_trade) {
        MqlDateTime time;
        TimeToStruct(T, time);
        //if (time.hour == 2) {
            const int N = ArraySize(symbol_trader);
            for (int i = 0; i < N; ++i) {
                symbol_trader[i].Trade();
            }
        //}
        last_trade = current_trade;
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester() {
    double profit = TesterStatistics(STAT_PROFIT);
    double win_ratio = TesterStatistics(STAT_TRADES) > 0 ? TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES) : 0.0;
    double draw_down = (100.0 - TesterStatistics(STAT_BALANCE_DDREL_PERCENT)) / 100.0;
    double tester_result = profit * win_ratio * draw_down;
    return tester_result;
}
//+------------------------------------------------------------------+
