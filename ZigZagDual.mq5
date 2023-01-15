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
const int ZIGZAG_DEVIATION = 15;
const int ZIGZAG_BACKSTEP = 3;
input int ZIGZAG_MULTIPLY = 10;
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

class SymbolTrader {
  public:
    SymbolTrader() : m_symbol(""), entry_type(0), EntryPeek2(0), prev_bar(0) {
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
        ulong ticket = GetTicket();
        bid[0] = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        ask[0] = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        // データは、一番古い要素が配列に割り当てられた物理メモリの先頭に配置されるように複製されます。
        CopyBuffer(hZigZag1, MAIN_LINE, 0, ZIGZAG_SCANBARS, ZigZag1); ArraySetAsSeries(ZigZag1, true);
        CopyBuffer(hZigZag2, MAIN_LINE, 0, ZIGZAG_SCANBARS, ZigZag2); ArraySetAsSeries(ZigZag2, true);
        CopyTime(m_symbol, Period(), 0, ZIGZAG_SCANBARS, Time);  ArraySetAsSeries(Time, true);

        if (ticket != 0) {
/*
            int entry_type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? +1 : -1;
            int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
            double price = entry_type > 0 ? bid[0] : ask[0];
            double stop = PositionGetDouble(POSITION_SL);
            double sl = NormalizeDouble(entry_type > 0 ? price - SL : price + SL, digits);
            double tp = NormalizeDouble(entry_type > 0 ? price + TP : price - TP, digits);
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
*/
        }
    }

    void Trade() {
        ulong ticket = GetTicket();

        time[0] = TimeCurrent();

        string comment1 = GetEntryComment();
        string comment2 = GetExitComment();
        if (ticket == 0) {
            int entry = GetEntrySignal();
            if (entry > 0) {
                EntryLong(comment1);
            }
            else if (entry < 0) {
                EntryShort(comment1);
            }
        } else if (PositionSelectByTicket(ticket)) {
            entry_type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? +1 : -1;
            int exit = GetExitSignal();
            if (entry_type > 0) {
                if (exit < 0) {
                    ExitPositions(comment2);
                    EntryShort(comment1);
                }
                else if (Peek2[0] < EntryPeek2) {
                    ExitPositions(comment2);
                    EntryShort(comment1);
                }
            }
            else if (entry_type < 0) {
                if (exit > 0) {
                    ExitPositions(comment2);
                    EntryLong(comment1);
                }
                else if (Peek2[0] > EntryPeek2) {
                    ExitPositions(comment2);
                    EntryLong(comment1);
                }
            }
        }

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
            ulong ticket = PositionGetTicket(i);
            if (PositionGetString(POSITION_SYMBOL) != m_symbol) {
                continue;
            }
            if (PositionGetInteger(POSITION_MAGIC) != MAGIC) {
                continue;
            }
            return ticket;
        }
        return 0;
    }

    int GetEntrySignal() {
        if (ArraySize(ZigZag1) < ZIGZAG_SCANBARS) {
            return 0;
        }
        if (ArraySize(ZigZag2) < ZIGZAG_SCANBARS) {
            return 0;
        }
        ScanPeek(ZigZag1, Peek1, Index1);
        ScanPeek(ZigZag2, Peek2, Index2);
        if (ArraySize(Peek2) > 2) {
            if (Peek2[0] < Peek2[1]) {
                // 買いトレンド転換待ち
                n = 0;
                while (n < ArraySize(Peek1) && Peek1[n] != Peek2[0]) {
                    ++n;
                }
                if (n + 2 < ArraySize(Peek1)) {
                    if (Peek2[1] == Peek1[n + 1]) {
                        SL = TP = ask[0] * 0.50;
                        return +1;
                    }
                    if (ask[0] > Peek1[n + 1]) {
                        SL = TP = ask[0] * 0.50;
                        return +1;
                    }
                }
            }
            else {
                // 売りトレンド転換待ち
                n = 0;
                while (n < ArraySize(Peek1) && Peek1[n] != Peek2[0]) {
                    ++n;
                }
                if (n + 2 < ArraySize(Peek1)) {
                    if (Peek2[1] == Peek1[n + 1]) {
                        SL = TP = ask[0] * 0.50;
                        return -1;
                    }
                    if (bid[0] < Peek1[n + 1]) {
                        SL = TP = ask[0] * 0.50;
                        return -1;
                    }
                }
            }
        }
        SL = TP = 0;
        return 0;
    }

    int GetExitSignal() {
        int exit =  GetEntrySignal();
        if (entry_type > 0) {
            if (Peek2[0] > EntryPeek2) {
                EntryPeek2 = Peek2[0];
            }
        }
        else {
            if (Peek2[0] < EntryPeek2) {
                EntryPeek2 = Peek2[0];
            }
        }
        return exit;
    }

    void ScanPeek(const double& value[], double& peek[], int& index[]) {
        int k = 0;
        for (int i = 0; i < ZIGZAG_SCANBARS; ++i) {
            if (value[i] == 0) {
                continue;
            }
            ArrayResize(peek, k + 1);
            ArrayResize(index, k + 1);
            peek[k] = value[i];
            index[k] = i;
            ++k;
        }
    }

    void EntryLong(string comment) {
        int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
        double sl = 0;//NormalizeDouble(bid[0] - SL, digits);
        double tp = 0;//NormalizeDouble(bid[0] + TP, digits);
        if (!trader.Buy(m_lots, m_symbol, 0, sl, tp, comment)) {
            Alert(StringFormat("Cannot Entry Buy %s %.2f", m_symbol, m_lots));
        }
        time[1] = time[0];
        EntryPeek2 = Peek2[0];
    }

    void EntryShort(string comment) {
        int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
        double sl = 0;//NormalizeDouble(ask[0] + SL, digits);
        double tp = 0;//NormalizeDouble(ask[0] - TP, digits);
        if (!trader.Sell(m_lots, m_symbol, 0, sl, tp, comment)) {
            Alert(StringFormat("Cannot Entry Exit %s %.2f", m_symbol, m_lots));
        }
        time[1] = time[0];
        EntryPeek2 = Peek2[0];
    }

    void ExitPositions(string comment) {
        int N = PositionsTotal();
        for (int i = N - 1; i >= 0; --i) {
            if (PositionGetSymbol(i) != m_symbol) {
                continue;
            }
            if (PositionGetInteger(POSITION_MAGIC) != MAGIC) {
                continue;
            }

            ulong ticket = PositionGetInteger(POSITION_TICKET);
            trader.PositionClose(ticket, -1, comment);
        }
        time[1] = time[0];
        EntryPeek2 = 0;
    }

    string GetEntryComment() {
        return StringFormat("%.0f",
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
    int hZigZag1;
    double ZigZag1[];
    double Peek1[];
    int Index1[];
    int hZigZag2;
    double ZigZag2[];
    double Peek2[];
    int entry_type;
    double EntryPeek2;
    int Index2[];
    datetime Time[];
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
    long current_trade = T / PeriodSeconds();
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
