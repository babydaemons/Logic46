//+------------------------------------------------------------------+
//|                                          CopyPositionReciver.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.00"
#property strict

#include "WindowsAPI.mqh"
#include "ErrorDescriptionMT4.mqh"

int     UPDATE_INTERVAL;      // ポジションコピーを行うインターバル(ミリ秒)
string  SYMBOL_APPEND_SUFFIX; // ポジションコピー時にシンボル名に追加するサフィックス
int     RETRY_INTERVAL_INIT;  // 発注時・ポジション修正時のリトライ時間の初期値(ミリ秒)
int     RETRY_COUNT_MAX;      // 発注時・ポジション修正時のリトライ最大回数
int     SLIPPAGE;             // スリッページ(ポイント)

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
    uint appdata_dir_length = GetEnvironmentVariable("appdata", appdata_dir, 1024);
    if (appdata_dir_length == 0) {
        printf("※エラー: 環境変数 appdata の値の取得に失敗しました");
        return false;
    } 
    string common_data_dir = appdata_dir + "\\MetaQuotes\\Terminal\\Common\\Files";

    // レシーバー側設定のINIファイルパスをログ出力します
    string inifile_name = StringFormat("CopyPositionEA\\Reciever-%s.ini", reciever_name);
    string inifile_path = StringFormat("%s\\%s", common_data_dir, inifile_name);
    printf("●レシーバー側設定INIファイルは「%s」です。", inifile_path);

    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        printf("※エラー: レシーバー側設定INIファイル「%s」が見つかりません。", inifile_path);
        return false;
    }

    // ポジションコピーを行うインターバル(ミリ秒)
    string update_interval = "";
    if (GetPrivateProfileString("Reciever", "UPDATE_INTERVAL", NONE, update_interval, 1024, inifile_path) == 0 || update_interval == NONE) {
        printf("※エラー: セクション[Reciever]のキー\"UPDATE_INTERVAL\"が見つかりません。");
        return false;
    }
    UPDATE_INTERVAL = (int)StringToInteger(update_interval);

    string retry_interval_init = "";
    if (GetPrivateProfileString("Reciever", "RETRY_INTERVAL_INIT", NONE, retry_interval_init, 1024, inifile_path) == 0 || retry_interval_init == NONE) {
        printf("※エラー: セクション[Reciever]のキー\"RETRY_INTERVAL_INIT\"が見つかりません。");
        return false;
    }
    RETRY_INTERVAL_INIT = (int)StringToInteger(retry_interval_init);

    string retry_count_max = "";
    if (GetPrivateProfileString("Reciever", "RETRY_COUNT_MAX", NONE, retry_count_max, 1024, inifile_path) == 0 || retry_count_max == NONE) {
        printf("※エラー: セクション[Reciever]のキー\"RETRY_COUNT_MAX\"が見つかりません。");
        return false;
    }
    RETRY_COUNT_MAX = (int)StringToInteger(retry_count_max);

    // ポジションコピー時にシンボル名に追加するサフィックス
    string symbol_append_suffix = "";
    GetPrivateProfileString("Reciever", "SYMBOL_APPEND_SUFFIX", NONE, symbol_append_suffix, 1024, inifile_path);
    SYMBOL_APPEND_SUFFIX = symbol_append_suffix == NONE ? "" : symbol_append_suffix;

    // センダー側の設定個数を取得
    string sender_count = "";
    if (GetPrivateProfileString("Reciever", "SENDER_COUNT", NONE, sender_count, 1024, inifile_path) == 0 || sender_count == NONE) {
        printf("※エラー: セクション[Sender]のキー\"RECIEVER_COUNT\"が見つかりません。");
        return false;
    }
    CommunacationDirCount = (int)StringToInteger(sender_count);
    printf("●%d個のレシーバー側にポジションをコピーします。", CommunacationDirCount);

    for (int i = 0; i < CommunacationDirCount; ++i) {
        string section_name = StringFormat("Sender%03d", i + 1);
        string sender_broker = "";
        if (GetPrivateProfileString(section_name, "BROKER", NONE, sender_broker, 1024, inifile_path) == 0 || sender_broker == NONE) {
            printf("※エラー: セクション[%s]のキー\"BROKER\"が見つかりません。", section_name);
            return false;
        }

        string sender_account = "";
        if (GetPrivateProfileString(section_name, "ACCOUNT", NONE, sender_account, 1024, inifile_path) == 0 || sender_account == NONE) {
            printf("※エラー: セクション[%s]のキー\"ACCOUNT\"が見つかりません。", section_name);
            return false;
        }

        // ポジションコピー時のロット数の係数
        string lots_multiply = "";
        GetPrivateProfileString(section_name, "LOTS_MULTIPLY", NONE, lots_multiply, 1024, inifile_path);
        ArrayResize(LotsMultiply, i + 1);
        LotsMultiply[i] = lots_multiply == NONE ? 1.0 : StringToDouble(lots_multiply);

        string sender_name = GetBrokerAccount(sender_broker, StringToInteger(sender_account));
        ArrayResize(CommunacationPathDir, i + 1);
        CommunacationPathDir[i] = StringFormat("CopyPositionEA\\%s\\%s\\", sender_name, reciever_name);
        FolderCreate(CommunacationPathDir[i], true);

        printf("[%03d]センダー側の証券会社は「%s」です。", i + 1, sender_broker);
        printf("[%03d]センダー側の口座番号は「%s」です。", i + 1, sender_account);
        printf("[%03d]センダー側からのポジションコピー時のロット係数は「%.3f」です。", i + 1, LotsMultiply[i]);
    }

    printf("●コピーポジションの受信監視を開始します。");
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
            // 3列目：エントリー価格
            double entry_price = StringToDouble(field[3]);
            // 4列目：シンボル名
            string symbol = field[4] + SYMBOL_APPEND_SUFFIX;
            // 5列目：コピー元チケット番号
            int ticket = (int)StringToInteger(field[5]);
            // 6列目：ポジションサイズ
            double lots = StringToDouble(field[6]) * lots_multiply;
            // 7列目：ストップロス
            double stoploss = StringToDouble(field[7]);
            // 8列目：テイクプロフィット
            double takeprofit = StringToDouble(field[8]);

            if (change == +1) {
                Entry(magic_number, entry_type, entry_price, symbol, ticket, lots, stoploss, takeprofit);
            }
            else if (change == -1) {
                Exit(magic_number, entry_type, entry_price, symbol, ticket, lots, stoploss, takeprofit);
            }
            else {
                Modify(magic_number, entry_type, entry_price, symbol, ticket, lots, stoploss, takeprofit);
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
void Entry(int magic_number, int entry_type, double entry_price, string symbol, int ticket, double lots, double stoploss, double takeprofit)
{
    lots = NormalizeDouble(lots, 2);

    double price = 0;
    color arrow = clrNONE;
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        arrow = clrBlue;
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
        arrow = clrRed;
    }

    int cmd = 0;
    switch (entry_type) {
    case +1:
        cmd = OP_BUY;
        break;
    case +2:
        cmd = OP_BUYLIMIT;
        price = entry_price;
        break;
    case +3:
        cmd = OP_BUYSTOP;
        price = entry_price;
        break;
    case -1:
        cmd = OP_SELL;
        break;
    case -2:
        cmd = OP_SELLLIMIT;
        price = entry_price;
        break;
    case -3:
        cmd = OP_SELLSTOP;
        price = entry_price;
        break;
    default:
        return;
    }

    string comment = StringFormat("#%d", ticket);
    string error_message = "";
    for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
        int order_ticket = OrderSend(symbol, cmd, lots, price, SLIPPAGE, 0, 0, comment, magic_number, 0, arrow);
        if (order_ticket == -1) {
            error_message = ErrorDescription();
            printf("※エラー: %s", error_message);
            Sleep(RETRY_INTERVAL_INIT << times);
        } else {
            return;
        }
    }

    Alert(error_message);
}

