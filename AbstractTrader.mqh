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
        _init_margin = RemainingMargin();
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
            printf("FATAL ERROR: margin %.0f was interrupted decrease %d%%", margin, _stop_trade_percentage);
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

public:
