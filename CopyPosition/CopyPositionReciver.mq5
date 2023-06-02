//+------------------------------------------------------------------+
//|                                          CopyPositionReciver.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

#import "kernel32.dll"
uint GetEnvironmentVariableW(
    string name,
    string& returnValue,
    uint bufferSize
);
#import

#import "kernel32.dll"
uint GetPrivateProfileStringW(
    string sectionName,
    string keyName,
    string defaultValue,
    string& returnValue,
    uint bufferSize,
    string iniFilePath);
#import

#include "ErrorDescriptionMT5.mqh"

int     UPDATE_INTERVAL;      // ポジションコピーを行うインターバル(ミリ秒)
string  SYMBOL_APPEND_SUFFIX; // ポジションコピー時にシンボル名に追加するサフィックス
int     RETRY_INTERVAL_INIT;  // 発注時・ポジション修正時のリトライ時間の初期値(ミリ秒)
int     RETRY_COUNT_MAX;      // 発注時・ポジション修正時のリトライ最大回数
int     SLIPPAGE;             // スリッページ(ポイント)

CTrade Trader;

//+------------------------------------------------------------------+
//| ポジション操作を表す列挙値です                                   |
//+------------------------------------------------------------------+
enum ENUM_POSITION_OPERATION {
    POSITION_ADD = +1,
    POSITION_REMOVE = -1,
    POSITION_MODIFY = 0,
};

// コピーしたいマジックナンバーの配列です
int MagicNumbers[];

// コピーポジション連携用タブ区切りファイルの個数です
int CommunacationDirCount = 0;

// コピーポジション連携用タブ区切りファイルのプレフィックスの配列です
string CommunacationPathDir[];

// ポジションコピー時のロット数の係数の配列です
double LotsMultiply[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // INIファイルより設定値を初期化します
    if (!Initialize()) {
        return INIT_FAILED;
    }

    // パラメータ UPDATE_INTERVAL で指定されたミリ秒の周期で
    // ポジションコピーを行います
    EventSetMillisecondTimer(UPDATE_INTERVAL);
    
    printf("コピーポジションの受信監視を開始しました。");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| INIファイルより設定値を初期化します                              |
//+------------------------------------------------------------------+
bool Initialize()
{
    // レシーバー側を識別する証券会社名+口座番号を取得します
    string reciever_name = GetBrokerAccount(AccountInfoString(ACCOUNT_COMPANY), AccountInfoInteger(ACCOUNT_LOGIN));

    // Commonデータフォルダのパスを取得します
    string appdata_dir = "";
    uint appdata_dir_length = GetEnvironmentVariableW("appdata", appdata_dir, 1024);
    if (appdata_dir_length == 0) {
        printf("エラー: 環境変数 appdata の値の取得に失敗しました");
        return false;
    } 
    string common_data_dir = appdata_dir + "\\MetaQuotes\\Terminal\\Common\\Files";

    // レシーバー側設定のINIファイルパスをログ出力します
    string inifile_name = StringFormat("CopyPositionEA\\Reciever-%s.ini", reciever_name);
    string inifile_path = StringFormat("%s\\%s", common_data_dir, inifile_name);
    printf("レシーバー側設定INIファイルは「%s」です。", inifile_path);

    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        printf("エラー: レシーバー側設定INIファイル「%s」が見つかりません。", inifile_path);
        return false;
    }

    const string NONE = "<NONE>";

    // ポジションコピーを行うインターバル(ミリ秒)
    string update_interval = "";
    if (GetPrivateProfileStringW("Reciever", "UPDATE_INTERVAL", NONE, update_interval, 1024, inifile_path) == 0 || update_interval == NONE) {
        printf("エラー: セクション[Reciever]のキー\"UPDATE_INTERVAL\"が見つかりません。");
        return false;
    }
    UPDATE_INTERVAL = (int)StringToInteger(update_interval);

    string retry_interval_init = "";
    if (GetPrivateProfileStringW("Reciever", "RETRY_INTERVAL_INIT", NONE, retry_interval_init, 1024, inifile_path) == 0 || retry_interval_init == NONE) {
        printf("エラー: セクション[Reciever]のキー\"RETRY_INTERVAL_INIT\"が見つかりません。");
        return false;
    }
    RETRY_INTERVAL_INIT = (int)StringToInteger(retry_interval_init);

    string retry_count_max = "";
    if (GetPrivateProfileStringW("Reciever", "RETRY_COUNT_MAX", NONE, retry_count_max, 1024, inifile_path) == 0 || retry_count_max == NONE) {
        printf("エラー: セクション[Reciever]のキー\"RETRY_COUNT_MAX\"が見つかりません。");
        return false;
    }
    RETRY_COUNT_MAX = (int)StringToInteger(retry_count_max);

    // ポジションコピー時にシンボル名に追加するサフィックス
    string symbol_append_suffix = "";
    GetPrivateProfileStringW("Reciever", "SYMBOL_APPEND_SUFFIX", NONE, symbol_append_suffix, 1024, inifile_path);
    SYMBOL_APPEND_SUFFIX = symbol_append_suffix == NONE ? "" : symbol_append_suffix;

    int i = 0;
    while (true) {
        string section_name = StringFormat("Sender%03d", i + 1);
        string sender_broker = "";
        if (GetPrivateProfileStringW(section_name, "BROKER", NONE, sender_broker, 1024, inifile_path) == 0 || sender_broker == NONE) {
            break;
        }

        string sender_account = "";
        if (GetPrivateProfileStringW(section_name, "ACCOUNT", NONE, sender_account, 1024, inifile_path) == 0 || sender_account == NONE) {
            break;
        }

        // ポジションコピー時のロット数の係数
        string lots_multiply = "";
        GetPrivateProfileStringW(section_name, "LOTS_MULTIPLY", NONE, lots_multiply, 1024, inifile_path);
        ArrayResize(LotsMultiply, i + 1);
        LotsMultiply[i] = lots_multiply == NONE ? 1.0 : StringToDouble(lots_multiply);

        string sender_name = GetBrokerAccount(sender_broker, StringToInteger(sender_account));
        ArrayResize(CommunacationPathDir, i + 1);
        CommunacationPathDir[i] = StringFormat("CopyPositionEA\\%s\\%s\\", sender_name, reciever_name);
        FolderCreate(CommunacationPathDir[i], true);

        printf("[%03d]センダー側の証券会社は「%s」です。", i + 1, sender_broker);
        printf("[%03d]センダー側の口座番号は「%s」です。", i + 1, sender_account);
        printf("[%03d]センダー側からのポジションコピー時のロット係数は「%.3f」です。", i + 1, LotsMultiply[i]);

        CommunacationDirCount = ++i;
    }

    return true;
}

