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
int trailing_count;

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

    if (ORDER_MODIFY_INTERVAL_SECONDS <= 0) {
        MessageBox("「逆指値更新間隔(秒)」はゼロより大きい秒数を指定してください。\n→パラメータ入力：" + IntegerToString(ORDER_MODIFY_INTERVAL_SECONDS));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (TRAILING_STOP_INTERVAL_SECONDS <= 0) {
        MessageBox("「トレーリングストップ更新間隔(秒)」はゼロより大きい秒数を指定してください。\n→パラメータ入力：" + IntegerToString(TRAILING_STOP_INTERVAL_SECONDS));
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

    if (TRAILING_TYPE != TRAILING_TYPE_WITHOUT_TP && TAKE_PROFIT <= 0) {
        MessageBox("「利確価格幅」はゼロより大きい値を指定してください。\n→パラメータ入力：" + DoubleToString(TAKE_PROFIT, 2));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (STOP_LOSS <= 0) {
        MessageBox("「損切価格幅」はゼロより大きい値を指定してください。\n→パラメータ入力：" + DoubleToString(STOP_LOSS, 2));
        return INIT_PARAMETERS_INCORRECT;
    }

    if (TRAILING_STOP_ENABLE) {
        if (TRAILING_STOP_LOSS <= 0) {
            MessageBox("「トレーリングストップ損切価格幅」はゼロより大きい値を指定してください。\n→パラメータ入力：" + DoubleToString(TRAILING_STOP_LOSS, 2));
            return INIT_PARAMETERS_INCORRECT;
        }
        if (TRAILING_TYPE != TRAILING_TYPE_WITHOUT_TP && TRAILING_TAKE_PROFIT <= 0) {
            MessageBox("「トレーリングストップ利確価格幅」はゼロより大きい値を指定してください。\n→パラメータ入力：" + DoubleToString(TRAILING_TAKE_PROFIT, 2));
            return INIT_PARAMETERS_INCORRECT;
        }
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
    currency_digits = AccountInfoString(ACCOUNT_CURRENCY) == "JPY" ? 0 : 2;

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
        tp = NormalizeDouble(buy_entry * (1.00 + 0.01 * TAKE_PROFIT), digits);
    }
    else {
        buy_entry = NormalizeDouble(ask + ENTRY_WIDTH * stddev, digits);
        sl = NormalizeDouble(buy_entry - STOP_LOSS * stddev, digits);
        tp = NormalizeDouble(buy_entry + TAKE_PROFIT * stddev, digits);
    }
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0 || TRAILING_TYPE == TRAILING_TYPE_WITHOUT_TP) {
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
        tp = NormalizeDouble(sell_entry * (1.00 - 0.01 * TAKE_PROFIT), digits);
    }
    else {
        sell_entry = NormalizeDouble(bid - ENTRY_WIDTH * stddev, digits);
        sl = NormalizeDouble(sell_entry + STOP_LOSS * stddev, digits);
        tp = NormalizeDouble(sell_entry - TAKE_PROFIT * stddev, digits);
    }
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0 || TRAILING_TYPE == TRAILING_TYPE_WITHOUT_TP) {
        tp = 0;
    }
}

//+------------------------------------------------------------------+
//| 買いポジションのトレーリングストップを実行するか判断する         |
//+------------------------------------------------------------------+
bool DoTrailingStopBuyPosition(double entry_price, double current_price, double point, int digits, double& sl, double& tp) {
    if (!TRAILING_STOP_ENABLE) {
        return false;
    }

    double profit_price = current_price - entry_price;
    int next_trailing_count = trailing_count + 1;
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        double profit_point = profit_price / point;
        if (profit_point < next_trailing_count * TRAILING_STOP_LOSS) {
            return false;
        }
        sl = NormalizeDouble(current_price - TRAILING_STOP_LOSS * point, digits);
        tp = NormalizeDouble(current_price + TRAILING_TAKE_PROFIT * point, digits);
    }
    else if (PRICE_TYPE == PRICE_TYPE_PERCENT) {
        double profit_percentage = 100 * profit_price / entry_price;
        if (profit_percentage < next_trailing_count * TRAILING_STOP_LOSS) {
            return false;
        }
        sl = NormalizeDouble(current_price - (0.01 * TRAILING_STOP_LOSS * entry_price), digits);
        tp = NormalizeDouble(current_price + (0.01 * TRAILING_TAKE_PROFIT * entry_price), digits);
    }
    else {
        if (stddev == 0) {
            return false;
        }
        double profit_deviation = profit_price / stddev;
        if (profit_deviation < next_trailing_count * TRAILING_STOP_LOSS) {
            return false;
        }
        sl = NormalizeDouble(current_price - TRAILING_STOP_LOSS * stddev, digits);
        tp = NormalizeDouble(current_price + TRAILING_TAKE_PROFIT * stddev, digits);
    }

    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0 || TRAILING_TYPE == TRAILING_TYPE_WITHOUT_TP) {
        tp = 0;
    }

    return true;
}

//+------------------------------------------------------------------+
//| 売りポジションのトレーリングストップを実行するか判断する         |
//+------------------------------------------------------------------+
bool DoTrailingStopSellPosition(double entry_price, double current_price, double point, int digits, double& sl, double& tp) {
    if (!TRAILING_STOP_ENABLE) {
        return false;
    }

    double profit_price = entry_price - current_price;
    int next_trailing_count = trailing_count + 1;
    if (PRICE_TYPE == PRICE_TYPE_POINT) {
        double profit_point = profit_price / point;
        if (profit_point < next_trailing_count * TRAILING_STOP_LOSS) {
            return false;
        }
        sl = NormalizeDouble(current_price + TRAILING_STOP_LOSS * point, digits);
        tp = NormalizeDouble(current_price - TRAILING_TAKE_PROFIT * point, digits);
    }
    else if (PRICE_TYPE == PRICE_TYPE_PERCENT) {
        double profit_percentage = 100 * profit_price / entry_price;
        if (profit_percentage < next_trailing_count * TRAILING_STOP_LOSS) {
            return false;
        }
        sl = NormalizeDouble(current_price + (0.01 * TRAILING_STOP_LOSS * entry_price), digits);
        tp = NormalizeDouble(current_price - (0.01 * TRAILING_TAKE_PROFIT * entry_price), digits);
    }
    else {
        if (stddev == 0) {
            return false;
        }
        double profit_deviation = profit_price / stddev;
        if (profit_deviation < next_trailing_count * TRAILING_STOP_LOSS) {
            return false;
        }
        sl = NormalizeDouble(current_price + TRAILING_STOP_LOSS * stddev, digits);
        tp = NormalizeDouble(current_price - TRAILING_TAKE_PROFIT * stddev, digits);
    }

    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0 || TRAILING_TYPE == TRAILING_TYPE_WITHOUT_TP) {
        tp = 0;
    }

    return true;
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
    else if (PRICE_TYPE == PRICE_TYPE_PERCENT) {
        double price_percentage = 100 * price_width / price;
        price_status = StringFormat("%+.0fポイント / %+4.2f％", price_point, price_percentage);
    }
    else {
        if (stddev == 0) {
            price_status = StringFormat("%+.0fポイント / %+4.2fσ", price_point, 0);
        }
        else {
            double price_deviation = price_width / stddev;
            price_status = StringFormat("%+.0fポイント / %+4.2fσ", price_point, price_deviation);
        }
    }
    return price_status;
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
