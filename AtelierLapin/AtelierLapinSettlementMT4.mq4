//+------------------------------------------------------------------+
//|                                    AtelierLapinQuickOrderMT4.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

sinput int MAGIC_NUMBER = 12345678; // マジックナンバー
sinput int TAKE_PROFIT = 100000; // 利確金額
sinput int STOP_LOSS = 50000; // 損切金額
sinput string DUMMY1 = "【24時間稼働は00:00】"; // ●決済中断時刻設定
sinput string CLOSE_TIME = "15:00"; // 決済中断時刻(サーバー時刻)
sinput string DUMMY2 = "【24時間稼働は00:00】"; // ●決済再開時刻設定
sinput string OPEN_TIME = "01:00"; // 決済再開時刻(サーバー時刻)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    datetime t1 = StringToTime("01:00");
    datetime t2 = StringToTime("23:59");
    datetime t3 = StringToTime("25:61");
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

}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {

}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
    if (id == CHARTEVENT_OBJECT_CLICK && sparam == "CheckboxEnableOrder") {
        bool pressed = (bool)ObjectGetInteger(0, "CheckboxEnableOrder", OBJPROP_STATE);
        if (pressed) {
        }
        Sleep(500);
    }

}
//+------------------------------------------------------------------+
