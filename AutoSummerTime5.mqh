//+------------------------------------------------------------------+
//|                                                       Sample.mq4 |
//|                                     Copyright (c) 2015, りゅーき |
//|                                           https://autofx100.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2015, りゅーき"
#property link      "https://autofx100.com/"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| インポート                                                       |
//+------------------------------------------------------------------+
#import "kernel32.dll"
void GetSystemTimeAsFileTime(uchar &lpSystemTimeAsFileTime[]);
#import

#ifdef __USE_GETTIMEZONEINFOMATION
// Windows API
#import "kernel32.dll"
int GetTimeZoneInformation(int& tzinfo[]);
#import

// 自動GMT設定
enum E_TIME_ZONE_ID {
    TIME_ZONE_ID_UNKNOWN,   // 不明
    TIME_ZONE_ID_STANDARD,  // 標準
    TIME_ZONE_ID_DAYLIGHT,  // サマータイム
};
#endif

//+------------------------------------------------------------------+
//| 定数定義                                                         |
//+------------------------------------------------------------------+
enum E_TIMEZONE_TYPE {
    TIMEZONE_METATRADER,    // MT4/MT5(冬時間GMT+2/夏時間GMT+3)
    TIMEZONE_NEWYORK,       // アメリカ(ニューヨーク(アメリカ東部時間))
    TIMEZONE_LONDON,        // イギリス(ロンドン)
    TIMEZONE_TOKYO,         // 日本(サマータイム無し)
};

//+------------------------------------------------------------------+
//| EAパラメータ設定情報                                             |
//+------------------------------------------------------------------+
input E_TIMEZONE_TYPE TIMEZONE_TYPE = TIMEZONE_METATRADER;  // タイムゾーン種別

//+-------------------------------------------------------------------
//| 下記のページをクラス化した
//| https://autofx100.com/2015/01/24/%E3%82%B5%E3%83%9E%E3%83%BC%E3%82%BF%E3%82%A4%E3%83%A0%E3%82%92%E8%80%83%E6%85%AE%E3%81%97%E3%81%9F%E8%87%AA%E5%8B%95gmt%E8%A8%AD%E5%AE%9A%E9%96%A2%E6%95%B0/
//+-------------------------------------------------------------------
class AutoSummerTime {
public:
    static datetime TimeCurrent() {
        return ::TimeCurrent();
    }

    static datetime TimeLocal() {
        if (!IsTesting() && !IsOptimization()) {
            return ::TimeLocal();
        }

        return ::TimeCurrent() - 3600 * CalcTimeDifference();
    }

    //+------------------------------------------------------------------+
    //|【関数】ローカルタイムのGMTオフセット値を取得する                 |
    //|                                                                  |
    //|【引数】なし                                                      |
    //|                                                                  |
    //|【戻値】GMTオフセット値                                           |
    //|                                                                  |
    //|【備考】MT4を実行するPCのローカルタイムが日本に設定されている場合 |
    //|       「-9」を返す。                                             |
    //+------------------------------------------------------------------+
    static int GetLocalGmtOffset()
    {
#ifdef __USE_GETTIMEZONEINFOMATION
        int timeZoneInfo[43] = {};

        // MT4を実行するPCのタイムゾーン取得
        // GetTimeZoneInformation()関数はWindows API
        E_TIME_ZONE_ID tzType = (E_TIME_ZONE_ID)GetTimeZoneInformation(timeZoneInfo);
    
        // 日本の場合、gTimeZoneInfo[0] = -540 = -9 * 60
        int LocalGmtOffset = timeZoneInfo[0] / 60;
    
        // 現在サマータイム期間か？
        if (tzType == TIME_ZONE_ID_DAYLIGHT) {
            // gTimeZoneInfo[42]はサマータイムで変化する時間（通常=-60分）
            LocalGmtOffset += timeZoneInfo[42] / 60;
        }
    
        return LocalGmtOffset;
#else
        return -9;
#endif
    }

