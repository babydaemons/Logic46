//+------------------------------------------------------------------+
//|                                                      Logic46.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"

const MQL45_TIMEFRAMES TIMEFRAMES[] = {
    PERIOD_M1,
    PERIOD_M5,
    PERIOD_M15,
    PERIOD_M30,
    PERIOD_H1,
    PERIOD_H4,
    PERIOD_D1,
    PERIOD_W1,
    PERIOD_MN1,
};

enum E_TIMEFRAMES {
    TIMEFRAME_M01,
    TIMEFRAME_M05,
    TIMEFRAME_M15,
    TIMEFRAME_M30,
    TIMEFRAME_H01,
    TIMEFRAME_H04,
    TIMEFRAME_D01,
    TIMEFRAME_W01,
    TIMEFRAME_MN1,
};

//--- input parameters
//input string            SYMBOLS = "USDJPY;EURUSD;GBPUSD;USDCHF;AUDUSD;EURJPY;GBPJPY;CHFJPY;AUDJPY";
//input string            SYMBOLS = "USDJPY;EURUSD;GBPUSD;USDCHF;AUDUSD";
input string            SYMBOLS = "USDJPY";
input E_TIMEFRAMES      TF = TIMEFRAME_H04;
input double            INIT_MARGIN = 100000;
input double            MIN_MARGIN_LEVEL = 1500.0;
input double            PYLAMIDDING_POWER = 0.6;
input bool              NANPIN_ENABLED = false;

input int               BAR_SCAN_BARS = 6;

input double            EMA_DAYS1 = 5.0;
input int               EMA_MULTI2 = 4;
input int               EMA_MULTI3 = 3;
input int               EMA_SCAN_BARS = 6;
input int               TOTAL_SCAN_BARS = 3;

input int               BB_DAYS1 = 10.0;
input int               BB_MULTI = 30;
input double            BB_ENTRY = 0.175;

input int               RSI_BARS = 48;
input int               RSI_SCAN_BARS = 3;
input double            RSI_ENTRY = 25.0;

input int               BB_SCAN_BARS = 2;
input double            BB_TRAILING_RATIO = 0.5;
input double            BB_STOPLOSS_RATIO = 8.0;
input double            BB_RISKREWARD_RATIO = 0.5;

input double            ACCOUNT_TRAILING_RATIO = 0.25;
input double            ACCOUNT_TAKEPROFIT_RATIO = 0.70;
input double            ACCOUNT_STOPLOSS_RATIO = 0.10;

input double            LOT = 0.01;
sinput int              STOP_BALANCE_PERCENTAGE = 40;
sinput int              SLIPPAGE = 10;
sinput int              MAGIC = 20220730;

string CommentAll;

#define TIMEFRAME TIMEFRAMES[TF]

#define EMA_BARS1 (int)(EMA_DAYS1 * 24.0 * 3600.0 / PeriodSeconds(TIMEFRAME))
#define EMA_BARS2 (EMA_BARS1 * EMA_MULTI2)
#define EMA_BARS3 (EMA_BARS2 * EMA_MULTI3)

#define BB_BARS1 (int)(BB_DAYS1 * 24.0 * 3600.0 / PeriodSeconds(TIMEFRAME))
#define BB_BARS2 (BB_BARS1 * BB_MULTI)

#define SIGNAL_ARRAY_SIZE 256

class ActiveTradeDays MQL45_DERIVERED {
public:
    ActiveTradeDays() { }

public:
    void Initialize(string symbol, int trailing_interval, int trade_interval, double min_margin_level, int stop_trade_percentage, int magic, int slippage)
    {
        _symbol = symbol;
        _trailing_interval = trailing_interval;
        _trade_interval = trade_interval;
        _min_margin_level = min_margin_level;
        _stop_trade_percentage = stop_trade_percentage;
        _magic = magic;
        _slippage = slippage;
        _init_margin = INIT_MARGIN > 0 ? INIT_MARGIN : RemainingMargin();
        _point = MarketInfo(symbol, MODE_POINT); 
        _digits = (int)MarketInfo(symbol, MODE_DIGITS);
        _prev_trailing_bar = _prev_trade_bar = 0;
        _position_max_profits[0] = _position_max_profits[1] = 0;
        _position_prev_profits[0] = _position_prev_profits[1] = 0;
        DoInitialize();
    }

    static double RemainingMargin()
    {
        return AccountBalance() + AccountCredit() + AccountProfit();
    }

