//+------------------------------------------------------------------+
//|                                           ParabolicTraderEA1.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "MQL45/MQL45_Trade.mqh"

//#define EXECUTE_TRAILINGSTOP

const int ZIGZAG_DEPTH1 = 12 * PeriodSeconds(PERIOD_D1) / PeriodSeconds();
const int ZIGZAG_DEVIATION1 = 5 * PeriodSeconds(PERIOD_D1) / PeriodSeconds();
const int ZIGZAG_BACKSTEP1 = 3 * PeriodSeconds(PERIOD_D1) / PeriodSeconds();
const int ZIGZAG_SCANBARS = 12 * 24 * 5;
const int STDDEV_BARS = 22 * PeriodSeconds(PERIOD_D1) / PeriodSeconds();
const int N = PeriodSeconds(PERIOD_W1) / PeriodSeconds();
sinput double LOTS = 0.01;
sinput int SLIPPAGE = 10;
sinput int MAGIC = 20230105;

CTrade trader;

enum ENUM_SYMBOL {
    //XAU, XAG, USD, EUR, JPY, GBP, CHF, AUD, NZD, MAX_SYMBOL
    USD, EUR, /*JPY, GBP, CHF, AUD, NZD,*/ MAX_SYMBOL
    //CHF, JPY, MAX_SYMBOL
};

