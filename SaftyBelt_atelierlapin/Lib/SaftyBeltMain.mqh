//+------------------------------------------------------------------+
//|                                            Lib/SaftyBeltMain.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

int Reason = -1;
long CloseTime;
long OpenTime;

const long TIME_ROUND = 24 * 60 * 60;

datetime LastChecked;

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

    EventSetTimer(1);

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
    UpdatePanel();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    UpdatePanel();
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

//+------------------------------------------------------------------+
//| ロングエントリー価格を返す                                       |
//+------------------------------------------------------------------+
double GetBuyEntry(double ask, double point, int digit) {
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        return NormalizeDouble(ask + ENTRY_WIDTH * point, digit);
    }
    else {
        return NormalizeDouble(ask * (1.00 + 0.01 * ENTRY_WIDTH), digit);
    }
}

//+------------------------------------------------------------------+
//| ショートエントリー価格を返す                                     |
//+------------------------------------------------------------------+
double GetSellEntry(double bid, double point, int digit) {
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        return NormalizeDouble(bid - ENTRY_WIDTH * point, digit);
    }
    else {
        return NormalizeDouble(bid * (1.00 - 0.01 * ENTRY_WIDTH), digit);
    }
}

//+------------------------------------------------------------------+
//| インターバル時間間隔の文字列を返す                               |
//+------------------------------------------------------------------+
string GetInterval(datetime t) {
    return StringFormat("%d:%02d", (long)t / 60, (long)t % 60);
}

//+------------------------------------------------------------------+
//| 秒単位時刻の文字列を返す                                         |
//+------------------------------------------------------------------+
string GetTimestamp(datetime t) {
    return StringFormat("%s:%02d", TimeToString(t, TIME_DATE | TIME_MINUTES), t % 60);
}