    enum TRADE_TYPE { NONE = -1, BUY, SELL };

    void ChechTradeStop()
    {
        double margin = RemainingMargin();
        double margin_percentage = margin / _init_margin * 100;
        if (margin_percentage < _stop_trade_percentage) {
            printf("FATAL ERROR: margin %.0f was interrupted decrease %.3f%%", margin, _stop_trade_percentage);
            ExpertRemove();
        }
    }

public:
    void TrailingStop()
    {
        ChechTradeStop();

        long current_bar = (long)TimeCurrent() / _trailing_interval;
        if (current_bar > _prev_trailing_bar) {
            _ask = MarketInfo(_symbol, MODE_ASK);
            _bid = MarketInfo(_symbol, MODE_BID);
            DoTrailingStop();
            _prev_trailing_bar = current_bar;
        }
    }


    void DoTrailingStop()
    {
        _position_counts[0] = _position_counts[1] = 0;
        _position_profits[0] = _position_profits[1] = 0;
        _position_lots[0] = _position_lots[1] = 0;

        for (int i = OrdersTotal() - 1; i >= 0; --i) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                continue;
            }
            if (OrderMagicNumber() != _magic) {
                continue;
            }
            if (OrderSymbol() != _symbol) {
                continue;
            }
    
            int ticket = OrderTicket();
            int type = OrderType() == OP_BUY ? BUY : SELL;
            double entry = OrderOpenPrice();
            double price = type == BUY ? _bid : _ask;
            double profit_price = type == BUY ? price - entry : entry - price;
            double profit_point = profit_price / _point;
            color arrow = type == BUY ? clrBlue : clrRed;
            if (type == BUY && profit_point > TrailingStart()) {
                double sl = NormalizeDouble(price - TrailingStep() * _point, _digits);
                double tp = 0;
                if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(%s, #%d) FAILED: %d", _symbol, ticket, GetLastError());
                }
            }
            else if (type == SELL && profit_point > TrailingStart()) {
                double sl = NormalizeDouble(price + TrailingStep() * _point, _digits);
                double tp = 0;
                if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(%s, #%d) FAILED: %d", _symbol, ticket, GetLastError());
                }
            }

