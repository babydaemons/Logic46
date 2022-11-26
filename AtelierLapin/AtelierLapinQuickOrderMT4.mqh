//+------------------------------------------------------------------+
//|                                    AtelierLapinQuickOrderMT4.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLotSize() {
    return (int)MarketInfo(Symbol(), MODE_LOTSIZE);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetSwapType() {
    static const string swap_types[] = {
        "ポイント",
        "決済通貨",
        "金利",
        "証拠金通貨",
    };
    return swap_types[(int)MarketInfo(Symbol(), MODE_SWAPTYPE)];
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetBuySwap() {
    return MarketInfo(Symbol(), MODE_SWAPLONG);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetSellSwap() {
    return MarketInfo(Symbol(), MODE_SWAPSHORT);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetInitMargin() {
    double commodity_ask = MarketInfo(Symbol(), MODE_ASK);
    string symbol = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT) + "JPY";
    double currency_ask = symbol == "JPYJPY" ? 1 : MarketInfo(symbol, MODE_ASK);
    double volume = StringToDouble(EditLots.GetText(__LINE__));
    double lot_size = GetLotSize();
    long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
    double margin = commodity_ask * currency_ask * volume * lot_size / leverage;
    return margin;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMagicNumberProfit() {
    int magic_number = StringToInteger(EditMagicNumber.GetText(__LINE__));
    double profit = 0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        profit += OrderProfit() + OrderSwap();
    }
    return profit;
}
//+------------------------------------------------------------------+