//+------------------------------------------------------------------+
//| 証券会社名と口座番号の組の文字列を返します                       |
//+------------------------------------------------------------------+
string GetBrokerAccount(string broker, long account)
{
    StringReplace(broker, " ", "_");
    StringReplace(broker, ",", "");
    StringReplace(broker, ".", "");
    return StringFormat("%s-%d", broker, account);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // タイマーを破棄します
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 気配値が更新されたタイミングで
    // ポジション全体の差分をタブ区切りファイルから読みだします
    LoadPositions();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // パラメータ UPDATE_INTERVAL で指定されたミリ秒の周期で
    // ポジション全体の差分をタブ区切りファイルから読みだします
    // OnTick()で十分なはずですが万が一のための保険です
    LoadPositions();
}

//+------------------------------------------------------------------+
//| ポジション全体の差分を全てのタブ区切りファイルから読みだします   |
//+------------------------------------------------------------------+
void LoadPositions()
{
    for (int i = 0; i < CommunacationDirCount; ++i) {
        LoadPosition(CommunacationPathDir[i], LotsMultiply[i]);
    }
}

//+------------------------------------------------------------------+
//| ポジション全体の差分をタブ区切りファイルから読みだします         |
//+------------------------------------------------------------------+
void LoadPosition(string communication_dir, double lots_multiply)
{
    string file_name;
    long search_handle = FileFindFirst(communication_dir + "*.tsv", file_name, FILE_COMMON);
    if (search_handle == INVALID_HANDLE) {
        return;
    }

    do {
        string path = communication_dir + file_name;
        int file = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_ACP);
        if (file == INVALID_HANDLE) {
            continue;
        }

        string line;
        while ((line = FileReadString(file)) != "") {
            string field[];
            StringSplit(line, '\t', field);
            // タブ区切りファイルの仕様
            // 0列目：+1: ポジション追加 ／ -1: ポジション削除 ／ 0: ポジション修正
            int change = (int)StringToInteger(field[0]);
            // 1列目：マジックナンバー
            int magic_number = (int)StringToInteger(field[1]);
            // 2列目：エントリー種別
            int entry_type = (int)StringToInteger(field[2]);
            // 3列目：シンボル名
            string symbol = field[3] + SYMBOL_APPEND_SUFFIX;
            // 4列目：コピー元チケット番号
            int ticket = (int)StringToInteger(field[4]);
            // 5列目：ポジションサイズ
            double lots = StringToDouble(field[5]) * lots_multiply;
            // 6列目：ストップロス
            double stoploss = StringToDouble(field[6]);
            // 7列目：テイクプロフィット
            double takeprofit = StringToDouble(field[7]);
            Sleep(10);

            if (change == +1) {
                Entry(magic_number, entry_type, symbol, ticket, lots, stoploss, takeprofit);
            }
            else if (change == -1) {
                Exit(magic_number, entry_type, symbol, ticket, lots, stoploss, takeprofit);
            }
            else {
                Modify(magic_number, entry_type, symbol, ticket, lots, stoploss, takeprofit);
            }
        }

        FileClose(file);
        FileDelete(path, FILE_COMMON);
    } while (FileFindNext(search_handle, file_name));

    FileFindClose(search_handle);
}

