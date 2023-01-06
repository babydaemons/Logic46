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

const double PSAR_STEP = 0.02;
const double PSAR_MAX = 0.2;
const int ADX_BARS = 14;
const int SD_BARS = 6;
const double ENTRY_CHANGE = 0.025;
sinput double LOTS = 0.01;
sinput int SLIPPAGE = 10;
sinput int MAGIC = 20230105;

CTrade trader;

enum ENUM_SYMBOL {
    XAU, XAG, USD, EUR, JPY, GBP, CHF, AUD, NZD, MAX_SYMBOL
};

enum ENUM_TREND_TYPE {
    BUY_CONTINUING = +2,
    BUY_CHANGED = +1,
    TREND_NONE = 0,
    SELL_CHANGED = -1,
    SELL_CONTINUING = -2,
};

class SymbolTrader {
public:
    SymbolTrader() : m_symbol(""), m_ticket(0), m_position(0) { }

    void Initialize(string symbol) {
        m_symbol = symbol;

        if (StringFind(m_symbol, "XA") != -1) {
            m_lots = LOTS;
        } else {
            m_lots = 10 * LOTS;
        }

        m_hADX = iADX(m_symbol, Period(), ADX_BARS);
        m_hADXMA = iMA(m_symbol, Period(), SD_BARS, 0, MODE_SMA, m_hADX);
        m_hADXSD = iStdDev(m_symbol, Period(), SD_BARS, 0, MODE_SMA, m_hADX);
        m_hSAR = iSAR(m_symbol, Period(), PSAR_STEP, PSAR_MAX);
    }

    void TrailingStop() {
        if (m_position == 0) {
            double SAR[2];
            CopyBuffer(m_hSAR, MAIN_LINE, 0, 2, SAR);

            double price[2];
            CopyClose(m_symbol, Period(), 0, 2, price);

            SL = MathAbs(price[0] - SAR[0]) / 2;
        } else {
            int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
            double price = SymbolInfoDouble(m_symbol, m_position > 0 ? SYMBOL_BID : SYMBOL_ASK);
            double sl = NormalizeDouble(m_position > 0 ? price - 0.5 * SL : price + 0.5 * SL, digits);
            if (!PositionSelectByTicket(m_ticket)) {
                double prev_sl = PositionGetDouble(POSITION_SL);
                if (m_position > 0 && sl > prev_sl) {
                    trader.PositionModify(m_ticket, sl, 0);
                } else if (m_position < 0 && sl < prev_sl) {
                    trader.PositionModify(m_ticket, sl, 0);
                }
            }
        }
    }

    void Trade() {
        ENUM_TREND_TYPE trend;
        trend = CheckTrend();

        if (m_position == 0) {
            if (DoEntryLong(trend)) {
                if (!trader.Buy(m_lots, m_symbol)) {
                    Alert(StringFormat("Cannot Entry Buy %s %.2f", m_symbol, m_lots));
                    m_ticket = 0;
                } else {
                    m_ticket = trader.ResultDeal();
                    m_position = +1;
                }
            }
            if (DoEntryShort(trend)) {
                if (!trader.Sell(m_lots, m_symbol)) {
                    Alert(StringFormat("Cannot Entry Exit %s %.2f", m_symbol, m_lots));
                    m_ticket = 0;
                } else {
                    m_ticket = trader.ResultDeal();
                    m_position = -1;
                }
            }
        } else {
            PositionSelectByTicket(m_ticket);
            double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            string comment = StringFormat("%+.0f", profit);
            if (m_position == +1) {
                bool exit_long = DoExitLong(trend);
                if (exit_long) {
                    ExitLong(comment);
                }
            } else {
                bool exit_short = DoExitShort(trend);
                if (exit_short) {
                    ExitShort(comment);
                }
            }
        }
    }

