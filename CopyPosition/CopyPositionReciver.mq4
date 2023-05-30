//+------------------------------------------------------------------+
//|                                            CopyPositionSeder.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.00"
#property strict

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

#import "kernel32.dll"
ulong GetTickCount64();
#import

int     UPDATE_INTERVAL;      // ポジションコピーを行うインターバル(ミリ秒)
string  SYMBOL_APPEND_SUFFIX; // ポジションコピー時にシンボル名に追加するサフィックス
int     RETRY_INTERVAL;       // 発注時・注文修正時のリトライインターバル時間(ミリ秒)
int     RETRY_COUNT_MAX;      // 発注時・注文修正時の最大リトライ回数
int     SLIPPAGE;             // スリッページ(ポイント)

//+------------------------------------------------------------------+
//| ポジション操作を表す列挙値です                                   |
//+------------------------------------------------------------------+
enum ENUM_POSITION_OPERATION {
    POSITION_ADD = +1,
    POSITION_REMOVE = -1,
    POSITION_MODIFY = 0,
};

#define MAX_POSITION 1024

//+------------------------------------------------------------------+
//| ポジション全体を表す構造体です                                   |
//+------------------------------------------------------------------+
struct POSITION_LIST {
    int Change[MAX_POSITION];
    int MagicNumber[MAX_POSITION];
    int EntryType[MAX_POSITION];
    string SymbolValue[MAX_POSITION];
    int Tickets[MAX_POSITION];
    double Lots[MAX_POSITION];
    double StopLoss[MAX_POSITION];
    double TakeProfit[MAX_POSITION];

    void Clear() {
        ArrayFill(Change, 0, MAX_POSITION, 0);
        ArrayFill(MagicNumber, 0, MAX_POSITION, 0);
        ArrayFill(EntryType, 0, MAX_POSITION, 0);
        ArrayFill(Tickets, 0, MAX_POSITION, 0);
        for (int i = 0; i < MAX_POSITION; ++i) {
            SymbolValue[i] = "";
        }
        ArrayFill(Lots, 0, MAX_POSITION, 0.0);
        ArrayFill(StopLoss, 0, MAX_POSITION, 0.0);
        ArrayFill(TakeProfit, 0, MAX_POSITION, 0.0);
    }
};

// ポジション全体を表す構造体配列の添字で
// 0と1のどちらが現在を表すか示すフラグです
bool CurrentIndex;

// 通信用タブ区切りファイルに書き出す
// ポジション全体の差分を表す構造体です
POSITION_LIST Output;

// コピーしたいマジックナンバーの配列です
int MagicNumbers[];

// コピーポジション連携用タブ区切りファイルの個数です
int CommunacationFileCount = 0;

// コピーポジション連携用タブ区切りファイルのプレフィックスの配列です
string CommunacationPathPattern[];

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
    
    // 添字0を現在のポジション状態にします
    CurrentIndex = (bool)0;

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
        return false;
    }
    UPDATE_INTERVAL = (int)StringToInteger(update_interval);

    // ポジションコピー時にシンボル名に追加するサフィックス
    GetPrivateProfileStringW("Reciever", "SYMBOL_APPEND_SUFFIX", "", SYMBOL_APPEND_SUFFIX, 1024, inifile_path);

    int i = 0;
    while (true) {
        string section_name = StringFormat("Sender%03d", i + 1);
        string broker = "";
        if (GetPrivateProfileStringW(section_name, "BROKER", NONE, broker, 1024, inifile_path) == 0 || broker == NONE) {
            break;
        }

        string account = "";
        if (GetPrivateProfileStringW(section_name, "ACCOUNT", NONE, account, 1024, inifile_path) == 0 || account == NONE) {
            break;
        }

        string sender_name = GetBrokerAccount(broker, StringToInteger(account));
        ArrayResize(CommunacationPathPattern, i + 1);
        CommunacationPathPattern[i] = StringFormat("CopyPositionEA\\%s\\%s-*.tsv", reciever_name, sender_name);
        CommunacationFileCount = ++i;
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
    for (int i = 0; i < CommunacationFileCount; ++i) {
        LoadPosition(CommunacationPathPattern[i]);
    }
}