//+------------------------------------------------------------------+
//| コピーするポジションを発注します                                 |
//+------------------------------------------------------------------+
void Entry(int magic_number, int entry_type, string symbol, int ticket, double lots, double stoploss, double takeprofit)
{
    lots = NormalizeDouble(lots, 2);

    double price = 0;
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    }

    string comment = StringFormat("#%d", ticket);

    if (entry_type == +1) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.Buy(lots, symbol, price, stoploss, takeprofit);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -1) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.Sell(lots, symbol, price, stoploss, takeprofit);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == +2) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.BuyLimit(lots, price, symbol, stoploss, takeprofit);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -2) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.SellLimit(lots, price, symbol, stoploss, takeprofit);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == +3) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.BuyStop(lots, price, symbol, stoploss, takeprofit);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -3) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.SellStop(lots, price, symbol, stoploss, takeprofit);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }

    string error = StringFormat("OrderSend() Failed %d", GetLastError());
    Print(error);
    Alert(error);
}

//+------------------------------------------------------------------+
//| コピーしたポジションを決済します                                 |
//+------------------------------------------------------------------+
void Exit(int magic_number, int entry_type, string symbol, int sender_ticket, double lots, double stoploss, double takrprofit)
{
    lots = NormalizeDouble(lots, 2);

    double price = 0;
    if (lots > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }

    string comment = StringFormat("#%d", sender_ticket);
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.PositionClose(ticket, SLIPPAGE);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
        string error = StringFormat("Trader.PositionClose() Failed %d", GetLastError());
        Print(error);
        Alert(error);
        return;
    }
    for (int i = 0; i < OrdersTotal(); ++i) {
        ulong ticket = OrderGetTicket(i);
        if (OrderGetString(ORDER_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.OrderDelete(ticket);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
        string error = StringFormat("Trader.OrderDelete() Failed %d", GetLastError());
        Print(error);
        Alert(error);
        return;
    }
}

//+------------------------------------------------------------------+
//| コピーしたポジションを修正します                                 |
//+------------------------------------------------------------------+
void Modify(int magic_number, int entry_type, string symbol, int sender_ticket, double lots, double stoploss, double takeprofit)
{
    lots = NormalizeDouble(lots, 2);

    double price = 0;
    if (lots > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }

    string comment = StringFormat("#%d", sender_ticket);
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.PositionModify(ticket, stoploss, takeprofit);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
        string error = StringFormat("Trader.PositionModify() Failed %d", GetLastError());
        Print(error);
        Alert(error);
        return;
    }
    for (int i = 0; i < OrdersTotal(); ++i) {
        ulong ticket = OrderGetTicket(i);
        if (OrderGetString(ORDER_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.OrderModify(ticket, price, stoploss, takeprofit, ORDER_TIME_GTC, 0);
            if (!result) {
                printf("エラー: %s", ErrorDescription());
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
        string error = StringFormat("Trader.OrderDelete() Failed %d", GetLastError());
        Print(error);
        Alert(error);
        return;
    }
}