    ENUM_TREND_TYPE CheckTrend() {
        double PLUSDI[2];
        CopyBuffer(m_hADX, PLUSDI_LINE, 0, 2, PLUSDI);

        double MINUSDI[2];
        CopyBuffer(m_hADX, MINUSDI_LINE, 0, 2, MINUSDI);

        double ADX[2];
        CopyBuffer(m_hADX, MAIN_LINE, 0, 2, ADX);

        double ADXMA[2];
        CopyBuffer(m_hADXMA, MAIN_LINE, 0, 2, ADXMA);

        double ADXSD[2];
        CopyBuffer(m_hADXSD, MAIN_LINE, 0, 2, ADXSD);

        double SAR[2];
        CopyBuffer(m_hSAR, MAIN_LINE, 0, 2, SAR);

        double price[2];
        CopyClose(m_symbol, Period(), 0, 2, price);

        if (SAR[1] == 0.0 || PLUSDI[1] == 0.0 || MINUSDI[1] == 0.0) {
            return TREND_NONE;
        } else if (SAR[1] < price[1]) {
            if (SAR[0] < price[0] && ADX[0] > ADXMA[0] + ADXSD[0] && PLUSDI[0] > MINUSDI[0]) {
                return BUY_CONTINUING;
            } else if (SAR[0] > price[0] && PLUSDI[1] < MINUSDI[1] && PLUSDI[0] > MINUSDI[0]) {
                return SELL_CHANGED;
            } else {
                return TREND_NONE;
            }
        } else {
            if (SAR[0] > price[0] && ADX[0] > ADXMA[0] + ADXSD[0] && PLUSDI[0] < MINUSDI[0]) {
                return SELL_CONTINUING;
            } else if (SAR[0] < price[0] && PLUSDI[1] > MINUSDI[1] && PLUSDI[0] < MINUSDI[0]) {
                return BUY_CHANGED;
            } else {
                return TREND_NONE;
            }
        }
    }

    bool DoEntryLong(ENUM_TREND_TYPE trend) {
        if (trend <= TREND_NONE) {
            return false;
        }
        return true;
    }

    bool DoEntryShort(ENUM_TREND_TYPE trend) {
        if (trend >= TREND_NONE) {
            return false;
        }
        return true;
    }

    bool DoExitLong(ENUM_TREND_TYPE trend) {
        if (trend <= TREND_NONE) {
            return true;
        }
        return false;
    }

    bool DoExitShort(ENUM_TREND_TYPE trend) {
        if (trend >= TREND_NONE) {
            return true;
        }
        return false;
    }

    void ExitLong(string comment) {
        if (!trader.PositionClose(m_ticket, -1, comment)) {
            Alert(StringFormat("Cannot Exit %d Sell %.2f at %s #%d", m_lots, m_ticket));
        } else {
            m_ticket = m_position = 0;
        }
    }

    void ExitShort(string comment) {
        if (!trader.PositionClose(m_ticket, -1, comment)) {
            Alert(StringFormat("Cannot Exit %d Buy %.2f at %s #%d", m_lots, m_ticket));
        } else {
            m_ticket = m_position = 0;
        }
    }

private:
    string m_symbol;
    double m_lots;
    int m_hADX;
    int m_hADXMA;
    int m_hADXSD;
    int m_hSAR;
    ulong m_ticket;
    int m_position;
    double SL;
};

SymbolTrader symbol_trader[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    trader.SetExpertMagicNumber(MAGIC);

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
        symbol_trader[i].Initialize(symbols[i]);
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
    static long last_trailing = 0;
    long current_trailing = TimeCurrent() / PeriodSeconds(PERIOD_M1);
    if (current_trailing > last_trailing) {
        const int N = ArraySize(symbol_trader);
        for (int i = 0; i < N; ++i) {
            symbol_trader[i].TrailingStop();
        }
        last_trailing = current_trailing;
    }

    static long last_trade = 0;
    long current_trade = (TimeCurrent() - 2 * 60 * 60) / PeriodSeconds(PERIOD_CURRENT);
    if (current_trade > last_trade) {
        const int N = ArraySize(symbol_trader);
        for (int i = 0; i < N; ++i) {
            symbol_trader[i].Trade();
        }
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