            _position_counts[type] += 1;
            _position_profits[type] += OrderProfit();
            _position_lots[type] += OrderLots();
        }
        
        for (int type = BUY; type <= SELL; ++type) {
            if (_position_profits[type] > _position_max_profits[type]) {
                _position_max_profits[type] = _position_profits[type];
            }
            if (_position_lots[type] != 0) {
                _position_average_profits[type] = _position_profits[type] / _position_lots[type];
            }
            else {
                _position_average_profits[type] = 0;
            }
        }

        PostTrailingStop();
    }

    void Trade()
    {
        ChechTradeStop();

        string comment;
        double lots;
        if (_trade_interval > 0) {
            long current_bar = (long)TimeCurrent() / _trade_interval;
            if (current_bar > _prev_trade_bar) {
                _ask = MarketInfo(_symbol, MODE_ASK);
                _bid = MarketInfo(_symbol, MODE_BID);
                TRADE_TYPE type = DoTrade(lots, comment);
                if (type != NONE) {
                    _last_ticket = ExecuteEntry(type, lots, comment);
                }
                _prev_trade_bar = current_bar;
            }
        }
        else {
            _ask = MarketInfo(_symbol, MODE_ASK);
            _bid = MarketInfo(_symbol, MODE_BID);
            TRADE_TYPE type = DoTrade(lots, comment);
            if (type != NONE) {
                _last_ticket = ExecuteEntry(type, lots, comment);
            }
        }
    }

    int ExecuteEntry(TRADE_TYPE type, double lots, string comment)
    {
        double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        if (margin_level > 0 && margin_level < _min_margin_level) {
            printf("ERROR: %s / %.2f lot: cannot entry: %.3f%%", _symbol, lots, margin_level);
            return -1;
        }
        
        string entry_comment = StringFormat("%s: %.0f / %.0f%%", comment, RemainingMargin(), AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));

        if (type == BUY) {
            double tp = TakeProfit() > 0 ? NormalizeDouble(_bid + TakeProfit() * _point, _digits) : 0;
            double sl = StopLoss() > 0 ? NormalizeDouble(_bid - StopLoss() * _point, _digits) : 0;
            color arrow = clrBlue;
            int ticket = OrderSend(_symbol, OP_BUY, lots, _ask, _slippage, sl, tp, entry_comment, _magic, 0, arrow);
            if (ticket == -1) {
                printf("ERROR: OrderSend(%s) FAILED: %d", _symbol, GetLastError());
            }
            return ticket;
        }

        if (type == SELL) {
            double tp = TakeProfit() > 0 ? NormalizeDouble(_ask - TakeProfit() * _point, _digits) : 0;
            double sl = StopLoss() > 0 ? NormalizeDouble(_ask + StopLoss() * _point, _digits) : 0;
            color arrow = clrRed;
            int ticket = OrderSend(_symbol, OP_SELL, lots, _bid, _slippage, sl, tp, entry_comment, _magic, 0, arrow);
            if (ticket == -1) {
                printf("ERROR: OrderSend(%s) FAILED: %d", _symbol, GetLastError());
            }
            return ticket;
        }

        return 0;
    }

    void CloseAll(TRADE_TYPE type, string close_method)
    {
        for (int i = BUY; i <= SELL; ++i) {
            _position_prev_profits[i] = _position_profits[i];
        }

        static const int order_types[] = { OP_BUY, OP_SELL };
        if (type < NONE || SELL < type) {
            printf("ERROR: type = %d, close_method = %s", type, close_method);
            DebugBreak();
        }
        int order_type = type == NONE ? INT_MAX : order_types[type];
        for (int i = OrdersTotal() - 1; i >= 0; --i) {
            if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                continue;
            }
            if (OrderMagicNumber() != _magic) {
                continue;
            }
            if (OrderSymbol() != _symbol) {
                continue;
            }
            if (order_type != INT_MAX && OrderType() != order_type) {
                continue;
            }

            int ticket = OrderTicket();
            double lots = OrderLots();
            double profit = OrderProfit();
            double price = OrderType() == OP_BUY ? _bid : _ask;
            color arrow = OrderType() == OP_BUY ? clrBlue : clrRed;
            string comments[];
            StringSplit(OrderComment(), ':', comments);
            string exit_comment = StringFormat("%s: %.0f / %+.0fJPY", comments[0], RemainingMargin(), profit);
            OrderCloseComment(exit_comment);
            if (!OrderClose(ticket, lots, price, _slippage, arrow)) {
                printf("ERROR: OrderClose(%s, #%d) FAILED: %d", _symbol, ticket, GetLastError());
            }
        }

        int type0 = type == NONE ? BUY  : type;
        int type1 = type == NONE ? SELL : type;
        for (int i = type0; i <= type1; ++i) {
            _position_counts[i] = 0;
            _position_profits[i] = 0;
            _position_lots[i] = 0;
            _position_max_profits[i] = 0;
            _position_average_profits[i] = 0;
        }
    }

    static bool IsBuyStart(const double& value[], int value_count, bool check_sign)
    {
        for (int i = 0; i < value_count - 1; ++i) {
            if (value[i] <= value[i + 1]) {
                return false;
            }
        }
        if (check_sign && value[value_count - 1] <= 0) {
            return false;
        }
        return true;
    }

    static bool IsSellStart(const double& value[], int value_count, bool check_sign)
    {
        for (int i = 0; i < value_count - 1; ++i) {
            if (value[i] >= value[i + 1]) {
                return false;
            }
        }
        if (check_sign && value[value_count - 1] >= 0) {
            return false;
        }
        return true;
    }

    static bool IsBuyEnd(const double& value[], int value_count, bool check_sign)
    {
        for (int i = 0; i < value_count - 1; ++i) {
            if (value[i] >= value[i + 1]) {
                return false;
            }
        }
        if (check_sign && value[value_count - 1] <= 0) {
            return false;
        }
        return true;
    }

    static bool IsSellEnd(const double& value[], int value_count, bool check_sign)
    {
        for (int i = 0; i < value_count - 1; ++i) {
            if (value[i] <= value[i + 1]) {
                return false;
            }
        }
        if (check_sign && value[value_count - 1] >= 0) {
            return false;
        }
        return true;
    }

    static bool IsBuyTrend(const double& value[], int value_count)
    {
        for (int i = 0; i < value_count; ++i) {
            if (value[i] < 0) {
                return false;
            }
        }
        return true;
    }

    static bool IsSellTrend(const double& value[], int value_count)
    {
        for (int i = 0; i < value_count; ++i) {
            if (value[i] > 0) {
                return false;
            }
        }
        return true;
    }

