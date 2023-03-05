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
int currency_digits;
bool is_testing;

int SecondsOfWeek(int day, int hour, int minute, int second) {
    return ((day * 60 + hour) + minute) * 60 + second;
}
int T1 = SecondsOfWeek(1,  0,  0,  0);
int T2 = SecondsOfWeek(5, 23, 59, 59);

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

    if (ORDER_MODIFY_INTERVAL_SECONDS <= 0) {
        MessageBox("「逆指値更新間隔(秒)」はゼロより大きい秒数を指定してください。\n→パラメータ入力：" + IntegerToString(ORDER_MODIFY_INTERVAL_SECONDS));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (RE_ENTRY_DISABLE_MINUTES <= 0) {
        MessageBox("「再エントリー禁止時間(分)」はゼロより大きい秒数を指定してください。\n→パラメータ入力：" + IntegerToString(RE_ENTRY_DISABLE_MINUTES));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (ENTRY_WIDTH <= 0) {
        MessageBox("「逆指値注文価格幅」はゼロより大きい値を指定してください。\n→パラメータ入力：" + DoubleToString(ENTRY_WIDTH, 2));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (TAKE_PROFIT < 0) {
        MessageBox("「利確価格幅」はゼロ以上のを指定してください。\n→パラメータ入力：" + DoubleToString(TAKE_PROFIT, 2));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (STOP_LOSS < 0) {
        MessageBox("「損切価格幅」はゼロ以上の値を指定してください。\n→パラメータ入力：" + DoubleToString(STOP_LOSS, 2));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (Reason != REASON_CHARTCHANGE && Reason != REASON_PARAMETERS) {
        InitPanel();
    }
    else {
        UpdatePanel();
    }

    EventSetTimer(1);

    enable_entry_type = ENTRY_TYPE;
    currency_digits = AccountInfoString(ACCOUNT_CURRENCY) == "JPY" ? 0 : 2;

#ifdef __MQL4__
    is_testing = IsTesting() || IsOptimization();
#else
    is_testing = (bool)MQLInfoInteger(MQL_TESTER) || (bool)MQLInfoInteger(MQL_FORWARD) || (bool)MQLInfoInteger(MQL_OPTIMIZATION) || (bool)MQLInfoInteger(MQL_VISUAL_MODE);
#endif 

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();

    if (reason != REASON_CHARTCHANGE && reason != REASON_PARAMETERS && reason != REASON_ACCOUNT) {
        DeleteOrderAll();
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
void GetBuyEntry(double ask, double point, int digits, double& buy_entry, double& sl, double& tp) {
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        buy_entry = NormalizeDouble(ask + ENTRY_WIDTH * point, digits);
        sl = NormalizeDouble(buy_entry - STOP_LOSS * point, digits);
        tp = NormalizeDouble(buy_entry + TAKE_PROFIT * point, digits);
    }
    else {
        buy_entry = NormalizeDouble(ask * (1.00 + 0.01 * ENTRY_WIDTH), digits);
        sl = NormalizeDouble(buy_entry * (1.00 - 0.01 * STOP_LOSS), digits);
        tp = NormalizeDouble(buy_entry * (1.00 + 0.01 * TAKE_PROFIT), digits);
    }
    if (sl < 0.5 * ask) {
        sl = NormalizeDouble(0.5 * ask, digits);
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
    else {
        sell_entry = NormalizeDouble(bid * (1.00 - 0.01 * ENTRY_WIDTH), digits);
        sl = NormalizeDouble(sell_entry * (1.00 + 0.01 * STOP_LOSS), digits);
        tp = NormalizeDouble(sell_entry * (1.00 - 0.01 * TAKE_PROFIT), digits);
    }
    if (tp < 0.5 * bid) {
        tp = NormalizeDouble(0.5 * bid, digits);
    }
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
}

//+------------------------------------------------------------------+
//| 価格情報の状態文字列を返す                                       |
//+------------------------------------------------------------------+
string GetPriceStatus(double price_width, double price, double point) {
    string price_status = "";
    double price_point = price_width / point;
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        price_status = StringFormat("%+.0fポイント", price_point);
    }
    else {
        double price_percentage = 100 * price_width / price;
        price_status = StringFormat("%+.0fポイント / %+4.2f％", price_point, price_percentage);
    }
    return price_status;
}

//+------------------------------------------------------------------+
//| トレードできるか判定する                                         |
//+------------------------------------------------------------------+
ulong diff_microsecond;
bool IsEnabledTrade() {
    if (last_order_modified == 0) {
        last_order_modified = TimeCurrent();
    }

    if (is_testing) {
        return true;
    }

    datetime now = TimeCurrent();
    static datetime prev_datetime = 0;
    if (prev_datetime == 0) {
        prev_datetime = now;
    }
    datetime current_datetime = now;

    MqlDateTime tm = {};
#ifdef __MQL5__
    TimeToStruct(TimeTradeServer(), tm);
    if (tm.day_of_week < 1 || 5 < tm.day_of_week) {
        return false;
    }
#endif

    TimeToStruct(now, tm);
    int T = SecondsOfWeek(tm.day_of_week, tm.hour, tm.min, tm.sec);
    if (0 < tm.day_of_week < 1 && 5 < tm.day_of_week < 6) {
        return true;
    }

    bool enable_trade = current_datetime > prev_datetime;

    prev_datetime = current_datetime;

    return enable_trade;
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

//+------------------------------------------------------------------+
//| 中断時間の表示文字列を返す                                       |
//+------------------------------------------------------------------+
string GetSuspended() {
    if (CLOSE_TIME == OPEN_TIME) {
        return "24時間監視";
    }
    else {
        return StringFormat("中断時間 %s～%s", CLOSE_TIME, OPEN_TIME);
    }
}
