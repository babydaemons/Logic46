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
//| 契約サイズ(ロットサイズ)の取得                                   |
//+------------------------------------------------------------------+
int GetLotSize() {
    return (int)MarketInfo(Symbol(), MODE_LOTSIZE);
}

//+------------------------------------------------------------------+
//| SwapTypeの取得                                                   |
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
//| BuySwapの取得                                                    |
//+------------------------------------------------------------------+
double GetBuySwap() {
    return MarketInfo(Symbol(), MODE_SWAPLONG);
}

//+------------------------------------------------------------------+
//| SellSwapの取得                                                   |
//+------------------------------------------------------------------+
double GetSellSwap() {
    return MarketInfo(Symbol(), MODE_SWAPSHORT);
}

//+------------------------------------------------------------------+
//| 発注ロット数における初期証拠金の取得                             |
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
//| 指定マジックナンバーの全損益の取得                               |
//+------------------------------------------------------------------+
double GetMagicNumberProfit() {
    int magic_number = GetMagicNumber();
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
//| マジックナンバーの取得                                           |
//+------------------------------------------------------------------+
int GetMagicNumber() {
    int magic_number = (int)StringToInteger(EditMagicNumber.GetText(__LINE__));
    return magic_number;
}

//+------------------------------------------------------------------+
//| 買い注文の送信                                                   |
//+------------------------------------------------------------------+
void SendBuyOrder() {
    int magic_number = GetMagicNumber();
    double lots = GetLotSize();
    string comment = StringFormat("atelier lapin %d", magic_number);
    int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 10, 0.0, 0.0, comment, magic_number, 0, clrBlue);
    if (ticket == -1) {
        MessageBox("買い注文が約定しませんでした", "エラー");
    }
}

//+------------------------------------------------------------------+
//| 売り注文の送信                                                   |
//+------------------------------------------------------------------+
void SendSellOrder() {
    int magic_number = GetMagicNumber();
    double lots = GetLotSize();
    string comment = StringFormat("atelier lapin %d", magic_number);
    int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 10, 0.0, 0.0, comment, magic_number, 0, clrRed);
    if (ticket == -1) {
        MessageBox("売り注文が約定しませんでした", "エラー");
    }
}