private:
    string _symbol;
    int _trailing_interval;
    int _trade_interval;
    int _magic;
    double _min_margin_level;
    int _slippage;
    int _stop_trade_percentage;
    double _init_margin;
    double _point;
    int _digits;
    long _prev_trailing_bar;
    long _prev_trade_bar;
    double _ask;
    double _bid;
    int _position_counts[2];
    double _position_profits[2];
    double _position_max_profits[2];
    double _position_average_profits[2];
    double _position_lots[2];
    double _position_prev_profits[2];
    int _last_ticket;
    int _line_close;

protected:
    void DoInitialize()
    {
        _is_trend = false;
    }

    TRADE_TYPE DoTrade(double& lots, string& comment)
    {
        if (364 < DayOfYear()) {
            return NONE;
        }
/*
        if (Hour() == 23 || Hour() == 0) {
            return NONE;
        }
*/
        for (int i = 0; i < BB_SCAN_BARS; ++i) {
            BB1[i] = iStdDev(_symbol, TIMEFRAME, BB_BARS1, 0, MODE_SMA, PRICE_OPEN, i);
            BB2[i] = iStdDev(_symbol, TIMEFRAME, BB_BARS2, 0, MODE_SMA, PRICE_OPEN, i);
        }
        
        for (int i = 0; i < RSI_SCAN_BARS; ++i) {
            RSI[i] = iRSI(_symbol, TIMEFRAME, RSI_BARS, PRICE_OPEN, i) - 50.0;
        }
        
        for (int i = 0; i < BAR_SCAN_BARS; ++i) {
            O[i] = ::iOpen(_symbol, TIMEFRAME, i);
            B[i] = ::iClose(_symbol, TIMEFRAME, i + 1) - ::iOpen(_symbol, TIMEFRAME, i + 1);
        }
        
        for (int i = 0; i < 2 * EMA_SCAN_BARS; ++i) {
            EMA1[i] = iMA(_symbol, TIMEFRAME, EMA_BARS1, 0, MODE_EMA, PRICE_OPEN, i);
            if (EMA1[i] == 0.0) { return NONE; }
            EMA2[i] = iMA(_symbol, TIMEFRAME, EMA_BARS2, 0, MODE_EMA, PRICE_OPEN, i);
            if (EMA2[i] == 0.0) { return NONE; }
            EMA3[i] = iMA(_symbol, TIMEFRAME, EMA_BARS3, 0, MODE_EMA, PRICE_OPEN, i);
            if (EMA3[i] == 0.0) { return NONE; }
            BAND1[i] = EMA1[i] - EMA2[i];
            BAND2[i] = EMA2[i] - EMA3[i];
        }

        TOTAL_BAND1[0] = TOTAL_BAND1[1] = 0;
        for (int i = 0; i < EMA_SCAN_BARS + 1; ++i) {
            for (int j = 0; j < EMA_SCAN_BARS; ++j) {
                TOTAL_BAND1[i] += BAND1[i + j];
                TOTAL_BAND2[i] += BAND2[i + j];
            }
        }

        TRADE_TYPE type = DoTrade(comment);
        if (type != NONE && _position_profits[type] >= 0.0) {
            double position_count = MathPow(MathMax(_position_counts[0], _position_counts[1]) + 1.0, PYLAMIDDING_POWER);
            double compound_interest = RemainingMargin() / _init_margin;
            lots = LOT;
            lots *= MathMax(MathFloor(position_count * compound_interest), 1.0);
        }
        ActiveLabel::Comment(StringFormat("ProfitMargin: %.0f\nMarginLevel: %.2f\n%%", RemainingMargin() - _init_margin, AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)));
        return type;
    }

    TRADE_TYPE DoTrade(string& comment)
    {
        if (BB1[0] == 0 || BB1[1] == 0 || BB2[0] == 0 || BB2[1] == 0) {
            return NONE;
        }

/*
        if (BB1[0] < BB1[1]) {
            _is_trend = false;
        }

        if (BB1[0] / BB2[0] < BB_ENTRY) {
            _is_trend = false;
        }

        if (!_is_trend) {
            TRADE_TYPE type0 = DoTrade0(comment);
            if (type0 != NONE) {
                return type0;
            }
        }

        TRADE_TYPE type1 = DoTrade1(comment);
        if (type1 != NONE) {
            _is_trend = true;
            return type1;
        }
*/

        TRADE_TYPE type2 = DoTrade2(comment);
        if (type2 != NONE) {
            _is_trend = true;
            return type2;
        }

/*
        TRADE_TYPE type3 = DoTrade3(comment);
        if (type3 != NONE) {
            _is_trend = true;
            return type3;
        }

        TRADE_TYPE type4 = DoTrade4(comment);
        if (type4 != NONE) {
            _is_trend = true;
            return type4;
        }

        TRADE_TYPE type5 = DoTrade5(comment);
        if (type5 != NONE) {
            _is_trend = true;
            return type4;
        }
*/

        return NONE;
    }

    TRADE_TYPE DoTrade0(string& comment)
    {
        if (RSI[0] < -RSI_ENTRY && IsSellEnd(RSI, RSI_SCAN_BARS, false)) {
            CloseAll(SELL, "DoTrade0(SELL)");
            comment = "BuyRange";
            return BUY;
        }

        if (RSI[0] > +RSI_ENTRY && IsBuyEnd(RSI, RSI_SCAN_BARS, false)) {
            CloseAll(BUY, "DoTrade0(SELL)");
            comment = "SellRange";
            return SELL;
        }

        return NONE;
    }

    TRADE_TYPE DoTrade1(string& comment)
    {
        if (BAND1[0] > 0 && BAND2[0] > 0) {
            CloseAll(SELL, "DoTrade1(SELL)");
            comment = "BuyPerfect";
            return BUY;
        }

        if (BAND1[0] < 0 && BAND2[0] < 0) {
            CloseAll(BUY, "DoTrade1(BUY)");
            comment = "SellPerfect";
            return SELL;
        }

        return NONE;
    }

    TRADE_TYPE DoTrade2(string& comment)
    {
        if (IsEntryEnabled(BUY) && O[0] > O[1] && B[0] > 0) {
            if (EMA1[0] > EMA1[1] && EMA2[0] > EMA2[1]) {
                if (IsBuyStart(TOTAL_BAND1, TOTAL_SCAN_BARS / 2, true) && IsBuyStart(TOTAL_BAND2, TOTAL_SCAN_BARS, true)) {
                    CloseAll(SELL, "BuyTotal(BuyStart)");
                    comment = "BuyTotal(BuyStart)";
                    return BUY;
                }
            }
        }

        if (IsEntryEnabled(SELL) && O[0] < O[1] && B[0] < 0) {
            if (EMA1[0] < EMA1[1] && EMA2[0] < EMA2[1]) {
                if (IsSellStart(TOTAL_BAND1, TOTAL_SCAN_BARS / 2, true) && IsSellStart(TOTAL_BAND2, TOTAL_SCAN_BARS, true)) {
                    CloseAll(BUY, "SellTotal(SellSttart)");
                    comment = "SellTotal(SellSttart)";
                    return SELL;
                }
            }
        }

        return NONE;
    }

    TRADE_TYPE DoTrade3(string& comment)
    {
        if (IsEntryEnabled(BUY) && IsBuyStart(O, BAR_SCAN_BARS, false) && IsBuyTrend(B, BAR_SCAN_BARS) && BAND1[0] > 0) {
            CloseAll(SELL, "DoTrade3(SELL)");
            comment = "BuyBars";
            return BUY;
        }

        if (IsEntryEnabled(SELL) && IsSellStart(O, BAR_SCAN_BARS, false) && IsSellTrend(B, BAR_SCAN_BARS) && BAND1[0] < 0) {
            CloseAll(BUY, "DoTrade3(BUY)");
            comment = "SellBars";
            return SELL;
        }

        return NONE;
    }

    TRADE_TYPE DoTrade4(string& comment)
    {
        if (IsEntryEnabled(BUY) && IsBuyTrend(B, BAR_SCAN_BARS)) {
            if (IsBuyStart(BAND1, EMA_SCAN_BARS, true)) {
                CloseAll(SELL, "DoTrade4(SELL1)");
                comment = "BuyStart";
                return BUY;
            }
            if (IsSellEnd(BAND1, EMA_SCAN_BARS, true)) {
                CloseAll(SELL, "DoTrade4(SELL2)");
                comment = "SellEnd";
                return BUY;
            }
        }
        if (IsEntryEnabled(SELL) && IsBuyTrend(B, BAR_SCAN_BARS)) {
            if (IsSellStart(BAND1, EMA_SCAN_BARS, true)) {
                CloseAll(BUY, "DoTrade4(BUY1)");
                comment = "SellStart";
                return SELL;
            }
            if (IsBuyEnd(BAND1, EMA_SCAN_BARS, true)) {
                CloseAll(BUY, "DoTrade4(BUY2)");
                comment = "BuyEnd";
                return SELL;
            }
        }

        return NONE;
    }

    TRADE_TYPE DoTrade5(string& comment)
    {
        double min_entry_profit = ACCOUNT_TRAILING_RATIO * RemainingMargin();
        if (IsEntryEnabled(BUY) && _position_profits[BUY] > min_entry_profit) {
            if (IsBuyTrend(BAND1, EMA_SCAN_BARS)) {
                comment = "BuyDiff";
                return BUY;
            }
        }
        if (IsEntryEnabled(SELL) && _position_profits[SELL] > min_entry_profit) {
            if (IsSellTrend(BAND1, EMA_SCAN_BARS)) {
                comment = "SellStart";
                return SELL;
            }
        }

        return NONE;
    }

    bool IsEntryEnabled(TRADE_TYPE type)
    {
        if (NANPIN_ENABLED) {
            return true;
        }

        TRADE_TYPE type1 = type;
        TRADE_TYPE type2 = type == BUY ? SELL : BUY;
        
        double spread = MarketInfo(_symbol, MODE_SPREAD);
        if (_position_average_profits[type1] >= -spread) {
            return true;
        }
        if (_position_average_profits[type2] <= -spread) {
            return true;
        }
        
        return false;
    }

    void PostTrailingStop()
    {
        double trailing_start_profit = RemainingMargin() * ACCOUNT_TRAILING_RATIO;
        for (int type = BUY; type <= SELL; ++type) {
            if (trailing_start_profit < _position_profits[type] && _position_profits[type] < ACCOUNT_TAKEPROFIT_RATIO * _position_max_profits[type]) {
                CloseAll((TRADE_TYPE)type, "PostTrailingStop(1)");
            }
            if (_position_profits[type] < -ACCOUNT_STOPLOSS_RATIO * RemainingMargin()) {
                CloseAll((TRADE_TYPE)type, "PostTrailingStop(2)");
            }
        }
        if (_position_average_profits[BUY] != 0 && _position_profits[SELL] != 0) {
            CloseAll(_position_average_profits[BUY] < _position_profits[SELL] ? BUY : SELL, "PostTrailingtop(3)");
        }
    }

    double TrailingStep()
    {
        return BB_TRAILING_RATIO * BB1[0] / _point;
    }

    double StopLoss()
    {
        return BB_STOPLOSS_RATIO * TrailingStep();
    }

    double TrailingStart()
    {
        return BB_RISKREWARD_RATIO * StopLoss();
    }

    double TakeProfit()
    {
        return 0.0;
    }