enum ENUM_TREND_TYPE {
    TREND_NONE,
    LONG_TREND,
    SHORT_TREND,
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
    SymbolTrader() : m_symbol(""), TrendType(TREND_NONE), entry_type(0), prev_bar(0) {
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
        hStdDev = iBands(m_symbol, Period(), STDDEV_BARS, 0, 2.0, PRICE_OPEN);
        if (hStdDev == INVALID_HANDLE) {
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
#ifdef EXECUTE_TRAILINGSTOP
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
#endif // EXECUTE_TRAILINGSTOP
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
                Alert("LONG Entry");
            }
            else if (entry < 0) {
                EntryShort();
                Alert("SHORT Entry");
            }
        }
        else if (PositionSelectByTicket(ticket)) {
            int exit = GetExitSignal();
            double profit = PositionGetDouble(POSITION_PROFIT);
            if (entry_type > 0) {
                if (exit <= 0) {
                    if (profit < 0) {
                        Alert(StringFormat("#%d LONG: %.0f Loss", profit));
                    }
                    ExitPositions();
                    if (exit < 0) {
                        EntryShort();
                    }
                }
            }
            else if (entry_type < 0) {
                if (exit >= 0) {
                    if (profit < 0) {
                        Alert(StringFormat("#%d SHORT: %.0f Loss", profit));
                    }
                    ExitPositions();
                    if (exit > 0) {
                        EntryLong();
                    }
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
        const int POSITIONS = PositionsTotal();
        for (int i = 0; i < POSITIONS; ++i) {
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
        ScanPeek(ZigZag1, Signal, Time);

        CopyBuffer(hStdDev, UPPER_BAND, 0, N + 1, Upper);
        CopyBuffer(hStdDev, LOWER_BAND, 0, N + 1, Lower);

        int signal = 0;

        // データは、一番古い要素が配列に割り当てられた物理メモリの先頭に配置されるように複製されます。
        while (ArraySize(ZigZag1) > 3 && ArraySize(Upper) > N) {
            double Band0 = Upper[N] - Lower[N];
            double Band1 = Upper[0] - Lower[0];
            if (Band0 < Band1) {
                TrendType = TREND_NONE;
                signal = 0;
                break;
            }
            if (bid[0] < Upper[0] &&
                ZigZag1[0].Peek < ZigZag1[2].Peek/* && ZigZag1[1].Peek < ZigZag1[3].Peek &&
                ZigZag1[2].Peek < ZigZag1[4].Peek && ZigZag1[3].Peek < ZigZag1[5].Peek*/) {
                if (TrendType != SHORT_TREND) {
                    TrendType = SHORT_TREND;
                }
                signal = -1;
                break;
            }
            if (ask[0] > Lower[0] &&
                ZigZag1[0].Peek > ZigZag1[2].Peek/* && ZigZag1[1].Peek > ZigZag1[3].Peek &&
                ZigZag1[2].Peek > ZigZag1[4].Peek && ZigZag1[3].Peek > ZigZag1[5].Peek*/) {
                if (TrendType != LONG_TREND) {
                    TrendType = LONG_TREND;
                }
                signal = +1;
                break;
            }
        }

/*
        if (ArraySize(ZigZag1) > 2) {
            SL = MathAbs(ZigZag1[1].Peek - ZigZag1[0].Peek);
            TP = 2 * SL;
        }
*/
        SL = ask[0] * 0.05;

        return signal;
    }

    int GetExitSignal() {
        datetime Time[];
        CopyTime(m_symbol, Period(), 0, ZIGZAG_SCANBARS, Time);

        // データは、一番古い要素が配列に割り当てられた物理メモリの先頭に配置されるように複製されます。
        double Signal[];
        CopyBuffer(hZigZag1, MAIN_LINE, 0, ZIGZAG_SCANBARS, Signal);
        ScanPeek(ZigZag1, Signal, Time);

        CopyBuffer(hStdDev, UPPER_BAND, 0, N + 1, Upper);
        CopyBuffer(hStdDev, LOWER_BAND, 0, N + 1, Lower);

        int signal = 0;

        // データは、一番古い要素が配列に割り当てられた物理メモリの先頭に配置されるように複製されます。
        while (ArraySize(ZigZag1) > 3 && ArraySize(Upper) > N) {
            double Band0 = Upper[N] - Lower[N];
            double Band1 = Upper[0] - Lower[0];
            if (Band0 < Band1) {
                TrendType = TREND_NONE;
                signal = 0;
                break;
            }
            if (ZigZag1[0].Peek < ZigZag1[2].Peek/* && ZigZag1[1].Peek < ZigZag1[3].Peek &&
                ZigZag1[2].Peek < ZigZag1[4].Peek && ZigZag1[3].Peek < ZigZag1[5].Peek*/) {
                if (entry_type > 0) {
                    TrendType = SHORT_CHANGED;
                }
                signal = -1;
                break;
            }
            if (ZigZag1[0].Peek > ZigZag1[2].Peek/* && ZigZag1[1].Peek > ZigZag1[3].Peek &&
                ZigZag1[2].Peek > ZigZag1[4].Peek && ZigZag1[3].Peek > ZigZag1[5].Peek*/) {
                if (entry_type < 0) {
                    TrendType = LONG_CHANGED;
                }
                signal = +1;
                break;
            }
        }

        return signal;
    }


    void ScanPeek(ZIGZAG& ZigZag[], const double& Signal[], const datetime& Time[]) {
        int k = 0;
        for (int i = ArraySize(Signal) - 1; i >= 0; --i) {
            if (Signal[i] == 0) {
                continue;
            }
            ArrayResize(ZigZag, k + 1);
            ZigZag[k].Peek = Signal[i];
            ZigZag[k].Time = Time[i];
            ++k;
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
        const int POSITIONS = PositionsTotal();
        for (int i = POSITIONS - 1; i >= 0; --i) {
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
    int hStdDev;
    double Upper[];
    double Lower[];
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

    const int SYMBOLS = ArraySize(symbols);
    ArrayResize(symbol_trader, SYMBOLS);
    for (int i = 0; i < SYMBOLS; ++i) {
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

    const int SYMBOLS = ArraySize(symbol_trader);

    static long last_trailing = 0;
    long current_trailing = T / PeriodSeconds(PERIOD_M1);
    if (current_trailing > last_trailing) {
        for (int i = 0; i < SYMBOLS; ++i) {
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
            for (int i = 0; i < SYMBOLS; ++i) {
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
