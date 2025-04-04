//+------------------------------------------------------------------+
//|                                            QuickSpeculatorEA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "QuickSpeculatorEA.dll"

#include <Trade/Trade.mqh>

#define UPDATE_INTERVAL 100

CTrade Trader;

ulong LastUpdate;
double OrderLots = 0.01;
int TakeProfit = 200000;
int StopLoss = -100000;
double TotalLots;
double TotalProfit;
int OrderType;

enum ENUM_EXECUTE_TYPE {
    EXECUTE_TYPE_NONE = 0,
    EXECUTE_TYPE_BUY = 1,
    EXECUTE_TYPE_SELL = -1,
    EXECUTE_TYPE_SETTLEMENT = 2,
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
    EventSetMillisecondTimer(25);
    QuickSpeculator::Show(GetPanelInfo(), ChartGetInteger(0, CHART_WINDOW_HANDLE), OrderLots, TakeProfit, StopLoss);

    Sleep(250);
    Update();

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
    EventKillTimer();
    QuickSpeculator::Hide();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    Update();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    if (GetTickCount64() - LastUpdate < UPDATE_INTERVAL) {
        return;
    }
    Update();
}

//+------------------------------------------------------------------+
//| トレードパネル情報の取得とトレードの実行                         |
//+------------------------------------------------------------------+
void Update() {
    int errorSetParent = 0;
    int errorMoveWindow = 0;
    QuickSpeculator::Update(GetPanelInfo(), OrderLots, TakeProfit, StopLoss, OrderType, errorSetParent, errorMoveWindow);
    if (errorSetParent != 0) {
        printf("ERROR: SetParent(): %d", errorSetParent);
    }
    if (errorMoveWindow != 0) {
        printf("ERROR: MoveWindow(): %d", errorMoveWindow);
    }
    
    if (OrderType == EXECUTE_TYPE_BUY) {
        if (!Trader.Buy(OrderLots, Symbol(), 0.0, 0.0, 0.0, "QuickSpeculator")) {
            Alert(StringFormat("Cannot Buy %.2f Lot", OrderLots));
        }
    }
    else if (OrderType == EXECUTE_TYPE_SELL) {
        if (!Trader.Sell(OrderLots, Symbol(), 0.0, 0.0, 0.0, "QuickSpeculator")) {
            Alert(StringFormat("Cannot Sell %.2f Lot", OrderLots));
        }
    }
    else if (OrderType == EXECUTE_TYPE_SETTLEMENT) {
        ExecuteSettlement();
    }
    else {
        if (TotalProfit < StopLoss || TakeProfit < TotalProfit) {
            ExecuteSettlement();
        }
    }

    LastUpdate = GetTickCount64();
}

//+------------------------------------------------------------------+
//| トレードパネル情報の取得                                         |
//+------------------------------------------------------------------+
string GetPanelInfo() {
    GetTotalPositions();

    string panelInfo =
        // 発注証拠金
        DoubleToString(GetInitMargin(), 0) + " " +
        // 発注スプレッド損失
        DoubleToString(GetInitSpreadLoss(), 0) + " " +
        // 口座残高
        DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 0) + " " +
        // 有効証拠金
        DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE) + AccountInfoDouble(ACCOUNT_CREDIT) + AccountInfoDouble(ACCOUNT_PROFIT), 0) + " " +
        // 必要証拠金
        DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 0) + " " +
        // 余剰証拠金
        DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 0) + " " +
        // 証拠金維持率
        DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2) + " " +
        // 全ロット数
        DoubleToString(TotalLots, 2) + " " +
        // 全損益
        DoubleToString(TotalProfit, 0);

    return panelInfo;
}

//+------------------------------------------------------------------+
//| 契約サイズ(ロットサイズ)の取得                                   |
//+------------------------------------------------------------------+
int GetLotSize() {
    return (int)SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
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
    double volume = OrderLots;
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
    double volume = OrderLots;
    double lot_size = GetLotSize();
    double loss = commodity_spread * currency_ask * volume * lot_size;
    return loss;
}

//+------------------------------------------------------------------+
//| 発注ロット済み全ロット数／全損益                                 |
//+------------------------------------------------------------------+
void GetTotalPositions() {
    TotalLots = TotalProfit = 0;
    int position_count = PositionsTotal();
    for (int i = 0; i < position_count; ++i) {
        if (PositionGetSymbol(i) != Symbol()) {
            continue;
        }
        TotalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        TotalLots += (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? +1 : -1) * PositionGetDouble(POSITION_VOLUME);
    }
}

//+------------------------------------------------------------------+
//| 全ポジション清算                                                 |
//+------------------------------------------------------------------+
void ExecuteSettlement() {
    int position_count = PositionsTotal();
    for (int i = position_count - 1; i >= 0; --i) {
        if (PositionGetSymbol(i) != Symbol()) {
            continue;
        }
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        Trader.PositionClose(ticket);
    }
}
