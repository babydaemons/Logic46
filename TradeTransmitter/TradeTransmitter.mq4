//+------------------------------------------------------------------+
//|                                             TradeTransmitter.mq4 |
//|                                                     iLogix, LLC. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "iLogix, LLC."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Get("http://localhost/api/polling/start");
    EventSetMillisecondTimer(100);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Get("http://localhost/api/polling/stop");
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
    string csv_text = Get("http://localhost/api/polling/execute");
}

//+------------------------------------------------------------------+
//| HTTP GET function                                                |
//+------------------------------------------------------------------+
string Get(string uri) {
    char data[];
    char result[];
    string result_headers;
    int res = WebRequest("GET", uri, NULL, 1000, data, result, result_headers);
    int size = ArraySize(result);
    uchar result_data[];
    ArrayResize(result_data, size);
    for (int i = 0; i < size; ++i) {
        result_data[i] = result[i];
    }
    string csv_text = CharArrayToString(result_data);
    return csv_text; 
}