    //+------------------------------------------------------------------+
    //|【関数】FX業者のサーバーがサマータイム期間かどうかを判断する      |
    //|                                                                  |
    //|【引数】なし                                                      |
    //|                                                                  |
    //|【戻値】true ：夏時間                                             |
    //|        false：冬時間（標準時間）                                 |
    //|                                                                  |
    //|【備考】英国夏時間：3月最終日曜AM1:00～10月最終日曜AM1:00         |
    //|        米国夏時間：3月第2日曜AM2:00～11月第1日曜AM2:00           |
    //+------------------------------------------------------------------+
    static bool IsSummerTime()
    {
        int year  = Year();
        int month = Month();
        int day   = Day();
        int w     = DayOfWeek();
        int hour  = Hour();
        int startMonth;
        int startN;
        int startW;
        int startHour;
        int endMonth;
        int endN;
        int endW;
        int endHour;
        int w1;     // month月１日の曜日
        int dstDay; // 夏時間開始または終了日付
    
        if (TIMEZONE_TYPE == TIMEZONE_LONDON) {
            // 英国夏時間
            startMonth = 3;
            startW     = 0;
            startHour  = 1;
    
            int dayOfWeek = TimeDayOfWeek(StringToTime(StringFormat("%04d/%02d/%02d", year, startMonth, 1)));

            int changeDay = NthDayOfWeekToDay(5, 0, dayOfWeek);
    
            if(changeDay >= 1 && changeDay <= 31) {
                startN = 5;
            } else {
                startN = 4;
            }
    
            endMonth   = 10;
            endW       = 0;
            endHour    = 1; // 2時になった瞬間に1時に戻るので「1」
    
            dayOfWeek = TimeDayOfWeek(StringToTime(StringFormat("%04d/%02d/%02d", year, endMonth, 1)));
    
            changeDay = NthDayOfWeekToDay(5, 0, dayOfWeek);
    
            if(day >= 1 && changeDay <= 31) {
                endN = 5;
            } else {
                endN = 4;
            }
        } else if (TIMEZONE_TYPE == TIMEZONE_NEWYORK || TIMEZONE_TYPE == TIMEZONE_METATRADER) {
            // 米国夏時間
            if (year <= 2006) {
                startMonth = 4;
                startN     = 1;
                startW     = 0;
                startHour  = 2;
    
                endMonth   = 10;
                endW       = 0;
                endHour    = 1; // 2時になった瞬間に1時に戻るので「1」
    
                int dayOfWeek = TimeDayOfWeek(StringToTime(StringFormat("%04d/%02d/%02d", year, endMonth, 1)));
    
                int changeDay = NthDayOfWeekToDay(5, 0, dayOfWeek);
    
                if (changeDay >= 1 && changeDay <= 31) {
                    endN = 5;
                } else {
                    endN = 4;
                }
            } else {
                startMonth = 3;
                startN     = 2;
                startW     = 0;
                startHour  = 2;
    
                endMonth   = 11;
                endN       = 1;
                endW       = 0;
                endHour    = 1;
            }
        } else {
            // サマータイムなし
            return false;
        }

        // サマータイム期間外の月の場合
        if (month < startMonth || endMonth < month) {
            return false;
        }
    
        // month月１日の曜日w1を求める．day＝1 ならば w1＝w で，
        // dayが１日増えるごとにw1は１日前にずれるので，数学的には
        //   w1 = (w - (day - 1)) mod 7
        // しかしＣ言語の場合は被除数が負になるとまずいので，
        // 負にならないようにするための最小の７の倍数35を足して
        w1 = (w + 36 - day) % 7;
    
        if (month == startMonth) {
            // month月のstartN回目のstartW曜日の日付dstDayを求める．
            dstDay = NthDayOfWeekToDay(startN, startW, w1);
    
            // (day, hour) が (dstDay, startHour) より前ならば夏時間ではない
            if (day < dstDay || (day == dstDay && hour < startHour)) {
                return false;
            }
        }
    
        if (month == endMonth) {
            // month月のendN回目のendW曜日の日付dstDayを求める
            dstDay = NthDayOfWeekToDay(endN, endW, w1);
    
            // (day, hour) が (dstDay, startHour) 以後ならば夏時間ではない
            if (day > dstDay || (day == dstDay && hour >= endHour)) {
                return false;
            }
        }
    
        return true;
    }

