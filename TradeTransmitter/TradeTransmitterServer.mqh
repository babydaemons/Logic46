//+------------------------------------------------------------------+
//|                                       TradeTransmitterServer.mqh |
//|                          Copyright 2024, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

#include "TradeTransmitter.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    EventSetMillisecondTimer(100);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    string csv_text = Get(URL);
    string lines[];
    int n = StringSplit(csv_text, '\n', lines) - 1;
    // MessageBox(csv_text);
    for (int i = 1; i < n; ++i) {
        string field[];
        StringSplit(lines[i], ',', field);
        // タブ区切りファイルの仕様
        // 0列目：証券会社のWebサイトのドメイン名
        string brokerSite = field[0];
        // 1列目：口座番号
        string accountNumber = field[1];
        // 2列目："entry": ポジション追加 ／ "exit": ポジション削除
        string change = field[2];
        // 3列目："long": 買い建て ／ "short": 売り建て
        string command = field[3];
        // 4列目：シンボル名
        string symbol = field[4];
        // 5列目：ポジションサイズ
        double lots = RoundLots(symbol, StringToDouble(field[5]) * LOTS_MULTIPLY);
        // 6列目：ポジションID(送信元証券会社名/口座番号)
        string position_id = field[6];
        // マジックナンバー：口座番号で代用
        int magic_number = (int)StringToInteger(accountNumber);
        if (change == "entry") {
            Entry(command, symbol, lots, magic_number, position_id);
        }
        else {
            Exit(command, symbol, lots, magic_number, position_id);
        }
    }
}
