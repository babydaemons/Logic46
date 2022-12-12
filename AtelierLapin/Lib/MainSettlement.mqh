//+------------------------------------------------------------------+
//|                                           Lib/MainSettlement.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

const bool __DEBUGGING = false;

int Reason = -1;
long CloseTime;
long OpenTime;

const long TIME_ROUND = 24 * 60 * 60;

//+------------------------------------------------------------------+
//| 時刻の書式チェック                                               |
//+------------------------------------------------------------------+
bool CheckTimeFormat(string time, long& T)
{
    if (StringLen(time) != 5) {
        return false;
    }

    if (time[0] < '0' || '2' < time[0]) {
        return false;
    }

    if (time[1] < '0' || '9' < time[1]) {
        return false;
    }

    if (time[2] != ':') {
        return false;
    }

    if (time[3] < '0' || '5' < time[3]) {
        return false;
    }

    if (time[4] < '0' || '9' < time[4]) {
        return false;
    }

    string t[];
    StringSplit(time, ':', t);
    long hour = StringToInteger(t[0]);
    if (hour < 0 || 23 < hour) {
        return false;
    }

    long minute = StringToInteger(t[1]);
    if (minute < 0 || 59 < minute) {
        return false;
    }

    T = (long)StringToTime(time) % TIME_ROUND;

    return true;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    if (!CheckTimeFormat(CLOSE_TIME, CloseTime)) {
        MessageBox("「決済中断時刻(サーバー時刻)」の書式が不正です。\n\"00:00\"～\"23:59\"の間の時刻を入力してください。\n→パラメータ入力：" + CLOSE_TIME);
        return INIT_PARAMETERS_INCORRECT;
    }

    if (!CheckTimeFormat(OPEN_TIME, OpenTime)) {
        MessageBox("「決済再開時刻(サーバー時刻)」の書式が不正です。\n\"00:00\"～\"23:59\"の間の時刻を入力してください。\n→パラメータ入力：" + OPEN_TIME);
        return INIT_PARAMETERS_INCORRECT;
    }

    if (Reason != REASON_CHARTCHANGE && Reason != REASON_PARAMETERS) {
        InitPanel();
    }
    else {
        UpdatePanel();
    }

    if (__DEBUGGING) {
        const string SUFFIX = ".ps01";
        //const string SUFFIX = "micro";
        //const string SUFFIX = "";

        AddPosition("XAUJPY" + SUFFIX, -0.01, 123);
        AddPosition("XAUJPY" + SUFFIX, -0.01, 2000);
        AddPosition("XAUJPY" + SUFFIX, -0.01, 3000);
    
        AddPosition("XAUAUD" + SUFFIX, 0.01, 123);
        AddPosition("XAUAUD" + SUFFIX, 0.01, 1000);
        AddPosition("XAUAUD" + SUFFIX, 0.01, 2000);

        AddPosition("XAUEUR" + SUFFIX, -0.1, 1234);
        AddPosition("XAUEUR" + SUFFIX, -0.1, 20000);
        AddPosition("XAUEUR" + SUFFIX, -0.1, 30000);

        AddPosition("XAUUSD" + SUFFIX, 0.1, 1234);
        AddPosition("XAUUSD" + SUFFIX, 0.1, 10000);
        AddPosition("XAUUSD" + SUFFIX, 0.1, 20000);
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
    long t = (long)TimeCurrent() % TIME_ROUND;

    if (OpenTime == CloseTime) {
        CheckMagicNumberPositions();
    }
    else if (OpenTime < CloseTime) {
        if (OpenTime <= t && t < CloseTime) {
            CheckMagicNumberPositions();
        }
    }
    else {
        if (t < CloseTime || OpenTime <= t) {
            CheckMagicNumberPositions();
        }
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    UpdatePanel();
}
//+------------------------------------------------------------------+