    //+------------------------------------------------------------------+
    //|【関数】ある月のn回目のdow曜日の日付を求める                      |
    //|                                                                  |
    //|【引数】 IN OUT  引数名             説明                          |
    //|        --------------------------------------------------------- |
    //|         ○      n                  n週目（1～5）                 |
    //|         ○      dow                曜日（0：日曜，…，6：土曜）  |
    //|         ○      dow1               その月の1日の曜日             |
    //|                                                                  |
    //|【戻値】その月のn回目のdow曜日の日にち                            |
    //|                                                                  |
    //|【備考】2007/3：1日は木曜(4)で，第3金曜(5)は16日                  |
    //|        NthDayOfWeekToDay(3, 5, 4) = 16                           |
    //+------------------------------------------------------------------+
    static int NthDayOfWeekToDay(int n, int dow, int dow1)
    {
        // day ← (最初の dow 曜日の日付)－１
        if (dow < dow1) {
            dow += 7;
        }

        int day = dow - dow1;
        // day ← ｎ回目の dow 曜日の日付 (day + 7 * (n - 1) + 1)
        day += 7 * n - 6;
        return day;
    }

    //+------------------------------------------------------------------+
    //|【関数】ローカルタイムとサーバタイムの時差を計算する              |
    //|                                                                  |
    //|【引数】 IN OUT  引数名             説明                          |
    //|        --------------------------------------------------------- |
    //|         ○      aUseAutoGMT_Flg    自動GMT設定有効フラグ         |
    //|         ○      aSummerTimeType    サマータイム区分              |
    //|         ○      aSummerGMT_Offset  サマータイム時のGMTｵﾌｾｯﾄ値    |
    //|         ○      aWinterGMT_Offset  標準時のGMTｵﾌｾｯﾄ値            |
    //|         ○      aLocalGMT_Offset   ﾛｰｶﾙﾀｲﾑのGMTｵﾌｾｯﾄ値           |
    //|                                                                  |
    //|【戻値】ローカルタイムとサーバタイムの時差                        |
    //|                                                                  |
    //|【備考】なし                                                      |
    //+------------------------------------------------------------------+
    static int CalcTimeDifference()
    {
        static int LocalGmtOffset = INT_MIN;
        if (LocalGmtOffset == INT_MIN) {
            LocalGmtOffset = GetLocalGmtOffset();
        }

        int ServerGmtOffset = 0;
    
        if (IsTesting() || IsOptimization()) {
            bool isSummerTime = IsSummerTime();
            ServerGmtOffset = (isSummerTime) ? SummerGmtOffsets[TIMEZONE_TYPE] : WinterGmtOffsets[TIMEZONE_TYPE];
        } else {
            // ローカルタイムがサーバタイムより少し遅い場合、1時間不足する不具合が発生。
            // TimeLocal()                 = 2016.08.06 23:25:26
            // TimeCurrent()               = 2016.08.05 10:25:46
            // TimeLocal() - TimeCurrent() = 1970.01.01 12:59:40
            // 時差 = 12h ※本来は13h。TimeHour()で時間hだけを取得するため、59分40秒が切り捨て。結果として、1時間不足する。
            datetime diffTime = ::TimeLocal() - ::TimeCurrent();
    
            // それを解消するため、分が30以上なら1時間加算することで暫定対処とする。
            // 美しいロジックではないが、別案が思い浮かばないため。
            if (TimeMinute(diffTime) >= 30) {
                ServerGmtOffset = LocalGmtOffset - (TimeHour(diffTime) + 1);
            } else {
                ServerGmtOffset = LocalGmtOffset - TimeHour(diffTime);
            }
        }
    
        return LocalGmtOffset - ServerGmtOffset;
    }