//+------------------------------------------------------------------+
//| ポジション全体の差分をタブ区切りファイルから読みだします         |
//+------------------------------------------------------------------+
void LoadPosition(string path_prefix)
{
    string path;
    long search_handle = FileFindFirst(path_prefix, path, FILE_COMMON);
    if (search_handle == INVALID_HANDLE) {
        return;
    }

    do {
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
            string symbol = field[3];
            // 4列目：コピー元チケット番号
            int ticket = (int)StringToInteger(field[4]);
            // 5列目：ポジションサイズ
            double lots = StringToDouble(field[5]);
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
    } while (FileFindNext(search_handle, path));

    FileFindClose(search_handle);
}

//+------------------------------------------------------------------+
//| コピーするポジションを発注します                                 |
//+------------------------------------------------------------------+
void Entry(int magic_number, int entry_type, string symbol, int ticket, double lots, double stoploss, double takrprofit)
{
    int cmd = 0;
    switch (OrderType()) {
    case +1:
        cmd = OP_BUY;
        break;
    case +2:
        cmd = OP_BUYLIMIT;
        break;
    case +3:
        cmd = OP_BUYSTOP;
        break;
    case -1:
        cmd = OP_SELL;
        break;
    case -2:
        cmd = OP_SELLLIMIT;
        break;
    case -3:
        cmd = OP_SELLSTOP;
        break;
    default:
        return;
    }

    lots = NormalizeDouble(lots, 2);

    double price = 0;
    color arrow = clrNONE;
    if (cmd > 0) {
        price = Ask;
        arrow = clrBlue;
    } else {
        price = Bid;
        arrow = clrRed;
    }

    string comment = StringFormat("#%d", ticket);
    for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
        int order_ticket = OrderSend(Symbol(), cmd, lots, price, SLIPPAGE, 0, 0, comment, magic_number, 0, arrow);
        if (order_ticket == -1) {
            Sleep(RETRY_INTERVAL << times);
        } else {
            return;
        }
    }

    string error = StringFormat("OrderSend() Failed %d", GetLastError());
    Print(error);
    Alert(error);
}

//+------------------------------------------------------------------+
//| コピーしたポジションを決済します                                 |
//+------------------------------------------------------------------+
void Exit(int magic_number, int entry_type, string symbol, int ticket, double lots, double stoploss, double takrprofit)
{
    lots = NormalizeDouble(lots, 2);

    double price = 0;
    color arrow = clrNONE;
    if (lots > 0) {
        price = Bid;
        arrow = clrBlue;
    } else {
        price = Ask;
        arrow = clrRed;
    }

    string comment = StringFormat("#%d", ticket);
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderComment() != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = OrderClose(ticket, lots, price, SLIPPAGE, arrow);
            if (!result) {
                Sleep(RETRY_INTERVAL << times);
            } else {
                return;
            }
        }
        string error = StringFormat("OrderClose() Failed %d", GetLastError());
        Print(error);
        Alert(error);
    }
}

//+------------------------------------------------------------------+
//| コピーしたポジションを修正します                                 |
//+------------------------------------------------------------------+
void Modify(int magic_number, int entry_type, string symbol, int ticket, double lots, double stoploss, double takrprofit)
{
    lots = NormalizeDouble(lots, 2);

    double price = 0;
    if (lots > 0) {
        price = Bid;
    } else {
        price = Ask;
    }

    string comment = StringFormat("#%d", ticket);
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderComment() != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = OrderModify(ticket, price, stoploss, takrprofit, 0);
            if (!result) {
                Sleep(RETRY_INTERVAL << times);
            } else {
                return;
            }
        }
        string error = StringFormat("OrderModify() Failed %d", GetLastError());
        Print(error);
        Alert(error);
    }
}
