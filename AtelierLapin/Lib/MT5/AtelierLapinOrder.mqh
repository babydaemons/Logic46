//+------------------------------------------------------------------+
//|                                                   QuickOrder.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../OrderPanel.mqh"
#include "SendOrderCloseAll.mqh"
#include "ErrorDescription.mqh"

#include <Trade/Trade.mqh>
CTrade trader;

//+------------------------------------------------------------------+
//| 契約サイズ(ロットサイズ)の取得                                   |
//+------------------------------------------------------------------+
int GetLotSize() {
    return (int)SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
}

//+------------------------------------------------------------------+
//| 最大ロット数の取得                                               |
//+------------------------------------------------------------------+
double GetMaxLot() {
    return SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
}

//+------------------------------------------------------------------+
//| 最小ロット数の取得                                               |
//+------------------------------------------------------------------+
double GetMinLot() {
    return SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
}

//+------------------------------------------------------------------+
//| SwapTypeの取得                                                   |
//+------------------------------------------------------------------+
string GetSwapType() {
    static const string swap_types[] = {
        "無効",
        "ポイント",
        "決済通貨",
        "証拠金通貨",
        "口座通貨",
        "金利(商品価格)",
        "金利(ポジション始値)",
        "ポイントを終値に反映後再オープン",
        "ポイントを現在値に反映後再オープン",
    };
    return swap_types[(int)SymbolInfoInteger(Symbol(), SYMBOL_SWAP_MODE)];
}

//+------------------------------------------------------------------+
//| BuySwapの取得                                                    |
//+------------------------------------------------------------------+
double GetBuySwap() {
    return SymbolInfoDouble(Symbol(), SYMBOL_SWAP_LONG);
}

//+------------------------------------------------------------------+
//| SellSwapの取得                                                   |
//+------------------------------------------------------------------+
double GetSellSwap() {
    return SymbolInfoDouble(Symbol(), SYMBOL_SWAP_SHORT);
}

//+------------------------------------------------------------------+
//| 発注ロット数における初期証拠金の取得                             |
//+------------------------------------------------------------------+
double GetInitMargin() {
    double commodity_ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    string symbol = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT) + "JPY";
    double currency_ask = symbol == "JPYJPY" ? 1 : SymbolInfoDouble(symbol, SYMBOL_ASK);
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
    ulong magic_number = GetMagicNumber();
    double profit = 0;
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) != magic_number) {
            continue;
        }
        profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    }
    return profit;
}

//+------------------------------------------------------------------+
//| 買い注文の送信                                                   |
//+------------------------------------------------------------------+
void SendBuyOrder() {
    int magic_number = GetMagicNumber();
    double lots = GetLots();
    string comment = StringFormat("atelier lapin %d", magic_number);
    trader.SetExpertMagicNumber(magic_number);
    bool suceed = trader.Buy(lots, Symbol(), 0.0, 0.0, 0.0, comment);
    if (!suceed) {
        int error_code = GetLastError();
        string caption = StringFormat("エラー[%d]", error_code);
        string message = StringFormat("%.2fロットの買い注文が約定しませんでした。\n%s", lots, ErrorDescription(error_code));
        MessageBox(message, caption);
    }
}

//+------------------------------------------------------------------+
//| 売り注文の送信                                                   |
//+------------------------------------------------------------------+
void SendSellOrder() {
    int magic_number = GetMagicNumber();
    double lots = GetLots();
    string comment = StringFormat("atelier lapin %d", magic_number);
    trader.SetExpertMagicNumber(magic_number);
    bool suceed = trader.Sell(lots, Symbol(), 0.0, 0.0, 0.0, comment);
    if (!suceed) {
        int error_code = GetLastError();
        string caption = StringFormat("エラー[%d]", error_code);
        string message = StringFormat("%.2fロットの売り注文が約定しませんでした。\n%s", lots, ErrorDescription(error_code));
        MessageBox(message, caption);
    }
}
