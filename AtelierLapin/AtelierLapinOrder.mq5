//+------------------------------------------------------------------+
//|                                            AtelierLapinOrder.mq5 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Lib/MT5/AtelierLapinOrder.mqh"

int Reason = -1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    if (Reason != REASON_CHARTCHANGE && Reason != REASON_PARAMETERS) {
        InitPanel();
    }

    EventSetTimer(5);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();

    if (reason != REASON_CHARTCHANGE && reason != REASON_PARAMETERS && reason != REASON_ACCOUNT) {
        RemovePanel();
    }

    Reason = reason;
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
    UpdatePanel();
}
//+------------------------------------------------------------------+
