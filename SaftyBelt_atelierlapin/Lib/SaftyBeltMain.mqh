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

uint enable_entry_type;

#ifdef __MQL5__
int hStdDev;
#endif

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

#ifdef __MQL5__
    if (PRICE_TYPE == PRICE_TYPE_STDDEV) {
        hStdDev = iStdDev(Symbol(), PERIOD_M1, STDDEV_MINUTES, 0, MODE_SMA, PRICE_CLOSE);
    }
#endif

    if (Reason != REASON_CHARTCHANGE && Reason != REASON_PARAMETERS) {
        InitPanel();
    }
    else {
        UpdatePanel();
    }

    EventSetTimer(1);

    enable_entry_type = ENTRY_TYPE;

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    if (reason != REASON_CHARTCHANGE && reason != REASON_PARAMETERS && reason != REASON_ACCOUNT) {
        DeleteOrderAll();
        RemovePanel();
    }

    Reason = reason;

    EventKillTimer();
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
void GetBuyEntry(double ask, double point, int digits, double& buy_entry, double& sl, double& tp) {
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        buy_entry = NormalizeDouble(ask + ENTRY_WIDTH * point, digits);
        sl = NormalizeDouble(buy_entry - STOP_LOSS * point, digits);
        tp = NormalizeDouble(buy_entry + TAKE_PROFIT * point, digits);
    }
    else if (PRICE_TYPE == PRICE_TYPE_PERCENT) {
        buy_entry = NormalizeDouble(ask * (1.00 + 0.01 * ENTRY_WIDTH), digits);
        sl = NormalizeDouble(buy_entry * (1.00 - 0.01 * STOP_LOSS), digits);
        tp = NormalizeDouble(buy_entry + (1.00 + 0.01 * TAKE_PROFIT), digits);
    }
    else {
        buy_entry = NormalizeDouble(ask + ENTRY_WIDTH * stddev, digits);
        sl = NormalizeDouble(buy_entry - STOP_LOSS * stddev, digits);
        tp = NormalizeDouble(buy_entry + TAKE_PROFIT * stddev, digits);
    }
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
}

//+------------------------------------------------------------------+
//| ショートエントリー価格を返す                                     |
//+------------------------------------------------------------------+
void GetSellEntry(double bid, double point, int digits, double& sell_entry, double& sl, double& tp) {
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        sell_entry = NormalizeDouble(bid - ENTRY_WIDTH * point, digits);
        sl = NormalizeDouble(sell_entry + STOP_LOSS * point, digits);
        tp = NormalizeDouble(sell_entry - TAKE_PROFIT * point, digits);
    }
    else if (PRICE_TYPE == PRICE_TYPE_PERCENT) {
        sell_entry = NormalizeDouble(bid * (1.00 - 0.01 * ENTRY_WIDTH), digits);
        sl = NormalizeDouble(sell_entry * (1.00 + 0.01 * STOP_LOSS), digits);
        tp = NormalizeDouble(sell_entry + (1.00 - 0.01 * TAKE_PROFIT), digits);
    }
    else {
        sell_entry = NormalizeDouble(bid - ENTRY_WIDTH * stddev, digits);
        sl = NormalizeDouble(sell_entry + STOP_LOSS * stddev, digits);
        tp = NormalizeDouble(sell_entry - TAKE_PROFIT * stddev, digits);
    }
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
}

//+------------------------------------------------------------------+
//| 買いポジションのトレーリングストップを実行するか判断する         |
//+------------------------------------------------------------------+
bool DoTrailingStopBuyPosition(double entry_price, double current_price, double point, int digits, double& sl) {
    if (!TRAILING_STOP_ENABLE) {
        return false;
    }

    double profit_price = current_price - entry_price;
    double profit_point = profit_price / point;

    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        if (profit_point < TRAILING_STOP) {
            return false;
        }
        sl = NormalizeDouble(current_price - TRAILING_STOP * point, digits);
    }
    else if (PRICE_TYPE == PRICE_TYPE_PERCENT) {
        double profit_percentage = profit_point / entry_price;
        if (profit_percentage < TRAILING_STOP) {
            return false;
        }
        sl = NormalizeDouble(current_price - (0.01 * TRAILING_STOP * entry_price), digits);
    }
    else {
        if (stddev == 0) {
            return false;
        }
        double profit_deviation = profit_point / stddev;
        if (profit_deviation < TRAILING_STOP) {
            return false;
        }
        sl = NormalizeDouble(current_price - TRAILING_STOP * stddev, digits);
    }

    return true;
}

//+------------------------------------------------------------------+
//| 売りポジションのトレーリングストップを実行するか判断する         |
//+------------------------------------------------------------------+
bool DoTrailingStopSellPosition(double entry_price, double current_price, double point, int digits, double& sl) {
    if (!TRAILING_STOP_ENABLE) {
        return false;
    }

    double profit_price = entry_price - current_price;
    double profit_point = profit_price / point;

    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        if (profit_point < TRAILING_STOP) {
            return false;
        }
        sl = NormalizeDouble(current_price + TRAILING_STOP * point, digits);
    }
    else if (PRICE_TYPE == PRICE_TYPE_PERCENT) {
        double profit_percentage = profit_point / entry_price;
        if (profit_percentage < TRAILING_STOP) {
            return false;
        }
        sl = NormalizeDouble(current_price + (0.01 * TRAILING_STOP * entry_price), digits);
    }
    else {
        if (stddev == 0) {
            return false;
        }
        double profit_deviation = profit_point / stddev;
        if (profit_deviation < TRAILING_STOP) {
            return false;
        }
        sl = NormalizeDouble(current_price + TRAILING_STOP * stddev, digits);
    }

    return true;
}

//+------------------------------------------------------------------+
//| 週末かどうか判定する                                             |
//+------------------------------------------------------------------+
bool IsWeekend() {
    MqlDateTime tm = {};
    TimeToStruct(TimeCurrent(), tm);
    return tm.day_of_week < 1 || 5 < tm.day_of_week;
}

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