private:
    bool _is_trend;
    double BB1[SIGNAL_ARRAY_SIZE];
    double BB2[SIGNAL_ARRAY_SIZE];
    double RSI[SIGNAL_ARRAY_SIZE];
    double O[SIGNAL_ARRAY_SIZE];
    double B[SIGNAL_ARRAY_SIZE];
    double EMA1[SIGNAL_ARRAY_SIZE];
    double EMA2[SIGNAL_ARRAY_SIZE];
    double EMA3[SIGNAL_ARRAY_SIZE];
    double BAND1[SIGNAL_ARRAY_SIZE];
    double BAND2[SIGNAL_ARRAY_SIZE];
    double TOTAL_BAND1[SIGNAL_ARRAY_SIZE];
    double TOTAL_BAND2[SIGNAL_ARRAY_SIZE];
};

ActiveTradeDays trader[16];
string Symbols[];
int SymbolCount;

MQL45_APPLICATION_START()

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    SymbolCount = StringSplit(SYMBOLS, ';', Symbols);
    for (int i = 0; i < SymbolCount; ++i) {
        trader[i].Initialize(Symbols[i], PeriodSeconds(PERIOD_M1), PeriodSeconds(TIMEFRAME), MIN_MARGIN_LEVEL, STOP_BALANCE_PERCENTAGE, MAGIC, SLIPPAGE);
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
    for (int i = 0; i < SymbolCount; ++i) {
        trader[i].TrailingStop();
    }
    for (int i = 0; i < SymbolCount; ++i) {
        trader[i].Trade();
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

MQL45_APPLICATION_END()
