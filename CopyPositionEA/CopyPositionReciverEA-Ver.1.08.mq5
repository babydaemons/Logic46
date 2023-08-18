//+------------------------------------------------------------------+
//|                                          CopyPositionReciver.mq5 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include <Trade/Trade.mqh>
#include "WindowsAPI.mqh"
#include "ErrorDescriptionMT5.mqh"

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

// シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
struct SYMBOL_CONVERSION {
    int Count;
    string Before[];
    string After[];
};
SYMBOL_CONVERSION SymbolConversion[];

// コピーポジション連携用タブ区切りファイルの個数です
int CommunacationDirCount = 0;

// コピーポジション連携用タブ区切りファイルのプレフィックスの配列です
string CommunacationPathDir[];

// ポジションコピー時のロット数の係数の配列です
double LotsMultiply[];

// 設定INIファイルパスです
string inifile_path;

//+------------------------------------------------------------------+
//| エラー表示します                                                 |
//+------------------------------------------------------------------+
void ERROR(string error_message)
{
    MessageBox(error_message + "\n\n※INIファイルパス:\n" + inifile_path, "エラー", MB_ICONERROR);
    printf(error_message);
    printf("※INIファイルパス: " + inifile_path);
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
#ifdef __CHECK_EXPERT_NAME
    // EAの名前をチェック
    const string EXPART_NAME = "CopyPositionReciverEA-Ver.1.01";
    string ExpertName = MQLInfoString(MQL_PROGRAM_NAME);
    if (ExpertName != EXPART_NAME) {
        string error_message = StringFormat("EAのファイル名を「%s.ex5」からリネームしないで下さい。", EXPART_NAME);
        MessageBox(error_message, "エラー", MB_ICONSTOP | MB_OK);
        return INIT_FAILED;
    }
#endif // __CHECK_EXPERT_NAME

    // INIファイルより設定値を初期化します
    if (!Initialize()) {
        return INIT_FAILED;
    }

    // 100ミリ秒の周期でポジションコピーを行います
    if (!EventSetMillisecondTimer(100)) {
        string error_message = "ポジションコピーのインターバルタイマーを設定できませんでした。";
        MessageBox(error_message, "エラー", MB_ICONSTOP | MB_OK);
        return INIT_FAILED;
    }
    
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
        string error_message = "※エラー: 環境変数 appdata の値の取得に失敗しました";
        printf(error_message);
        MessageBox(error_message, "エラー", MB_ICONERROR);
        return false;
    } 
    string common_data_dir = appdata_dir + "\\MetaQuotes\\Terminal\\Common\\Files";

    // レシーバー側設定のINIファイルパスをログ出力します
    string inifile_name = StringFormat("CopyPositionEA\\Reciever-%s.ini", reciever_name);
    inifile_path = StringFormat("%s\\%s", common_data_dir, inifile_name);
    printf("●レシーバー側設定INIファイルは「%s」です。", inifile_path);
    printf("●レシーバー側証券会社名は「%s」です。", AccountInfoString(ACCOUNT_COMPANY));
    printf("●レシーバー側口座番号は「%d」です。", AccountInfoInteger(ACCOUNT_LOGIN));

    if (!FileIsExist(inifile_name, FILE_COMMON)) {
        string error_message = "※エラー: レシーバー側設定INIファイルが見つかりません。\n" +
                               StringFormat("●レシーバー側証券会社名は「%s」です。\n", AccountInfoString(ACCOUNT_COMPANY)) +
                               StringFormat("●レシーバー側口座番号は「%d」です。", AccountInfoInteger(ACCOUNT_LOGIN));
        ERROR(error_message);
        int file = FileOpen(inifile_name, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_UTF8);
        if (file == INVALID_HANDLE) {
            string error_message2 = "※エラー: INIファイルの作成に失敗しました\n" + inifile_path + "\n" + ErrorDescription();
            ERROR(error_message2);
            return false;
        }
        FileWrite(file, "[Reciever]");
        FileWrite(file, "; (エラーチェック用)レシーバー側証券会社名");
        FileWrite(file, "BROKER = " + AccountInfoString(ACCOUNT_COMPANY));
        FileWrite(file, "; (エラーチェック用)レシーバー側口座番号");
        FileWrite(file, "ACCOUNT = " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
        FileWrite(file, "; (オプション)ロット数の係数");
        FileWrite(file, ";LOTS_MULTIPLY = 0.1");
        FileWrite(file, "; (オプション)シンボル名の変換(\"変換前シンボル名|変換後シンボル名\"のカンマ区切り)");
        FileWrite(file, ";SYMBOL_CONVERSION = XAUUSD|GOLD,XAGUSD|SILVER");
        FileWrite(file, "; 発注時・ポジション修正時のリトライ時間の初期値(ミリ秒)");
        FileWrite(file, "RETRY_INTERVAL_INIT = 100");
        FileWrite(file, "; 発注時・ポジション修正時のリトライ最大回数");
        FileWrite(file, "RETRY_COUNT_MAX = 5");
        FileWrite(file, "; スリッページ");
        FileWrite(file, "SLIPPAGE = 10");
        FileWrite(file, "; センダー側の設定個数");
        FileWrite(file, "SENDER_COUNT = 1");
        FileWrite(file, "");
        FileWrite(file, "[Sender001]");
        FileWrite(file, "; (エラーチェック用)センダー側証券会社名");
        FileWrite(file, "BROKER = Titan FX Limited");
        FileWrite(file, "; (エラーチェック用)センダー側口座番号");
        FileWrite(file, "ACCOUNT = 12345678");
        FileWrite(file, "; (オプション)ロット数の係数");
        FileWrite(file, ";LOTS_MULTIPLY = 1.0");
        FileWrite(file, "; (オプション)シンボル名の変換(\"変換前シンボル名|変換後シンボル名\"のカンマ区切り)");
        FileWrite(file, ";SYMBOL_CONVERSION = GOLD|XAUUSD,SILVER|XAGUSD");
        FileClose(file);
        MessageBox("テンプレートのINIファイルを作成しました。\n" + inifile_path, "ご案内", MB_ICONINFORMATION);
        return false;
    }

    string reciever_broker = "";
    if (GetPrivateProfileString("Reciever", "BROKER", NONE, reciever_broker, 1024, inifile_path) == 0 || reciever_broker == NONE || AccountInfoString(ACCOUNT_COMPANY) != reciever_broker) {
        string error_message = "※レシーバー側証券会社名が一致しません: セクション[Reciever]のキー\"BROKER\"を見直してください。";
        ERROR(error_message);
        return false;
    }

    string reciever_account = "";
    if (GetPrivateProfileString("Reciever", "ACCOUNT", NONE, reciever_account, 1024, inifile_path) == 0 || reciever_account == NONE || AccountInfoInteger(ACCOUNT_LOGIN) != StringToInteger(reciever_account)) {
        string error_message = "※レシーバー側口座番号が一致しません: セクション[Reciever]のキー\"ACCOUNT\"を見直してください。";
        ERROR(error_message);
        return false;
    }

    string retry_interval_init = "";
    if (GetPrivateProfileString("Reciever", "RETRY_INTERVAL_INIT", NONE, retry_interval_init, 1024, inifile_path) == 0 || retry_interval_init == NONE) {
        string error_message = "※エラー: セクション[Reciever]のキー\"RETRY_INTERVAL_INIT\"が見つかりません。";
        ERROR(error_message);
        return false;
    }
    RETRY_INTERVAL_INIT = (int)StringToInteger(retry_interval_init);

    string retry_count_max = "";
    if (GetPrivateProfileString("Reciever", "RETRY_COUNT_MAX", NONE, retry_count_max, 1024, inifile_path) == 0 || retry_count_max == NONE) {
        string error_message = "※エラー: セクション[Reciever]のキー\"RETRY_COUNT_MAX\"が見つかりません。";
        ERROR(error_message);
        return false;
    }
    RETRY_COUNT_MAX = (int)StringToInteger(retry_count_max);

    // ポジションコピー時にシンボル名から削除するサフィックスを自動検索する
    int totalSymbols = SymbolsTotal(false);
    SYMBOL_APPEND_SUFFIX = "";
    for (int i = 0; i < totalSymbols; i++) {
        string symbolName = SymbolName(i, false);
        printf("[%02d/%02d]%s", i + 1, totalSymbols, symbolName);
        if (StringSubstr(symbolName, 0, 6) == "USDJPY") {
            SYMBOL_APPEND_SUFFIX = symbolName;
            StringReplace(SYMBOL_APPEND_SUFFIX, "USDJPY", "");
            printf("[%02d/%02d]コピーポジション送信時に削除するサフィックスは \'%s\' です。", i + 1, totalSymbols, SYMBOL_APPEND_SUFFIX);
            break;
        }
    }

    // センダー側の設定個数を取得
    string sender_count = "";
    if (GetPrivateProfileString("Reciever", "SENDER_COUNT", NONE, sender_count, 1024, inifile_path) == 0 || sender_count == NONE) {
        string error_message = "※エラー: セクション[Reciever]のキー\"SENDER_COUNT\"が見つかりません。";
        ERROR(error_message);
        return false;
    }
    CommunacationDirCount = (int)StringToInteger(sender_count);
    printf("●%d個のレシーバー側にポジションをコピーします。", CommunacationDirCount);

    ArrayResize(SymbolConversion, CommunacationDirCount);

    for (int i = 0; i < CommunacationDirCount; ++i) {
        string section_name = StringFormat("Sender%03d", i + 1);
        string sender_broker = "";
        if (GetPrivateProfileString(section_name, "BROKER", NONE, sender_broker, 1024, inifile_path) == 0 || sender_broker == NONE) {
            string error_message = StringFormat("※エラー: セクション[%s]のキー\"BROKER\"が見つかりません。", section_name);
            ERROR(error_message);
            return false;
        }

        string sender_account = "";
        if (GetPrivateProfileString(section_name, "ACCOUNT", NONE, sender_account, 1024, inifile_path) == 0 || sender_account == NONE) {
            string error_message = StringFormat("※エラー: セクション[%s]のキー\"ACCOUNT\"が見つかりません。", section_name);
            ERROR(error_message);
            return false;
        }

        // ポジションコピー時のロット数の係数
        string lots_multiply = "";
        GetPrivateProfileString(section_name, "LOTS_MULTIPLY", NONE, lots_multiply, 1024, inifile_path);
        ArrayResize(LotsMultiply, i + 1);
        LotsMultiply[i] = lots_multiply == NONE ? 1.0 : StringToDouble(lots_multiply);

        // シンボル名の変換("変換前シンボル名|変換後シンボル名"のカンマ区切り)
        string symbol_conversion_list = "";
        GetPrivateProfileString(section_name, "SYMBOL_CONVERSION", NONE, symbol_conversion_list, 1024, inifile_path);
        InitializeSymbolConversion(symbol_conversion_list, i);

        string sender_name = GetBrokerAccount(sender_broker, StringToInteger(sender_account));
        ArrayResize(CommunacationPathDir, i + 1);
        CommunacationPathDir[i] = StringFormat("CopyPositionEA\\%s\\%s", sender_name, reciever_name);

        // ポジションコピー連携ファイル用フォルダを作成する
        if (!FolderCreate(CommunacationPathDir[i], FILE_COMMON)) {
            string error_message = StringFormat("※エラー: コピー連携ファイルのフォルダーの作成に失敗しました: \"%s\"", CommunacationPathDir[i]);
            ERROR(error_message);
            return false;
        }

        printf("[%03d]センダー側の証券会社は「%s」です。", i + 1, sender_broker);
        printf("[%03d]センダー側の口座番号は「%s」です。", i + 1, sender_account);
        printf("[%03d]センダー側からのポジションコピー時のロット係数は「%.3f」です。", i + 1, LotsMultiply[i]);
        printf("[%03d]センダー側からのポジションコピーフォルダは「%s」です。", i + 1, CommunacationPathDir[i]);
    }

    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        string error_message = "※エラー: 自動売買が許可されていません。";
        ERROR(error_message);
        return false;
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
//| シンボル名の変換情報を初期化します                               |
//+------------------------------------------------------------------+
void InitializeSymbolConversion(string symbol_conversion_list, int k)
{
    if (symbol_conversion_list == NONE) {
        SymbolConversion[k].Count = 0;
        return;
    }

    string symbol_conversion[];
    SymbolConversion[k].Count = StringSplit(symbol_conversion_list, ',', symbol_conversion);
    ArrayResize(SymbolConversion[k].Before, SymbolConversion[k].Count);
    ArrayResize(SymbolConversion[k].After, SymbolConversion[k].Count);
    for (int i = 0; i < SymbolConversion[k].Count; ++i) {
        string conversion[];
        StringSplit(symbol_conversion[i], '|', conversion);
        SymbolConversion[k].Before[i] = conversion[0];
        SymbolConversion[k].After[i] = conversion[1];
    }
}

//+------------------------------------------------------------------+
//| シンボル名の変換を行います                                       |
//+------------------------------------------------------------------+
string ConvertSymbol(string symbol_before, int k)
{
    for (int i = 0; i < SymbolConversion[k].Count; ++i) {
        if (SymbolConversion[k].Before[i] == symbol_before) {
            return SymbolConversion[k].After[i];
        }
    }

    return symbol_before;
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
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // 100ミリ秒の周期でポジション全体の差分をタブ区切りファイルから読みだします
    LoadPositions();
}

//+------------------------------------------------------------------+
//| ポジション全体の差分を全てのタブ区切りファイルから読みだします   |
//+------------------------------------------------------------------+
void LoadPositions()
{
    for (int i = 0; i < CommunacationDirCount; ++i) {
        LoadPosition(CommunacationPathDir[i], LotsMultiply[i], i);
    }
}

//+------------------------------------------------------------------+
//| ポジション全体の差分をタブ区切りファイルから読みだします         |
//+------------------------------------------------------------------+
void LoadPosition(string communication_dir, double lots_multiply, int k)
{
    string file_name;
    long search_handle = FileFindFirst(communication_dir + "\\*.tsv", file_name, FILE_COMMON);
    if (search_handle == INVALID_HANDLE) {
        return;
    }

    do {
        string path = communication_dir + "\\" + file_name;
        int file = FileOpen(path, FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON, '\t', CP_ACP);
        if (file == INVALID_HANDLE) {
            continue;
        }

        // 見つかったコピーポジション連携用タブ区切りファイルのファイル名をログ出力します
        printf("⇒連携ファイル: \"%s\"", path);

        string line;
        while ((line = FileReadString(file)) != "") {
            string field[];
            StringSplit(line, '\t', field);
            // タブ区切りファイルの仕様
            // 0列目：送信元証券会社名
            string sender_broker = field[0];
            // 1列目：+1: ポジション追加 ／ -1: ポジション削除 ／ 0: ポジション修正
            int change = (int)StringToInteger(field[1]);
            // 2列目：マジックナンバー
            int magic_number = (int)StringToInteger(field[2]);
            // 3列目：エントリー種別
            int entry_type = (int)StringToInteger(field[3]);
            // 4列目：エントリー価格
            double entry_price = StringToDouble(field[4]);
            // 5列目：シンボル名
            string symbol = field[5] + SYMBOL_APPEND_SUFFIX;
            // 4列目：エントリー価格を補正
            if (entry_type > 0) {
                entry_price = MathMin(entry_price, SymbolInfoDouble(symbol, SYMBOL_ASK));
            }
            else {
                entry_price = MathMax(entry_price, SymbolInfoDouble(symbol, SYMBOL_BID));
            }
            // 6列目：コピー元チケット番号
            int ticket = (int)StringToInteger(field[6]);
            // 7列目：ポジションサイズ
            double lots = RoundLots(symbol, StringToDouble(field[7]) * lots_multiply);
            // 8列目：ストップロス
            double stoploss = StringToDouble(field[8]);
            // 9列目：テイクプロフィット
            double takeprofit = StringToDouble(field[9]);

            printf("ポジションコピー受信: %s %+d %d %+d %.6f %s %d %.2f %.6f %.6f",
                sender_broker, change, magic_number, entry_type, entry_price, symbol, ticket, lots, stoploss, takeprofit);

            if (change == +1) {
                Entry(sender_broker, magic_number, entry_type, entry_price, symbol, ticket, lots, stoploss, takeprofit);
            }
            else if (change == -1) {
                Exit(sender_broker, magic_number, entry_type, entry_price, symbol, ticket, stoploss, takeprofit);
            }
            else {
                Modify(sender_broker, magic_number, entry_type, entry_price, symbol, ticket, stoploss, takeprofit);
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
void Entry(string sender_broker, int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double lots, double stoploss, double takeprofit)
{
    lots = RoundLots(symbol, lots);

    double price = 0;
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    }

    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    if (entry_type == +1) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.Buy(lots, symbol, price, stoploss, takeprofit, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -1) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.Sell(lots, symbol, price, stoploss, takeprofit, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == +2) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.BuyLimit(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -2) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.SellLimit(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == +3) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.BuyStop(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -3) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.SellStop(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }

    Alert(error_message);
}

//+------------------------------------------------------------------+
//| ロット数を口座の上限・下限に丸めます                             |
//+------------------------------------------------------------------+
double RoundLots(string symbol, double lots)
{
    double rounded_lots = lots;
    double max_lots = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    if (lots > max_lots) {
        rounded_lots = max_lots;
    }
    double min_lots = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    if (lots < min_lots) {
        rounded_lots = min_lots;
    }
    double lots_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    if (lots_step == 0.0) {
        lots_step = 0.01;
    }
    double lots_qty = NormalizeDouble(rounded_lots / lots_step, 0);
    return lots_qty * lots_step;
}

//+------------------------------------------------------------------+
//| コピーしたポジションを決済します                                 |
//+------------------------------------------------------------------+
void Exit(string sender_broker, int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double stoploss, double takeprofit)
{
    double price = 0;
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }

    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_COMMENT) != comment) {
            continue;
        }
        double lots = PositionGetDouble(POSITION_VOLUME);
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.PositionClose(ticket, SLIPPAGE);
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
    for (int i = 0; i < OrdersTotal(); ++i) {
        ulong ticket = OrderGetTicket(i);
        if (OrderGetString(ORDER_COMMENT) != comment) {
            continue;
        }
        double lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.OrderDelete(ticket);
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
void Modify(string sender_broker, int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double stoploss, double takeprofit)
{
    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.PositionModify(ticket, stoploss, takeprofit);
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
    for (int i = 0; i < OrdersTotal(); ++i) {
        ulong ticket = OrderGetTicket(i);
        if (OrderGetString(ORDER_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.OrderModify(ticket, entry_price, stoploss, takeprofit, ORDER_TIME_GTC, 0);
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