    static datetime TimeSecondOfWeek(int wday, int hour, int minute, int second)
    {
        // 1970年1月4日が最初の日曜日
        return ((((wday * 24) + hour) * 60) + minute) * 60 + second + (datetime)(4 * 24 * 60 * 60);
    }

    static datetime GetUnixTime() {
        const long EPOCH_DIFFERENCE = 11644473600L; // 1601年1月1日から1970年1月1日までの秒数
        const long FILETIME_UNITS = 10000000L;      // 1秒あたりの100ナノ秒単位

        // FILETIMEは8バイトのデータ
        uchar fileTime[8];
        ArrayInitialize(fileTime, 0);

        // Windows APIを呼び出して現在時刻を取得
        GetSystemTimeAsFileTime(fileTime);

        // FILETIMEを64ビット整数に変換
        long low = (long)fileTime[0] | ((long)fileTime[1] << 8) | ((long)fileTime[2] << 16) | ((long)fileTime[3] << 24);
        long high = (long)fileTime[4] | ((long)fileTime[5] << 8) | ((long)fileTime[6] << 16) | ((long)fileTime[7] << 24);
        long quadPart = ((long)high << 32) | (long)low;

        // 100ナノ秒単位を秒単位に変換し、エポック差を引く
        return (datetime)(quadPart / FILETIME_UNITS - EPOCH_DIFFERENCE + (9L * 3600L));
    }

    static bool IsOptimization()
    {
        return((MQLInfoInteger(MQL_OPTIMIZATION) == 1) ? true : false);
    }
    
    static bool IsTesting()
    {
        return((MQLInfoInteger(MQL_TESTER) == 1) ? true : false);
    }

    static int Year()
    {
        MqlDateTime tm;
        ::TimeCurrent(tm);
        return(tm.year);
    }

    static int Month()
    {
        MqlDateTime tm;
        ::TimeCurrent(tm);
        return(tm.mon);
    }

    static int Day()
    {
        MqlDateTime tm;
        ::TimeCurrent(tm);
        return(tm.day);
    }

    static int DayOfWeek()
    {
        MqlDateTime tm;
        ::TimeCurrent(tm);
        return(tm.day_of_week);
    }

    static int Hour()
    {
        MqlDateTime tm;
        ::TimeCurrent(tm);
        return(tm.hour);
    }

    static int TimeDayOfWeek(datetime date)
    {
        MqlDateTime tm;
        TimeToStruct(date,tm);
        return(tm.day_of_week);
    }

    static int TimeHour(datetime date)
    {
        MqlDateTime tm;
        TimeToStruct(date,tm);
        return(tm.hour);
    }

    static int TimeMinute(datetime date)
    {
        MqlDateTime tm;
        TimeToStruct(date,tm);
        return(tm.min);
    }

    static int GetDiffHours()
    {
        if (IsSummerTime()) {
            return SummerGmtOffsets[TIMEZONE_TYPE] - SummerGmtOffsets[TIMEZONE_TOKYO];
        }
        else {
            return WinterGmtOffsets[TIMEZONE_TYPE] - WinterGmtOffsets[TIMEZONE_TOKYO];
        }
    }
public:
    static const int SummerGmtOffsets[];
    static const int WinterGmtOffsets[];
};

const int AutoSummerTime::SummerGmtOffsets[] = { +3, -4, +1, -9 };
const int AutoSummerTime::WinterGmtOffsets[] = { +2, -5, +0, -9 };

//+------------------------------------------------------------------+