//+------------------------------------------------------------------+
//| コピーしたポジションを決済します                                 |
//+------------------------------------------------------------------+
void Exit(int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double lots, double stoploss, double takeprofit)
{
    lots = NormalizeDouble(lots, 2);

    double price = 0;
    color arrow = clrNONE;
    if (lots > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
        arrow = clrBlue;
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        arrow = clrRed;
    }

    string comment = StringFormat("#%d", sender_ticket);
    string error_message = "";
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderComment() != comment) {
            continue;
        }
        int ticket = OrderTicket();
        int order_type = OrderType();
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = (order_type == OP_BUY || order_type == OP_SELL) ?
                            OrderClose(ticket, lots, price, SLIPPAGE, arrow) :
                            OrderDelete(ticket, arrow);
            if (!result) {
            error_message = ErrorDescription();
            printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }

        Alert(error_message);
        return;
    }
}

//+------------------------------------------------------------------+
//| コピーしたポジションを修正します                                 |
//+------------------------------------------------------------------+
void Modify(int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double lots, double stoploss, double takeprofit)
{
    lots = NormalizeDouble(lots, 2);

    string comment = StringFormat("#%d", sender_ticket);
    string error_message = "";
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderComment() != comment) {
            continue;
        }
        int ticket = OrderTicket();
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = OrderModify(ticket, entry_price, stoploss, takeprofit, 0);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }

        Alert(error_message);
        return;
    }
}
