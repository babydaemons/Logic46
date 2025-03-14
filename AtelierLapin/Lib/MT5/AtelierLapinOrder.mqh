﻿//+------------------------------------------------------------------+
//|                                        Lib/AtelierLapinOrder.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

#include "../PanelOrder.mqh"
#include "AtelierLapinCommon.mqh"
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
        "金利(現在値)",
        "金利(ポジ始値)",
        "ポジ再オープン",
        "ポジ再オープン",
    };
    int swap_type = __DEBUGGING ? 8 : (int)SymbolInfoInteger(Symbol(), SYMBOL_SWAP_MODE);
    return swap_types[swap_type];
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
    double currency_ask = 1.0;
    if (symbol != "JPYJPY") {
        SymbolSelect(symbol, true);
        currency_ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }
    double volume = StringToDouble(EditLots.GetText(__LINE__));
    double lot_size = GetLotSize();
    long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
    double margin = commodity_ask * currency_ask * volume * lot_size / leverage;
    return margin;
}

//+------------------------------------------------------------------+
//| 発注ロット数における初期スプレッド損失の取得                     |
//+------------------------------------------------------------------+
double GetInitSpreadLoss() {
    double commodity_spread = SymbolInfoDouble(Symbol(), SYMBOL_BID) - SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    string symbol = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT) + "JPY";
    double currency_ask = 1.0;
    if (symbol != "JPYJPY") {
        SymbolSelect(symbol, true);
        currency_ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }
    double volume = StringToDouble(EditLots.GetText(__LINE__));
    double lot_size = GetLotSize();
    double loss = commodity_spread * currency_ask * volume * lot_size;
    return loss;
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
