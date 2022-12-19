//+------------------------------------------------------------------+
//|                                           Lib/MainSettlement.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

const bool __DEBUGGING = false;

int Reason = -1;
long CloseTime;
long OpenTime;

const long TIME_ROUND = 24 * 60 * 60;

string GlobalVariableKey;

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
    GlobalVariableKey = StringFormat("LOCK[atelierlapin(%d)]", MAGIC_NUMBER);
    if (GlobalVariableCheck(GlobalVariableKey)) {
        datetime prev_session = (datetime)(long)GlobalVariableGet(GlobalVariableKey);
        MessageBox("指定されたマジックナンバーの決済機能EAは下記の時刻に起動済みです。\n" +
                   "→マジックナンバー：" + IntegerToString(MAGIC_NUMBER) + "\n" +
                   "→起動時刻：" + TimeToString(prev_session));
        return INIT_PARAMETERS_INCORRECT;
    }
    else {
        GlobalVariableSet(GlobalVariableKey, (long)TimeCurrent());
        GlobalVariablesFlush();
    }

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

    GlobalVariableDel(GlobalVariableKey);
    GlobalVariablesFlush();

    Reason = reason;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (IsWatching()) {
        CheckMagicNumberPositions();
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    UpdatePanel();
    GlobalVariableSet(GlobalVariableKey, GlobalVariableGet(GlobalVariableKey));
    GlobalVariablesFlush();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsWatching() {
    long t = (long)TimeCurrent() % TIME_ROUND;

    if (OpenTime == CloseTime) {
        return true;
    }
    else if (OpenTime < CloseTime) {
        if (OpenTime <= t && t < CloseTime) {
            return true;
        }
    }
    else {
        if (t < CloseTime || OpenTime <= t) {
            return true;
        }
    }

    return false;
}